import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:drumly/constants.dart';

class DrumlySongV1 {

  DrumlySongV1({
    required this.v,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.ts,
    required this.durationMs,
    required this.syncMs,
    required this.lookaheadMs,
    required this.hitMs,
    required this.calibrateSpeed,
    required this.dt,
    required this.m,
  });

  factory DrumlySongV1.fromJson(Map<String, dynamic> json) => DrumlySongV1(
      v: json['v'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String,
      bpm: json['bpm'] as int,
      ts: json['ts'] as String,
      durationMs: json['duration_ms'] as int,
      syncMs: json['sync_ms'] as int,
      lookaheadMs: json['lookahead_ms'] as int,
      hitMs: json['hit_ms'] as int,
      calibrateSpeed: (json['calibrate_speed'] as num).toDouble(),
      dt: (json['dt'] as List).cast<int>(),
      m: (json['m'] as List).cast<int>(),
    );
  final int v;
  final String title;
  final String artist;
  final int bpm;
  final String ts;
  final int durationMs;
  final int syncMs;
  final int lookaheadMs;
  final int hitMs;
  final double calibrateSpeed;

  final List<int> dt; // delta ms
  final List<int> m; // bitmask (8-bit)

  // Optional: cache abs times
  List<int>? _absT;

  /// Build absolute times (ms) once
  List<int> get absT {
    final cached = _absT;
    if (cached != null) return cached;

    final out = List<int>.filled(dt.length, 0);
    var t = 0;
    for (var i = 0; i < dt.length; i++) {
      t += dt[i];
      out[i] = t;
    }
    _absT = out;
    return out;
  }

  /// Find first index with absT[idx] >= target
  int lowerBoundAbsT(int targetMs) {
    final a = absT;
    var lo = 0, hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] < targetMs) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

class FallingNote {

  FallingNote({
    required this.lane,
    required this.xPct,
    required this.y,
    required this.opacity,
    required this.isHit,
  });
  final int lane; // 0..7
  final double xPct; // 0..100
  final double y; // px
  final double opacity;
  final bool isHit;
}

/// lane bitmask -> lanes
List<int> lanesFromMask(int mask) {
  final out = <int>[];
  for (var i = 0; i < 8; i++) {
    if ((mask & (1 << i)) != 0) out.add(i);
  }
  return out;
}

double clamp(double v, double a, double b) => math.max(a, math.min(b, v));

List<FallingNote> buildVisibleNotes({
  required DrumlySongV1 song,
  required int songMs, // "tab ms" (playerMs - syncMs)
  int pastMs = 160,
  double stageH = 420,
  double padAreaH = 190,
  double spawnY = 24,
}) {
  final lookahead = song.lookaheadMs;
  final start = songMs - pastMs;
  final end = songMs + lookahead;

  final absT = song.absT;
  final n = absT.length;
  if (n == 0) return const [];

  var idx = song.lowerBoundAbsT(start);
  // biraz geri sar — ekran "hit" efektini kaçırmasın
  idx = math.max(0, idx - 16);

  final notes = <FallingNote>[];

  final padRowH = padAreaH / 2.0;
  final padTop = stageH - padAreaH;

  for (var i = idx; i < n; i++) {
    final t = absT[i];
    if (t > end) break;

    final alphaRaw = (t - songMs) / lookahead; // 0: hit, 1: spawn
    final alpha = clamp(alphaRaw, -pastMs / lookahead, 1.1);

    final isHit = (t - songMs).abs() <= 18; // daha sıkı hissiyat

    // y interpolate
    // targetY: lane row'a göre (üst 4 lane row0, alt 4 lane row1 gibi)
    final mask = song.m[i];
    final lanes = lanesFromMask(mask);

    for (final lane in lanes) {
      final col = lane % 4;
      final row = lane < 4 ? 0 : 1;

      final targetY = padTop + row * padRowH + padRowH / 2.0;
      final y = targetY + (spawnY - targetY) * alpha;

      final xPct = (100.0 / 4.0) * (col + 0.5);

      var opacity = 1.0;
      if (alphaRaw < 0) {
        opacity = clamp(1 + alphaRaw * 6, 0, 1);
      } else {
        opacity = clamp(1 - (alphaRaw - 0.85) * 3, 0.2, 1);
      }

      if (y < -40 || y > stageH + 60 || opacity <= 0.02) continue;

      notes.add(FallingNote(
        lane: lane,
        xPct: xPct,
        y: y,
        opacity: opacity,
        isHit: isHit,
      ),);
    }
  }

  return notes;
}

/// Demo sayfası - song_notes.json dosyasını kullanarak LED player'ı test eder
class LedPlayerDemoPage extends StatefulWidget {
  const LedPlayerDemoPage({super.key});

  @override
  State<LedPlayerDemoPage> createState() => _LedPlayerDemoPageState();
}

class _LedPlayerDemoPageState extends State<LedPlayerDemoPage>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _speed = 1.0;
  bool _showControls = false;
  bool _showSpeedControl = false;
  DrumlySongV1? _song;
  Timer? _speedControlTimer;

  late Ticker _ticker;
  Duration? _lastElapsed;
  double _playerMs = 0.0; // Player time in ms

  // Helper to get LED color from constants
  Color _getLedColor(int index) {
    final drumPartKey =
        (index + 1).toString(); // index 0-7 -> drumParts '1'-'8'
    final rgb = DrumParts.drumParts[drumPartKey]?['rgb'] as List<dynamic>?;
    if (rgb != null && rgb.length == 3) {
      return Color.fromRGBO(rgb[0] as int, rgb[1] as int, rgb[2] as int, 1);
    }
    return Colors.white; // fallback
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _loadScore();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _speedControlTimer?.cancel();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying || _song == null) return;

    final last = _lastElapsed;
    _lastElapsed = elapsed;

    if (last == null) return;

    final dtMs = (elapsed - last).inMicroseconds / 1000.0;

    setState(() {
      _playerMs += dtMs * _speed;
      final dur = _song!.durationMs;
      if (_playerMs >= dur) {
        _playerMs = dur.toDouble();
        _isPlaying = false;
        _lastElapsed = null;
        _ticker.stop();
      }
    });
  }

  void _togglePlay() {
    if (_song == null) return;

    setState(() {
      // If at end, restart from beginning
      if (_playerMs >= _song!.durationMs) {
        _playerMs = 0.0;
      }
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else {
      _lastElapsed = null;
      _ticker.stop();
    }
  }

  void _toggleSpeedControl() {
    setState(() {
      _showSpeedControl = !_showSpeedControl;
    });

    // Cancel any existing timer
    _speedControlTimer?.cancel();

    // If opening, start new timer to auto-close after 3 seconds
    if (_showSpeedControl) {
      _speedControlTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSpeedControl = false;
          });
        }
      });
    }
  }

  void _onSpeedChanged(double value) {
    setState(() {
      _speed = value;
    });

    // Reset timer when speed changes
    _speedControlTimer?.cancel();
    _speedControlTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSpeedControl = false;
        });
      }
    });
  }

  Future<void> _loadScore() async {
    try {
      final jsonString = await rootBundle.loadString('assets/song_notes.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final song = DrumlySongV1.fromJson(jsonData);

      setState(() {
        _song = song;
      });
    } catch (e) {
      debugPrint('Failed to load song: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Dinamik boyutlar
    final topGradientHeight = screenHeight * 0.12;
    final hitZoneHeight = screenHeight * 0.1;
    final drumNameFontSize = screenHeight * 0.012;
    final playButtonIconSize = screenHeight * 0.06;
    final controlsPadding = screenWidth * 0.05;
    final controlsTitleSize = screenHeight * 0.03;
    final controlsTextSize = screenHeight * 0.018;
    final infoTextSize = screenHeight * 0.015;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _song == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Main content - 8 vertical lanes
                _buildLanesView(
                    hitZoneHeight, drumNameFontSize, screenHeight, screenWidth,),

                // Top gradient overlay
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
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Speed control at top
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggleSpeedControl,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _showSpeedControl
                            ? screenWidth * 0.75
                            : screenWidth * 0.2,
                        padding: EdgeInsets.symmetric(
                          horizontal: _showSpeedControl
                              ? screenWidth * 0.03
                              : screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: _showSpeedControl
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    flex: 0,
                                    child: Text(
                                      'Speed:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenHeight * 0.015,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _speed,
                                        min: 0.5,
                                        max: 2.0,
                                        divisions: 15,
                                        label: '${_speed.toStringAsFixed(1)}x',
                                        activeColor: Colors.blue,
                                        onChanged: _onSpeedChanged,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 0,
                                    child: Text(
                                      '${_speed.toStringAsFixed(1)}x',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenHeight * 0.015,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '${_speed.toStringAsFixed(1)}x',
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

                // Controls overlay
                if (_showControls)
                  _buildControlsOverlay(controlsPadding, controlsTitleSize,
                      controlsTextSize, infoTextSize,),

                // Play/Pause button - Center with dynamic opacity
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity:
                        (_isPlaying && _playerMs < (_song?.durationMs ?? 0))
                            ? 0.3
                            : 0.8,
                    child: FloatingActionButton.large(
                      backgroundColor: _isPlaying ? Colors.red : Colors.green,
                      onPressed: _togglePlay,
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: playButtonIconSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLanesView(double hitZoneHeight, double drumNameFontSize,
      double screenHeight, double screenWidth,) {
    // Calculate song time (playerMs - syncMs)
    final songMs = (_playerMs - (_song?.syncMs ?? 0)).round();

    // Calculate current active mask
    int activeMask = 0;
    if (_song != null) {
      final absT = _song!.absT;
      for (var i = 0; i < absT.length; i++) {
        if ((absT[i] - songMs).abs() <= (_song!.hitMs / 2)) {
          activeMask |= _song!.m[i];
        }
      }
    }

    // Calculate falling notes
    final notes = _song != null
        ? buildVisibleNotes(
            song: _song!,
            songMs: songMs,
            stageH: screenHeight,
            padAreaH: hitZoneHeight * 2,
          )
        : <FallingNote>[];

    return Stack(
      children: [
        // 8 lanes
        Row(
          children: List.generate(
              8,
              (index) => Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _getLedColor(index).withOpacity(0.1),
                            Colors.black,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Hit zone at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: hitZoneHeight,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 50),
                              decoration: BoxDecoration(
                                color: (activeMask & (1 << index)) != 0
                                    ? _getLedColor(index).withOpacity(0.7)
                                    : _getLedColor(index).withOpacity(0.3),
                                border: Border.all(
                                  color: _getLedColor(index),
                                  width: 2,
                                ),
                                boxShadow: (activeMask & (1 << index)) != 0
                                    ? [
                                        BoxShadow(
                                          color: _getLedColor(index)
                                              .withOpacity(0.6),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  _getDrumName(index),
                                  style: TextStyle(
                                    color: _getLedColor(index),
                                    fontSize: drumNameFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),),
        ),

        // Falling notes overlay
        ...notes.map((n) {
          final laneWidth = screenWidth / 8;
          final noteSize = screenHeight * 0.025;
          final x = (n.lane + 0.5) * laneWidth;

          return Positioned(
            left: x - noteSize / 2,
            top: n.y - noteSize / 2,
            child: Opacity(
              opacity: n.opacity,
              child: Container(
                width: noteSize,
                height: noteSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: n.isHit
                        ? const [Color(0xFF10B981), Color(0xFF059669)]
                        : [
                            _getLedColor(n.lane).withOpacity(0.8),
                            _getLedColor(n.lane),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getLedColor(n.lane).withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
              ),
            ),
          );
        }),
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
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Controls',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: padding),

                    // Speed control
                    Row(
                      children: [
                        Text(
                          'Speed:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: textSize,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _speed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 6,
                            label: '${_speed.toStringAsFixed(1)}x',
                            onChanged: (value) =>
                                setState(() => _speed = value),
                          ),
                        ),
                        Text(
                          '${_speed.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: textSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: padding * 0.67),

                    // Info
                    if (_song != null) ...[
                      Text(
                        'Title: ${_song!.title}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: infoSize,
                        ),
                      ),
                      Text(
                        'Artist: ${_song!.artist}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: infoSize,
                        ),
                      ),
                      Text(
                        'BPM: ${_song!.bpm}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: infoSize,
                        ),
                      ),
                      Text(
                        'Time Signature: ${_song!.ts}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: infoSize,
                        ),
                      ),
                      Text(
                        'Duration: ${(_song!.durationMs / 1000).toStringAsFixed(1)}s',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: infoSize,
                        ),
                      ),
                      Text(
                        'Notes: ${_song!.dt.length}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: infoSize,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  String _getDrumName(int index) {
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
