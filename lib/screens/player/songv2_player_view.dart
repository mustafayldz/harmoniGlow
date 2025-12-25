// song_v2_player_view_ultimate.dart
//
// ✅ Burst-proof Note Rain (iOS + Android)
// - drawRawAtlas ✅ (single batch draw)
// - NO ghost notes ✅ (sublistView with writeCount)
// - Lane-time precompute ✅ (no mask scan per frame)
// - Cursor-based hit flashes ✅ (O(8*k), no allocations)
// - FrameTiming-based LOD ✅ (reacts to real raster/ui cost)
// - Dense-pass “streak” rendering ✅ (turns 400 notes into ~40 strips)
//
// Drop-in: replace your current page with this file’s SongV2PlayerView.
// Requires: SongV2Model has (absT, m, lookaheadMs, hitMs, syncMs, durationMs, title, artist, bpm, ts, dt, source)

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:drumly/constants.dart';
import 'package:drumly/models/songv2_model.dart';
import 'package:drumly/services/songv2_service.dart';

/// -------------------------
///  UTIL
/// -------------------------
int _lowerBoundInt32(Int32List a, int target) {
  var lo = 0;
  var hi = a.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (a[mid] < target) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

double _clampD(double v, double a, double b) => math.max(a, math.min(b, v));

int _packArgbWithOpacity(Color c, double opacity01) {
  final oa = (opacity01 * 255).round().clamp(0, 255);
  final a = (c.alpha * oa) ~/ 255;
  return (a << 24) | (c.red << 16) | (c.green << 8) | c.blue;
}

/// -------------------------
///  ZERO-ALLOCATION FLASH CONTROLLER
/// -------------------------
class LaneFlashController extends ChangeNotifier {
  LaneFlashController() : v = Float32List(8);
  final Float32List v;

  void decay(double dtMs) {
    bool changed = false;
    for (var i = 0; i < 8; i++) {
      final nv = v[i] - dtMs;
      final clamped = nv < 0.0 ? 0.0 : nv;
      if (clamped != v[i]) {
        v[i] = clamped;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void flashLane(int lane, double ms) {
    if (v[lane] != ms) {
      v[lane] = ms;
      notifyListeners();
    }
  }

  void reset() {
    for (var i = 0; i < 8; i++) {
      v[i] = 0.0;
    }
    notifyListeners();
  }
}

/// -------------------------
///  STATIC STAGE (background + lane labels)
/// -------------------------
class _StaticStagePainter extends CustomPainter {
  _StaticStagePainter({
    required this.laneColors,
    required this.hitZoneHeight,
    required this.drumNameFontSize,
  });

  final List<Color> laneColors;
  final double hitZoneHeight;
  final double drumNameFontSize;

  List<TextPainter>? _labelPainters;
  List<Shader>? _cachedShaders;
  Size? _lastSize;
  double? _lastLaneW;
  double? _lastFont;

  @override
  void paint(Canvas canvas, Size size) {
    final laneW = size.width / 8.0;

    // Cache shaders on size changes
    if (_cachedShaders == null || _lastSize != size) {
      _cachedShaders = List.generate(8, (lane) {
        final rect = Rect.fromLTWH(lane * laneW, 0, laneW, size.height);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [laneColors[lane].withOpacity(0.08), Colors.black],
        ).createShader(rect);
      });
      _lastSize = size;
    }

    // Lane backgrounds + dividers
    final divPaint = Paint()..color = const Color(0x1AFFFFFF);
    for (int lane = 0; lane < 8; lane++) {
      final rect = Rect.fromLTWH(lane * laneW, 0, laneW, size.height);
      canvas.drawRect(rect, Paint()..shader = _cachedShaders![lane]);
      canvas.drawRect(Rect.fromLTWH(rect.right - 1, 0, 1, size.height), divPaint);
    }

    // Labels: re-layout if laneW or font changes
    final needRelayout = _labelPainters == null ||
        _labelPainters!.isEmpty ||
        _lastLaneW != laneW ||
        _lastFont != drumNameFontSize;

    if (needRelayout) {
      _labelPainters = List.generate(8, (lane) {
        final tp = TextPainter(
          text: TextSpan(
            text: _drumName(lane),
            style: TextStyle(
              color: laneColors[lane],
              fontSize: drumNameFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: laneW - 8);
        return tp;
      });
      _lastLaneW = laneW;
      _lastFont = drumNameFontSize;
    }

    final padTop = size.height - hitZoneHeight;
    for (int lane = 0; lane < 8; lane++) {
      final tp = _labelPainters![lane];
      tp.paint(
        canvas,
        Offset(
          lane * laneW + (laneW - tp.width) / 2,
          padTop + (hitZoneHeight - tp.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StaticStagePainter old) => false;

  String _drumName(int index) {
    switch (index) {
      case 0:
        return 'Hi-Hat';
      case 1:
        return 'Crash';
      case 2:
        return 'Ride';
      case 3:
        return 'Snare';
      case 4:
        return 'Tom 1';
      case 5:
        return 'Tom 2';
      case 6:
        return 'Floor\nTom';
      case 7:
        return 'Kick';
      default:
        return '';
    }
  }
}

/// -------------------------
///  HIT GLOW (cheap layer, optional glow)
/// -------------------------
class _HitGlowPainter extends CustomPainter {
  _HitGlowPainter({
    required this.flashCtrl,
    required this.laneColors,
    required this.hitZoneHeight,
    required this.enableGlow,
  }) : super(repaint: flashCtrl);

  final LaneFlashController flashCtrl;
  final List<Color> laneColors;
  final double hitZoneHeight;
  final bool enableGlow;

  static final _blurCache = <int, MaskFilter>{
    0: const MaskFilter.blur(BlurStyle.normal, 0),
    4: const MaskFilter.blur(BlurStyle.normal, 4),
    8: const MaskFilter.blur(BlurStyle.normal, 8),
    12: const MaskFilter.blur(BlurStyle.normal, 12),
    16: const MaskFilter.blur(BlurStyle.normal, 16),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final laneW = size.width / 8.0;
    final padTop = size.height - hitZoneHeight;

    for (int lane = 0; lane < 8; lane++) {
      final intensity = (flashCtrl.v[lane] / 180.0).clamp(0.0, 1.0);
      final c = laneColors[lane];
      final zone = Rect.fromLTWH(lane * laneW, padTop, laneW, hitZoneHeight);

      // Fill + border
      canvas.drawRect(zone, Paint()..color = c.withOpacity(0.30 + 0.50 * intensity));
      canvas.drawRect(
        zone.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = c,
      );

      // Optional glow (quantized blur)
      if (enableGlow && intensity > 0.06) {
        final sigma = (intensity * 16).round().clamp(0, 16);
        final quantized = (sigma ~/ 4) * 4;
        canvas.drawRect(
          zone.deflate(6),
          Paint()
            ..color = c.withOpacity(0.35 * intensity)
            ..maskFilter = _blurCache[quantized],
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HitGlowPainter old) => true;
}

/// -------------------------
///  NOTES LAYER (drawRawAtlas + optional dense "streak" mode)
/// -------------------------
class _NotesRawAtlasPainter extends CustomPainter {
  _NotesRawAtlasPainter({
    required this.songMs,
    required this.laneTimes, // 8 lanes, each Int32List of note times
    required this.laneColors,
    required this.hitZoneHeight,
    required this.noteSprite,
    required this.lookaheadMs,
    required this.maxNotesTotal,
    required this.denseMode,
  }) : super(repaint: songMs);

  final ValueListenable<int> songMs;
  final List<Int32List> laneTimes;
  final List<Color> laneColors;
  final double hitZoneHeight;
  final ui.Image? noteSprite;

  final int lookaheadMs;
  final int maxNotesTotal;
  final bool denseMode;

  static const int _pastMs = 160;

  // Buffers (reused, no per-frame allocations)
  static Float32List? _rst;
  static Float32List? _rect;
  static Int32List? _cols;
  static int _cap = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final sprite = noteSprite;
    if (sprite == null) return;

    final tNow = songMs.value;
    final laneW = size.width / 8.0;

    final start = tNow - _pastMs;
    final end = tNow + lookaheadMs;

    final padRowH = (hitZoneHeight * 2) / 2.0;
    final padTop2 = size.height - (hitZoneHeight * 2);
    const spawnY = 24.0;

    // Visual size
    final noteR = size.height * 0.0125;
    final scale = noteR / 16.0; // sprite assumed 32x32 with center ~16
    final spriteW = sprite.width.toDouble();
    final spriteH = sprite.height.toDouble();

    // Capacity
    if (_rst == null || _cap < maxNotesTotal) {
      _cap = maxNotesTotal;
      _rst = Float32List(_cap * 4); // scos, ssin, tx, ty
      _rect = Float32List(_cap * 4); // x, y, w, h (src rect)
      _cols = Int32List(_cap); // ARGB
    }

    // Budget per lane (prevents one lane eating all)
    final perLaneBudget = math.max(24, (maxNotesTotal / 8).floor());

    int w = 0; // write count for atlas
    final stripPaint = Paint()..style = PaintingStyle.fill;

    // Dense mode: cluster adjacent notes into vertical strips
    final minSpacingPx = noteR * 1.35;

    for (int lane = 0; lane < 8; lane++) {
      final times = laneTimes[lane];
      if (times.isEmpty) continue;

      int i = _lowerBoundInt32(times, start);
      if (i > 0) i -= 1; // tiny backstep

      int usedThisLane = 0;

      final xCenter = (lane + 0.5) * laneW;
      final row = lane < 4 ? 0 : 1;
      final targetY = padTop2 + row * padRowH + padRowH / 2.0;

      // For dense clustering
      double? runTopY;
      double? runBottomY;
      double runMaxOpacity = 0.0;
      int runColorArgb = 0;

      void flushRunIfAny() {
        if (!denseMode) return;
        if (runTopY == null || runBottomY == null) return;
        final top = math.min(runTopY!, runBottomY!);
        final bot = math.max(runTopY!, runBottomY!);
        final h = (bot - top).abs().clamp(2.0, 99999.0);

        // Draw a slim strip
        stripPaint.color = Color(runColorArgb).withOpacity(1.0);
        final stripW = noteR * 1.25;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(xCenter - stripW / 2, top - noteR * 0.6, stripW, h + noteR * 1.2),
            Radius.circular(stripW * 0.5),
          ),
          stripPaint,
        );

        runTopY = null;
        runBottomY = null;
        runMaxOpacity = 0.0;
        runColorArgb = 0;
      }

      while (i < times.length && usedThisLane < perLaneBudget) {
        final t = times[i];
        if (t > end) break;

        final alphaRaw = (t - tNow) / lookaheadMs;
        final alpha = _clampD(alphaRaw, -_pastMs / lookaheadMs, 1.1);

        final y = targetY + (spawnY - targetY) * alpha;
        if (y < -60 || y > size.height + 80) {
          i++;
          continue;
        }

        double opacity;
        if (alphaRaw < 0) {
          opacity = _clampD(1 + alphaRaw * 6, 0.0, 1.0);
        } else {
          opacity = _clampD(1 - (alphaRaw - 0.85) * 3, 0.2, 1.0);
        }
        if (opacity <= 0.01) {
          i++;
          continue;
        }

        final isHit = (t - tNow).abs() <= 18;
        final baseC = isHit ? const Color(0xFF10B981) : laneColors[lane];
        final argb = _packArgbWithOpacity(baseC, opacity);

        // Dense clustering:
        // If consecutive y's too close, draw as strip instead of many sprites.
        if (denseMode) {
          if (runTopY == null) {
            runTopY = y;
            runBottomY = y;
            runMaxOpacity = opacity;
            runColorArgb = argb;
          } else {
            final prevY = runBottomY!;
            final dy = (prevY - y).abs();
            if (dy < minSpacingPx) {
              // extend run
              runBottomY = y;
              if (opacity > runMaxOpacity) {
                runMaxOpacity = opacity;
                runColorArgb = argb;
              }
            } else {
              // flush old run, start new
              flushRunIfAny();
              runTopY = y;
              runBottomY = y;
              runMaxOpacity = opacity;
              runColorArgb = argb;
            }
          }

          // For dense mode, still render an occasional "bead" for readability
          // (every 3rd note or when hit)
          final renderBead = isHit || ((i % 3) == 0);
          if (!renderBead) {
            i++;
            usedThisLane++;
            continue;
          }
        }

        // Atlas write
        if (w >= maxNotesTotal) break;

        final base = w * 4;
        _rst![base + 0] = scale; // scos
        _rst![base + 1] = 0.0; // ssin
        _rst![base + 2] = xCenter - 16.0 * scale; // tx (center sprite)
        _rst![base + 3] = y - 16.0 * scale; // ty

        _rect![base + 0] = 0.0;
        _rect![base + 1] = 0.0;
        _rect![base + 2] = spriteW;
        _rect![base + 3] = spriteH;

        _cols![w] = argb;

        w++;
        i++;
        usedThisLane++;
      }

      // flush any leftover run for this lane
      flushRunIfAny();
    }

    if (w == 0) return;

    // ✅ CRITICAL: pass only the used portion (prevents ghost notes)
    final tView = Float32List.sublistView(_rst!, 0, w * 4);
    final rView = Float32List.sublistView(_rect!, 0, w * 4);
    final cView = Int32List.sublistView(_cols!, 0, w);

    canvas.drawRawAtlas(
      sprite,
      tView,
      rView,
      cView,
      BlendMode.srcOver,
      null,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _NotesRawAtlasPainter old) => true;
}

/// -------------------------
///  MAIN VIEW
/// -------------------------
class SongV2PlayerView extends StatefulWidget {
  const SongV2PlayerView({required this.songv2Id, super.key});
  final String songv2Id;

  @override
  State<SongV2PlayerView> createState() => _SongV2PlayerViewState();
}

class _SongV2PlayerViewState extends State<SongV2PlayerView> with SingleTickerProviderStateMixin {
  final SongV2Service _songV2Service = SongV2Service();

  // State
  bool _isLoading = true;
  String? _errorMessage;

  bool _isPlaying = false;
  double _speed = 1.0;
  bool _showControls = false;
  bool _showSpeedControl = false;

  SongV2Model? _song;

  // Time
  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _playerMs = 0.0;
  late final ValueNotifier<int> _songMsN = ValueNotifier<int>(0);

  // YouTube
  YoutubePlayerController? _ytController;
  bool _ytReady = false;
  double _ytPollAccumMs = 0.0;

  // Visuals
  late List<Color> _laneColors;
  final LaneFlashController _flashCtrl = LaneFlashController();
  static const int _flashDurationMs = 180;

  ui.Image? _noteSprite;

  // Precomputed per-lane times (ABS ms)
  List<Int32List> _laneTimes = List.generate(8, (_) => Int32List(0));

  // Hit cursors per lane
  final List<int> _hitCursorLane = List<int>.filled(8, 0);

  // LOD (frame-timing based)
  bool _enableGlow = true;
  bool _denseMode = false;
  int _lookaheadMs = 2000;
  int _maxNotesTotal = 900;

  double _rasterAvgMs = 0.0;
  double _uiAvgMs = 0.0;

  Timer? _speedControlTimer;

  Color _getLedColor(int index) {
    final drumPartKey = (index + 1).toString();
    final rgb = DrumParts.drumParts[drumPartKey]?['rgb'] as List<dynamic>?;
    if (rgb != null && rgb.length == 3) {
      return Color.fromRGBO(rgb[0] as int, rgb[1] as int, rgb[2] as int, 1);
    }
    return Colors.white;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

    // Real frame timing feedback (UI + Raster)
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);

    _generateNoteSprite();
    _loadSongFromBackend();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);

    _ticker.dispose();
    _speedControlTimer?.cancel();

    _ytController?.dispose();
    _noteSprite?.dispose();

    _songMsN.dispose();
    _flashCtrl.dispose();

    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    if (timings.isEmpty) return;

    // EMA smoothing
    const alpha = 0.10;
    final last = timings.last;
    final raster = last.rasterDuration.inMicroseconds / 1000.0;
    final uiMs = last.buildDuration.inMicroseconds / 1000.0;

    _rasterAvgMs = (_rasterAvgMs == 0.0) ? raster : (_rasterAvgMs * (1 - alpha) + raster * alpha);
    _uiAvgMs = (_uiAvgMs == 0.0) ? uiMs : (_uiAvgMs * (1 - alpha) + uiMs * alpha);

    // LOD decisions from *real* costs
    // Target: 16.6ms @60Hz
    final overRaster = _rasterAvgMs > 16.6;
    final overUi = _uiAvgMs > 10.0;

    if (overRaster || overUi) {
      // degrade fast
      _enableGlow = false;
      _denseMode = true;
      _lookaheadMs = math.max(1200, _lookaheadMs - 150);
      _maxNotesTotal = math.max(520, _maxNotesTotal - 80);
    } else {
      // restore slowly
      _enableGlow = true;
      _denseMode = false;
      if (_song != null) {
        _lookaheadMs = math.min(_song!.lookaheadMs, _lookaheadMs + 40);
      }
      _maxNotesTotal = math.min(1000, _maxNotesTotal + 40);
    }
  }

  Future<void> _generateNoteSprite() async {
    // 32x32 white circle with outline; tinted via ARGB in drawRawAtlas.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 32, 32));

    canvas.drawCircle(const Offset(16, 16), 15, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(16, 16),
      15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(0.25),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(32, 32);
    picture.dispose();

    if (!mounted) return;
    setState(() => _noteSprite = img);
  }

  Future<void> _loadSongFromBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final song = await _songV2Service.getSongV2ById(context, widget.songv2Id);
      if (song == null) {
        setState(() {
          _errorMessage = 'Song not found';
          _isLoading = false;
        });
        return;
      }

      _laneColors = List<Color>.generate(8, (i) => _getLedColor(i));

      // Precompute lane times: avoid runtime mask scanning
      _laneTimes = _buildLaneTimes(song);

      // Init LOD defaults from song
      _lookaheadMs = song.lookaheadMs;
      _maxNotesTotal = 900;
      _enableGlow = true;
      _denseMode = false;

      setState(() {
        _song = song;
        _isLoading = false;
      });

      // YouTube controller
      try {
        if (song.source.type.toLowerCase() == 'youtube') {
          _ytController = YoutubePlayerController(
            initialVideoId: song.source.videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              hideControls: true,
              enableCaption: false,
              disableDragSeek: false,
            ),
          )..addListener(() {
              final ready = _ytController?.value.isReady ?? false;
              if (ready != _ytReady) {
                setState(() => _ytReady = ready);
              }
            });

          _ytController!.setPlaybackRate(_nearestPlaybackRate(_speed));
        }
      } catch (e) {
        debugPrint('YouTube init failed: $e');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load song: $e';
        _isLoading = false;
      });
    }
  }

  List<Int32List> _buildLaneTimes(SongV2Model song) {
    final tmp = List.generate(8, (_) => <int>[]);
    final n = song.absT.length;

    // absT is time per event; m is lane bitmask per event
    for (int i = 0; i < n; i++) {
      final mask = song.m[i];
      if (mask == 0) continue;
      final t = song.absT[i];

      // bit scan (8 lanes)
      for (int lane = 0; lane < 8; lane++) {
        if ((mask & (1 << lane)) != 0) {
          tmp[lane].add(t);
        }
      }
    }

    return List.generate(8, (lane) => Int32List.fromList(tmp[lane]));
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying || _song == null) return;

    final last = _lastElapsed;
    _lastElapsed = elapsed;
    if (last == null) return;

    // dt (clamp huge spikes to avoid physics/time explosions)
    var dtMs = (elapsed - last).inMicroseconds / 1000.0;
    if (dtMs.isNaN || dtMs.isInfinite) return;
    if (dtMs > 50.0) dtMs = 50.0;

    // Sync time source
    if (_ytController != null && _ytReady) {
      _ytPollAccumMs += dtMs;

      // Poll YouTube position infrequently; correct drift when large
      if (_ytPollAccumMs >= 350.0) {
        final posMs = _ytController!.value.position.inMilliseconds.toDouble();
        final drift = (posMs - _playerMs).abs();
        if (drift > 100.0) {
          _playerMs = posMs;
        }
        _ytPollAccumMs = 0.0;
      } else {
        _playerMs += dtMs * _speed;
      }
    } else {
      _playerMs += dtMs * _speed;
    }

    final songMs = (_playerMs - _song!.syncMs).round();

    // Hit flashes: lane cursors (no allocations)
    _updateLaneHits(songMs);

    // Decay glow
    _flashCtrl.decay(dtMs);

    // Stop end
    final dur = _song!.durationMs;
    if (_playerMs >= dur) {
      _playerMs = dur.toDouble();
      _isPlaying = false;
      _lastElapsed = null;
      _ticker.stop();
      setState(() {}); // update UI once
    }

    // Drive painters (no rebuild)
    _songMsN.value = songMs;
  }

  void _updateLaneHits(int songMs) {
    final song = _song;
    if (song == null) return;

    final hitWindow = (song.hitMs / 2).round();

    for (int lane = 0; lane < 8; lane++) {
      final times = _laneTimes[lane];
      var c = _hitCursorLane[lane];

      // Advance cursor past old hits
      while (c < times.length && times[c] < songMs - hitWindow) {
        c++;
      }

      // Flash all notes inside window
      int j = c;
      while (j < times.length && times[j] <= songMs + hitWindow) {
        // inside window
        _flashCtrl.flashLane(lane, _flashDurationMs.toDouble());
        j++;
      }

      _hitCursorLane[lane] = c;
    }
  }

  void _togglePlay() {
    final song = _song;
    if (song == null) return;

    setState(() {
      if (_playerMs >= song.durationMs) {
        _playerMs = 0.0;
      }
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      // Reset per-play state
      for (int i = 0; i < 8; i++) _hitCursorLane[i] = 0;
      _flashCtrl.reset();

      _lastElapsed = Duration.zero;
      _ticker.start();

      if (_ytController != null && _ytReady) {
        _ytController!.seekTo(Duration(milliseconds: _playerMs.toInt()));
        _ytController!.play();
      }
    } else {
      _lastElapsed = null;
      _ticker.stop();
      if (_ytController != null && _ytReady) _ytController!.pause();
    }
  }

  void _toggleSpeedControl() {
    setState(() => _showSpeedControl = !_showSpeedControl);
    _speedControlTimer?.cancel();
    if (_showSpeedControl) {
      _speedControlTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSpeedControl = false);
      });
    }
  }

  void _onSpeedChanged(double value) {
    final rate = _nearestPlaybackRate(value);
    setState(() => _speed = rate);

    if (_ytController != null && _ytReady) {
      _ytController!.setPlaybackRate(rate);
    }

    _speedControlTimer?.cancel();
    _speedControlTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSpeedControl = false);
    });
  }

  double _nearestPlaybackRate(double v) {
    const allowed = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    double best = allowed.first;
    double bestDiff = (v - best).abs();
    for (final r in allowed) {
      final d = (v - r).abs();
      if (d < bestDiff) {
        best = r;
        bestDiff = d;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final padTop = MediaQuery.of(context).padding.top;

    final screenHeight = screen.height;
    final screenWidth = screen.width;

    final topGradientHeight = screenHeight * 0.12;
    final hitZoneHeight = screenHeight * 0.10;
    final drumNameFontSize = screenHeight * 0.012;

    final playButtonIconSize = screenHeight * 0.06;

    final controlsPadding = screenWidth * 0.05;
    final controlsTitleSize = screenHeight * 0.03;
    final controlsTextSize = screenHeight * 0.018;
    final infoTextSize = screenHeight * 0.015;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading song...', style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    _buildStage(
                      hitZoneHeight: hitZoneHeight,
                      drumNameFontSize: drumNameFontSize,
                    ),

                    // Offscreen YouTube player
                    if (_ytController != null)
                      Positioned(
                        top: -1000,
                        child: SizedBox(
                          width: 1,
                          height: 1,
                          child: YoutubePlayer(
                            controller: _ytController!,
                            onReady: () => setState(() => _ytReady = true),
                          ),
                        ),
                      ),

                    // Top gradient
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topGradientHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.0)],
                          ),
                        ),
                      ),
                    ),

                    // Back
                    Positioned(
                      top: padTop + 8,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Speed
                    Positioned(
                      top: padTop + 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _toggleSpeedControl,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: _showSpeedControl ? screenWidth * 0.75 : screenWidth * 0.20,
                            padding: EdgeInsets.symmetric(
                              horizontal: _showSpeedControl ? screenWidth * 0.03 : screenWidth * 0.04,
                              vertical: screenHeight * 0.010,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: _showSpeedControl
                                ? Row(
                                    children: [
                                      Text(
                                        'Speed:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenHeight * 0.015,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 3,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                          ),
                                          child: Slider(
                                            value: _speed,
                                            min: 0.25,
                                            max: 2.0,
                                            divisions: 7,
                                            label: '${_speed.toStringAsFixed(2)}x',
                                            activeColor: Colors.blue,
                                            onChanged: _onSpeedChanged,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_speed.toStringAsFixed(2)}x',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenHeight * 0.015,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    '${_speed.toStringAsFixed(2)}x',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenHeight * 0.02,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ),
                    ),

                    if (_showControls)
                      _buildControlsOverlay(
                        controlsPadding,
                        controlsTitleSize,
                        controlsTextSize,
                        infoTextSize,
                      ),

                    // Play/Pause
                    Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isPlaying ? 0.30 : 0.85,
                        child: FloatingActionButton.large(
                          backgroundColor: _isPlaying ? Colors.red : Colors.green,
                          onPressed: _togglePlay,
                          child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: playButtonIconSize),
                        ),
                      ),
                    ),

                    // Optional tiny perf indicator (comment out in prod)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.55,
                          child: Text(
                            'UI ${_uiAvgMs.toStringAsFixed(1)}ms • Raster ${_rasterAvgMs.toStringAsFixed(1)}ms'
                            ' • LOD ${_denseMode ? "DENSE" : "NORMAL"}'
                            ' • notesCap $_maxNotesTotal',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStage({
    required double hitZoneHeight,
    required double drumNameFontSize,
  }) {
    final song = _song;
    if (song == null) return const SizedBox.expand();

    // Three isolated layers
    return Stack(
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _StaticStagePainter(
              laneColors: _laneColors,
              hitZoneHeight: hitZoneHeight,
              drumNameFontSize: drumNameFontSize,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _HitGlowPainter(
              flashCtrl: _flashCtrl,
              laneColors: _laneColors,
              hitZoneHeight: hitZoneHeight,
              enableGlow: _enableGlow,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _NotesRawAtlasPainter(
              songMs: _songMsN,
              laneTimes: _laneTimes,
              laneColors: _laneColors,
              hitZoneHeight: hitZoneHeight,
              noteSprite: _noteSprite,
              lookaheadMs: _lookaheadMs,
              maxNotesTotal: _maxNotesTotal,
              denseMode: _denseMode,
            ),
            isComplex: true,
            willChange: true,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsOverlay(
    double padding,
    double titleSize,
    double textSize,
    double infoSize,
  ) =>
      Positioned.fill(
        child: GestureDetector(
          onTap: () => setState(() => _showControls = false),
          child: ColoredBox(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Container(
                margin: EdgeInsets.all(padding),
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Controls', style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.bold)),
                    SizedBox(height: padding),
                    Row(
                      children: [
                        Text('Speed:', style: TextStyle(color: Colors.white, fontSize: textSize)),
                        Expanded(
                          child: Slider(
                            value: _speed,
                            min: 0.25,
                            max: 2.0,
                            divisions: 7,
                            label: '${_speed.toStringAsFixed(2)}x',
                            onChanged: _onSpeedChanged,
                          ),
                        ),
                        Text('${_speed.toStringAsFixed(2)}x',
                            style: TextStyle(color: Colors.white, fontSize: textSize, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: padding * 0.67),
                    if (_song != null) ...[
                      Text('Title: ${_song!.title}', style: TextStyle(color: Colors.grey, fontSize: infoSize)),
                      Text('Artist: ${_song!.artist}', style: TextStyle(color: Colors.grey, fontSize: infoSize)),
                      Text('BPM: ${_song!.bpm}', style: TextStyle(color: Colors.grey, fontSize: infoSize)),
                      Text('Time Signature: ${_song!.ts}', style: TextStyle(color: Colors.grey, fontSize: infoSize)),
                      Text('Duration: ${(_song!.durationMs / 1000).toStringAsFixed(1)}s',
                          style: TextStyle(color: Colors.grey, fontSize: infoSize)),
                      Text('Notes: ${_song!.dt.length}', style: TextStyle(color: Colors.grey, fontSize: infoSize)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
