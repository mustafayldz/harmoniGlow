import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drumly/shared/app_gradients.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:drumly/constants.dart';
import 'package:drumly/models/songv2_model.dart';
import 'package:drumly/services/songv2_service.dart';

/// ---------------------------------------------------------------------------
/// 1) Drum kit layout (normalized coords inside the DRUM RECT)
/// ---------------------------------------------------------------------------

class DrumAnchor {
  const DrumAnchor(this.x, this.y, this.r);
  final double x; // 0..1
  final double y; // 0..1
  final double r; // relative to rect width
}

class DrumKitLayout {
  static const Map<int, DrumAnchor> anchor = {
    0: DrumAnchor(0.220, 0.456, 0.075), // Hi-Hat
    1: DrumAnchor(0.100, 0.166, 0.090), // Crash
    2: DrumAnchor(0.900, 0.166, 0.090), // Ride
    3: DrumAnchor(0.380, 0.502, 0.075), // Snare
    4: DrumAnchor(0.450, 0.200, 0.075), // Tom 1
    5: DrumAnchor(0.650, 0.200, 0.075), // Tom 2
    6: DrumAnchor(0.750, 0.517, 0.090), // Floor Tom
    7: DrumAnchor(0.550, 0.705, 0.120), // Kick
  };

  static const Map<int, String> labels = {
    0: 'Hi-Hat',
    1: 'Crash',
    2: 'Ride',
    3: 'Snare',
    4: 'Tom 1',
    5: 'Tom 2',
    6: 'Floor Tom',
    7: 'Kick',
  };
}

/// ---------------------------------------------------------------------------
/// 2) Zero-allocation lane flash controller
/// ---------------------------------------------------------------------------

class LaneFlashController extends ChangeNotifier {
  LaneFlashController() : v = Float32List(8);
  final Float32List v;

  void decay(double dtMs) {
    bool changed = false;
    for (var i = 0; i < 8; i++) {
      final nv = v[i] - dtMs;
      final clamped = nv < 0 ? 0.0 : nv;
      if (clamped != v[i]) {
        v[i] = clamped;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void flashLane(int lane, double ms) {
    if (lane < 0 || lane >= 8) return;
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

/// ---------------------------------------------------------------------------
/// 3) Notes + part glow painter
/// ---------------------------------------------------------------------------

class _NotesAndGlowPainter extends CustomPainter {
  _NotesAndGlowPainter({
    required this.song,
    required this.songMs,
    required this.dstRect,
    required this.safe,
    required this.laneColors,
    required this.flashCtrl,
    required this.noteSprite,
    required this.enableGlow,
    required this.maxNotesPerFrame,
    required this.dynamicLookahead,
    required this.isDarkMode, // ✅
  }) : super(repaint: Listenable.merge([songMs, flashCtrl]));

  final SongV2Model song;
  final ValueListenable<int> songMs;

  final Rect dstRect;
  final EdgeInsets safe;
  final List<Color> laneColors;
  final LaneFlashController flashCtrl;
  final ui.Image? noteSprite;

  final bool enableGlow;
  final int maxNotesPerFrame;
  final int dynamicLookahead;

  final bool isDarkMode; // ✅

  static const int pastMs = 160;
  static const int hitTightMs = 18;

  static Float32List? _rst;
  static Float32List? _rects;
  static Int32List? _colors;
  static int _cap = 0;

  static List<TextPainter>? _labelPainters;
  static double _lastDstRectWidth = 0.0;
  static bool _lastDark = true;

  static int _packColor(Color c, double opacity) {
    final oa = (opacity * 255).round().clamp(0, 255);
    final na = (c.alpha * oa) ~/ 255;
    return (na << 24) | (c.red << 16) | (c.green << 8) | c.blue;
  }

  Offset _anchorToScreen(int lane) {
    final a = DrumKitLayout.anchor[lane]!;
    return Offset(
      dstRect.left + a.x * dstRect.width,
      dstRect.top + a.y * dstRect.height,
    );
  }

  double _anchorRadiusPx(int lane) {
    final a = DrumKitLayout.anchor[lane]!;
    return a.r * dstRect.width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ Artık "BlendMode.clear" YOK.
    // Arka plan (DecoratedBox) aynen kalır.

    final tNow = songMs.value;
    final lookahead = dynamicLookahead;

    if (enableGlow) _paintPartGlows(canvas);

    if (noteSprite != null) {
      _drawNotesRawAtlas(canvas, size, tNow, lookahead);
    } else {
      _drawNotesFallback(canvas, size, tNow, lookahead);
    }
  }

  void _paintPartGlows(Canvas canvas) {
    // ✅ Label cache: dstRect veya tema değişince yeniden oluştur
    final needRebuild =
        _labelPainters == null ||
        (_lastDstRectWidth - dstRect.width).abs() > 0.1 ||
        _lastDark != isDarkMode;

    if (needRebuild) {
      _lastDstRectWidth = dstRect.width;
      _lastDark = isDarkMode;

      _labelPainters = List.generate(8, (lane) {
        final r = _anchorRadiusPx(lane);
        final label = DrumKitLayout.labels[lane] ?? '';

        final textColor = isDarkMode
            ? Colors.white.withOpacity(0.92)
            : Colors.black.withOpacity(0.92);

        final shadowColor = isDarkMode
            ? Colors.black.withOpacity(0.85)
            : Colors.white.withOpacity(0.75);

        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: textColor,
              fontSize: r * 0.38, // ✅ biraz büyüttük
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: shadowColor,
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        return tp;
      });
    }

    for (int lane = 0; lane < 8; lane++) {
      final c = laneColors[lane];
      final center = _anchorToScreen(lane);
      final r = _anchorRadiusPx(lane);

      // ✅ Kontrast outline (arka plan açıkken de koyu görünür, koyuyken de)
      final outlineColor = isDarkMode ? Colors.black.withOpacity(0.65) : Colors.white.withOpacity(0.75);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..color = outlineColor,
      );

      // ✅ Renkleri daha “dolu” göstermek için opaklıkları artırdık
      final baseRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = c.withOpacity(isDarkMode ? 0.70 : 0.85);
      canvas.drawCircle(center, r, baseRing);

      final baseFill = Paint()..color = c.withOpacity(isDarkMode ? 0.18 : 0.26);
      canvas.drawCircle(center, r, baseFill);

      // ✅ Label
      final textPainter = _labelPainters![lane];
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - r - textPainter.height - 6,
        ),
      );

      // ✅ Hit glow
      final intensity = (flashCtrl.v[lane] / 180.0).clamp(0.0, 1.0);
      if (intensity > 0.01) {
        final glowStrength = isDarkMode ? 0.55 : 0.85;

        final glowPaint = Paint()
          ..shader = ui.Gradient.radial(
            center,
            r * (1.25 + 0.40 * intensity),
            [
              c.withOpacity(0.0),
              c.withOpacity(glowStrength * intensity),
              c.withOpacity(0.0),
            ],
            const [0.0, 0.55, 1.0],
          );
        canvas.drawCircle(center, r * (1.25 + 0.40 * intensity), glowPaint);

        final oval = Rect.fromCenter(
          center: center,
          width: r * 2.25,
          height: r * 1.75,
        );

        canvas.drawOval(
          oval,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = c.withOpacity((isDarkMode ? 0.85 : 1.0) * intensity),
        );
      }
    }
  }

  void _drawNotesRawAtlas(Canvas canvas, Size size, int tNow, int lookahead) {
    if (_rst == null || _cap < maxNotesPerFrame) {
      _cap = maxNotesPerFrame;
      _rst = Float32List(_cap * 4);
      _rects = Float32List(_cap * 4);
      _colors = Int32List(_cap);
    }

    final start = tNow - pastMs;
    final end = tNow + lookahead;

    int idx = _lowerBoundAbsT(song.absT, start);
    idx = math.max(0, idx - 16);

    final spriteW = noteSprite!.width.toDouble();
    final spriteH = noteSprite!.height.toDouble();

    final noteR = dstRect.width * 0.020; // ✅ biraz büyüttük (soluk hissini azaltır)
    final scale = noteR / 16.0;

    final spawnY = safe.top + 8.0;

    int w = 0;

    for (int i = idx; i < song.absT.length && w < maxNotesPerFrame; i++) {
      final t = song.absT[i];
      if (t > end) break;

      final timeToHit = t - tNow;
      final timeSinceHit = tNow - t;
      if (timeSinceHit > pastMs) continue;

      final alphaRaw = (t - tNow) / lookahead;
      final alpha = alphaRaw.clamp(-pastMs / lookahead, 1.1);
      final progress = (1.0 - alpha).clamp(0.0, 1.0);

      final mask = song.m[i];

      for (int lane = 0; lane < 8; lane++) {
        if ((mask & (1 << lane)) == 0) continue;
        if (w >= maxNotesPerFrame) break;

        final target = _anchorToScreen(lane);

        final x = target.dx;
        final y = spawnY + progress * (target.dy - spawnY);

        double opacity;
        if (timeToHit >= 0) {
          opacity = 1.0;
        } else {
          opacity = (1.0 - (timeSinceHit / pastMs)).clamp(0.0, 1.0);
        }

        final isHit = (t - tNow).abs() <= hitTightMs;
        final c = isHit ? const Color(0xFF10B981) : laneColors[lane];

        final b = w * 4;
        const spriteCenter = 24.0;

        _rst![b + 0] = scale;
        _rst![b + 1] = 0.0;
        _rst![b + 2] = x - spriteCenter * scale;
        _rst![b + 3] = y - spriteCenter * scale;

        _rects![b + 0] = 0;
        _rects![b + 1] = 0;
        _rects![b + 2] = spriteW;
        _rects![b + 3] = spriteH;

        _colors![w] = _packColor(c, opacity);
        w++;
      }
    }

    for (int j = w; j < _cap; j++) {
      _colors![j] = 0;
      final b = j * 4;
      _rst![b + 0] = 0.0;
      _rst![b + 1] = 0.0;
      _rst![b + 2] = -999999.0;
      _rst![b + 3] = -999999.0;
      _rects![b + 0] = 0.0;
      _rects![b + 1] = 0.0;
      _rects![b + 2] = 0.0;
      _rects![b + 3] = 0.0;
    }

    if (w == 0) return;

    final rstView = Float32List.sublistView(_rst!, 0, w * 4);
    final rectsView = Float32List.sublistView(_rects!, 0, w * 4);
    final colorsView = Int32List.sublistView(_colors!, 0, w);

    // ✅ Renkleri daha “tok” yapmak için modulate yerine srcIn
    // sprite beyaz mask -> renkler daha güçlü görünür
    canvas.drawRawAtlas(
      noteSprite!,
      rstView,
      rectsView,
      colorsView,
      BlendMode.modulate,
      null,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = true,
    );
  }

  void _drawNotesFallback(Canvas canvas, Size size, int tNow, int lookahead) {
    final start = tNow - pastMs;
    final end = tNow + lookahead;

    int idx = _lowerBoundAbsT(song.absT, start);
    idx = math.max(0, idx - 16);

    final noteR = dstRect.width * 0.020;
    final spawnY = safe.top + 8.0;

    for (int i = idx; i < song.absT.length; i++) {
      final t = song.absT[i];
      if (t > end) break;

      final timeToHit = t - tNow;
      final timeSinceHit = tNow - t;
      if (timeSinceHit > pastMs) continue;

      final alphaRaw = (t - tNow) / lookahead;
      final alpha = alphaRaw.clamp(-pastMs / lookahead, 1.1);
      final progress = (1.0 - alpha).clamp(0.0, 1.0);

      final mask = song.m[i];

      for (int lane = 0; lane < 8; lane++) {
        if ((mask & (1 << lane)) == 0) continue;

        final target = _anchorToScreen(lane);
        final x = target.dx;
        final y = spawnY + progress * (target.dy - spawnY);

        double opacity;
        if (timeToHit >= 0) {
          opacity = 1.0;
        } else {
          opacity = (1.0 - (timeSinceHit / pastMs)).clamp(0.0, 1.0);
        }

        final isHit = (t - tNow).abs() <= hitTightMs;
        final c = isHit ? const Color(0xFF10B981) : laneColors[lane];

        canvas.drawCircle(
          Offset(x, y),
          noteR,
          Paint()..color = c.withOpacity(opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NotesAndGlowPainter old) => true;
}

int _lowerBoundAbsT(List<int> absT, int targetMs) {
  var lo = 0;
  var hi = absT.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (absT[mid] < targetMs) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// ---------------------------------------------------------------------------
/// 4) Main View
/// ---------------------------------------------------------------------------

class SongV2PlayerView extends StatefulWidget {
  const SongV2PlayerView({
    required this.songv2Id,
    super.key,
  });

  final String songv2Id;

  @override
  State<SongV2PlayerView> createState() => _SongV2PlayerViewState();
}

class _SongV2PlayerViewState extends State<SongV2PlayerView>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _speed = 1.0;
  bool _showSpeedSlider = false;

  SongV2Model? _song;
  bool _isLoading = true;
  String? _error;

  late final Ticker _ticker;
  Duration? _lastElapsed;

  double _playerMs = 0.0;
  late final ValueNotifier<int> _songMsN = ValueNotifier<int>(0);

  YoutubePlayerController? _ytController;
  bool _ytReady = false;
  double _ytPollAccumMs = 0.0;

  late final LaneFlashController _flashCtrl = LaneFlashController();
  static const int _flashDurationMs = 180;
  late final List<Color> _laneColors;

  // ✅ drum_kit.jpg yok ama aynı anchor düzenini korumak için aspect sabit
  static const double kDrumAspect = 1.7777777778;

  int _hitCursor = 0;

  ui.Image? _noteSprite;

  int _dynamicLookahead = 2000;
  bool _enableGlow = true;
  int _maxNotesPerFrame = 900;
  int _overBudget = 0;

  final SongV2Service _service = SongV2Service();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _laneColors = List<Color>.generate(8, (i) => _getLedColor(i));
    _loadAll();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ytController?.dispose();
    _flashCtrl.dispose();
    _songMsN.dispose();
    _noteSprite?.dispose();
    super.dispose();
  }

  Color _getLedColor(int index) {
    final drumPartKey = (index + 1).toString();
    final rgb = DrumParts.drumParts[drumPartKey]?['rgb'] as List<dynamic>?;
    if (rgb != null && rgb.length == 3) {
      return Color.fromRGBO(rgb[0] as int, rgb[1] as int, rgb[2] as int, 1);
    }
    return Colors.white;
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final s = await _service.getSongV2ById(context, widget.songv2Id);
      if (s == null) {
        setState(() {
          _error = 'Song not found';
          _isLoading = false;
        });
        return;
      }
      _song = s;
      _dynamicLookahead = s.lookaheadMs;

      // ✅ NOTE sprite'ı unutma (yoksa raw atlas çalışmaz)
      _noteSprite = await _createNoteSprite();

      if (s.source.type.toLowerCase() == 'youtube') {
        _ytController = YoutubePlayerController(
          initialVideoId: s.source.videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            hideControls: true,
            enableCaption: false,
          ),
        )..addListener(() {
            final ready = _ytController?.value.isReady ?? false;
            if (ready != _ytReady) setState(() => _ytReady = ready);
          });

        _ytController!.setPlaybackRate(_nearestPlaybackRate(_speed));
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _isLoading = false;
      });
    }
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying || _song == null) return;

    final last = _lastElapsed;
    _lastElapsed = elapsed;
    if (last == null) return;

    final dtMs = (elapsed - last).inMicroseconds / 1000.0;

    const frameBudget = 16.7;
    if (dtMs > frameBudget * 1.25) {
      _overBudget++;
      if (_overBudget >= 3) {
        _enableGlow = false;
        _dynamicLookahead = math.min(_dynamicLookahead, 1500);
        _maxNotesPerFrame = math.min(_maxNotesPerFrame, 600);
      }
    } else {
      _overBudget = 0;
      if (!_enableGlow && dtMs < frameBudget * 0.85) _enableGlow = true;
      if (_song != null && _dynamicLookahead < _song!.lookaheadMs) {
        _dynamicLookahead = math.min(_dynamicLookahead + 50, _song!.lookaheadMs);
      }
      _maxNotesPerFrame = math.min(_maxNotesPerFrame + 40, 900);
    }

    if (_ytController != null && _ytReady) {
      _ytPollAccumMs += dtMs;
      if (_ytPollAccumMs >= 350.0) {
        final posMs = _ytController!.value.position.inMilliseconds.toDouble();
        final diff = posMs - _playerMs;
        _playerMs += diff * 0.08;
        _ytPollAccumMs = 0.0;
      } else {
        _playerMs += dtMs * _speed;
      }
    } else {
      _playerMs += dtMs * _speed;
    }

    final songMs = (_playerMs - _song!.syncMs).round();
    _updateLaneHitsCursor(songMs);
    _flashCtrl.decay(dtMs);

    if (_playerMs >= _song!.durationMs) {
      _playerMs = _song!.durationMs.toDouble();
      _isPlaying = false;
      _lastElapsed = null;
      _ticker.stop();
      setState(() {});
    }

    _songMsN.value = songMs;
  }

  void _updateLaneHitsCursor(int songMs) {
    final s = _song!;
    final absT = s.absT;
    final n = absT.length;
    if (n == 0) return;

    final hitWindow = (s.hitMs / 2).round();

    while (_hitCursor < n && absT[_hitCursor] < songMs - hitWindow) {
      _hitCursor++;
    }

    for (int i = _hitCursor; i < n && absT[i] <= songMs + hitWindow; i++) {
      if ((absT[i] - songMs).abs() <= hitWindow) {
        final mask = s.m[i];
        for (int lane = 0; lane < 8; lane++) {
          if ((mask & (1 << lane)) != 0) {
            _flashCtrl.flashLane(lane, _flashDurationMs.toDouble());
          }
        }
      }
    }
  }

  void _togglePlay() {
    final s = _song;
    if (s == null) return;

    setState(() {
      if (_playerMs >= s.durationMs) {
        _playerMs = 0.0;
        _hitCursor = 0;
        _flashCtrl.reset();
      }
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
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

  void _onSpeedChanged(double v) {
    final rate = _nearestPlaybackRate(v);
    setState(() => _speed = rate);
    if (_ytController != null && _ytReady) _ytController!.setPlaybackRate(rate);
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }
    if (_song == null) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      // ✅ gradient görünmesi için transparent
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: AppDecorations.backgroundDecoration(isDarkMode),
        child: LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            final safe = MediaQuery.of(context).padding;

            final dstRect = computeDrumRect(
              screen: size,
              safe: safe,
              aspect: kDrumAspect,
            );

            return Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _NotesAndGlowPainter(
                      song: _song!,
                      songMs: _songMsN,
                      dstRect: dstRect,
                      safe: safe,
                      laneColors: _laneColors,
                      flashCtrl: _flashCtrl,
                      noteSprite: _noteSprite,
                      enableGlow: _enableGlow,
                      maxNotesPerFrame: _maxNotesPerFrame,
                      dynamicLookahead: _dynamicLookahead,
                      isDarkMode: isDarkMode, // ✅
                    ),
                    isComplex: true,
                    willChange: true,
                    child: const SizedBox.expand(),
                  ),
                ),

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

                // ✅ Back button: her zeminde görünür "pill"
                Positioned(
                  top: safe.top + 10,
                  left: 12,
                  child: _PillIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                    darkMode: isDarkMode,
                  ),
                ),

                Positioned(
                  top: safe.top + 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _showSpeedSlider = !_showSpeedSlider),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        width: _showSpeedSlider ? math.min(280, size.width * 0.75) : 90,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: _showSpeedSlider
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Speed', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                      ),
                                      child: Slider(
                                        value: _speed,
                                        min: 0.25,
                                        max: 2.0,
                                        divisions: 7,
                                        label: '${_speed.toStringAsFixed(2)}x',
                                        onChanged: _onSpeedChanged,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_speed.toStringAsFixed(2)}x',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : Text(
                                '${_speed.toStringAsFixed(2)}x',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Opacity(
                    opacity: _isPlaying ? 0.18 : 0.85,
                    child: FloatingActionButton.large(
                      backgroundColor: _isPlaying ? Colors.red : Colors.green,
                      onPressed: _togglePlay,
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 44),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ✅ Back button widget (zeminden bağımsız görünür)
class _PillIconButton extends StatelessWidget {
  const _PillIconButton({
    required this.icon,
    required this.onTap,
    required this.darkMode,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool darkMode;

  @override
  Widget build(BuildContext context) {
    // Her zeminde kontrast: koyu modda daha açık pill, açık modda daha koyu pill
    final bg = darkMode ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.55);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(0.25),
              )
            ],
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Helpers
/// ---------------------------------------------------------------------------

Rect computeDrumRect({
  required Size screen,
  required EdgeInsets safe,
  required double aspect,
}) {
  final availW = screen.width;
  final availH = screen.height - safe.top - safe.bottom;

  double drawW = availW;
  double drawH = drawW / aspect;

  if (drawH > availH) {
    drawH = availH;
    drawW = drawH * aspect;
  }

  final left = (availW - drawW) / 2.0;
  final top = safe.top + (availH - drawH);
  return Rect.fromLTWH(left, top, drawW, drawH);
}

Future<ui.Image> _createNoteSprite() async {
  const size = 48;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
  final s = size.toDouble();

  final path = Path()
    ..moveTo(s * 0.5, s * 0.06)
    ..cubicTo(s * 0.82, s * 0.22, s * 0.92, s * 0.50, s * 0.74, s * 0.80)
    ..cubicTo(s * 0.62, s * 0.96, s * 0.38, s * 0.96, s * 0.26, s * 0.80)
    ..cubicTo(s * 0.08, s * 0.50, s * 0.18, s * 0.22, s * 0.5, s * 0.06)
    ..close();

  // ✅ Beyaz mask: drawRawAtlas + BlendMode.srcIn ile çok iyi tint olur
  canvas.drawPath(
    path,
    Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFFFFFFFF),
  );

  final pic = recorder.endRecording();
  final img = await pic.toImage(size, size);
  pic.dispose();
  return img;
}
