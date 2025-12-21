import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:drumly/models/song_model_v2.dart';
import 'package:drumly/models/score_v2_model.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/widgets/song_led_player.dart'; // Import helper functions

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
  SongModelV2? _songModel;
  Timer? _speedControlTimer;

  late Ticker _ticker;
  Duration? _lastElapsed;
  double _posMs = 0.0;
  ScoreV2? _score; // Parsed score for notes
  final double _audioOffsetMs = 0;

  // Helper to get LED color from constants
  Color _getLedColor(int index) {
    final drumPartKey = (index + 1).toString(); // index 0-7 -> drumParts '1'-'8'
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
    if (!_isPlaying || _score == null) return;

    final last = _lastElapsed;
    _lastElapsed = elapsed;

    if (last == null) return;

    final dtMs = (elapsed - last).inMicroseconds / 1000.0;

    setState(() {
      // _posMs represents actual elapsed time (not speed-adjusted)
      // The speed adjustment happens in tickToMs/msToTick conversions
      _posMs += dtMs * _speed;
      final dur = _getDurationMs();
      if (dur > 0 && _posMs >= dur) {
        _posMs = dur;
        _isPlaying = false;
        _lastElapsed = null;
        _ticker.stop();
      }
    });
  }

  double _getDurationMs() {
    if (_score == null) return 0;
    final lt = lastTickOf(_score!);
    // Get duration at current speed - faster speed = shorter duration
    return tickToMs(lt, _score!, speed: _speed, audioOffsetMs: _audioOffsetMs);
  }

  void _togglePlay() {
    if (_score == null) return;

    setState(() {
      // If at end, restart from beginning
      if (_posMs >= _getDurationMs()) {
        _posMs = 0.0;
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
    // When speed changes, we need to recalculate _posMs to maintain sync
    // First get current tick position (using old speed)
    final currentTick = _score != null 
        ? msToTick(_posMs, _score!, speed: _speed, audioOffsetMs: _audioOffsetMs)
        : 0;
    
    setState(() {
      _speed = value;
      // Recalculate _posMs with new speed to maintain same tick position
      if (_score != null) {
        _posMs = tickToMs(currentTick, _score!, speed: _speed, audioOffsetMs: _audioOffsetMs);
      }
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
      final scoreV2Model = ScoreV2Model.fromJsonString(jsonString);

      // Parse to ScoreV2 for falling notes
      final scoreV2Widget = ScoreV2(
        ppq: scoreV2Model.ppq,
        tempoMap: scoreV2Model.tempoMap
            .map((t) => TempoChange(
                  tick: t.tick,
                  bpm: t.bpm.toDouble(),
                ))
            .toList(),
        events: scoreV2Model.events
            .map((e) => ScoreEvent(
                  t0: e.t0,
                  dt: e.dt,
                  m: e.m,
                ))
            .toList(),
      );

      setState(() {
        _songModel = SongModelV2(
          name: 'Demo Song',
          scoreV2: scoreV2Model,
          bpm: scoreV2Model.tempoMap.isNotEmpty
              ? scoreV2Model.tempoMap.first.bpm
              : null,
        );
        _score = scoreV2Widget;
      });
    } catch (e) {
      debugPrint('Failed to load score: $e');
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
      body: _songModel == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Main content - 8 vertical lanes
                _buildLanesView(
                    hitZoneHeight, drumNameFontSize, screenHeight, screenWidth),

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
                            width: 1,
                          ),
                        ),
                        child: _showSpeedControl
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                            enabledThumbRadius: 8,),
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
                      controlsTextSize, infoTextSize),

                // Play/Pause button - Center with dynamic opacity
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity:
                        (_isPlaying && _posMs < _getDurationMs()) ? 0.3 : 0.8,
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
      double screenHeight, double screenWidth) {
    // Calculate current active mask
    final curTick = _score != null
        ? msToTick(_posMs, _score!,
            speed: _speed, audioOffsetMs: _audioOffsetMs)
        : 0;
    final activeMask = _score != null ? maskAtTick(_score!, curTick) : 0;

    // Calculate falling notes with corrected 8-lane logic
    final notes = _score != null
        ? _buildFallingNotes8Lanes(screenHeight, screenWidth, hitZoneHeight)
        : <_FallingNote8Lane>[];

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
                            width: 1,
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
                                        )
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
                  )),
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
                            _getLedColor(n.lane)
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getLedColor(n.lane).withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
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
                    if (_songModel?.scoreV2 != null) ...[
                      Text(
                        'PPQ: ${_songModel!.scoreV2!.ppq}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: infoSize,
                        ),
                      ),
                      Text(
                        'Events: ${_songModel!.scoreV2!.events.length}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: infoSize,
                        ),
                      ),
                      Text(
                        'Tempo Changes: ${_songModel!.scoreV2!.tempoMap.length}',
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

  // Custom falling notes calculation for 8 vertical lanes
  List<_FallingNote8Lane> _buildFallingNotes8Lanes(
    double screenHeight,
    double screenWidth,
    double hitZoneHeight,
  ) {
    if (_score == null) return [];

    // Adjust lookAhead and past windows based on speed for smoother experience at all speeds
    final speedFactor = 1.0 / _speed.clamp(0.5, 2.0);
    final lookAheadMs = 2200.0 * speedFactor;
    final pastMs = 200.0 * speedFactor;

    final events = _score!.events;
    if (events.isEmpty) return [];

    final startMs = _posMs - pastMs;
    final endMs = _posMs + lookAheadMs;

    final startTick = msToTick(startMs, _score!,
        speed: _speed, audioOffsetMs: _audioOffsetMs);
    final endTick =
        msToTick(endMs, _score!, speed: _speed, audioOffsetMs: _audioOffsetMs) +
            1;

    final notes = <_FallingNote8Lane>[];
    final spawnY = 0.0; // Start from top
    final targetY = screenHeight - hitZoneHeight / 2; // Center of hit zone

    for (final e in events) {
      if (e.t0 > endTick) break;
      if (e.t0 < startTick) continue;

      final eventMs =
          tickToMs(e.t0, _score!, speed: _speed, audioOffsetMs: _audioOffsetMs);
      final alphaRaw = (eventMs - _posMs) / lookAheadMs; // 0 at hit, 1 at spawn

      if (alphaRaw < -pastMs / lookAheadMs || alphaRaw > 1.15) continue;

      // Calculate Y position (linear interpolation from spawn to target)
      final y = targetY + (spawnY - targetY) * alphaRaw;

      // Calculate opacity with smoother falloff
      double opacity;
      if (alphaRaw < 0) {
        // Past notes fade out
        opacity = (1 + alphaRaw * 5).clamp(0.0, 1.0);
      } else {
        // Future notes fade in at spawn
        opacity = (1 - (alphaRaw - 0.85) * 2.5).clamp(0.3, 1.0);
      }

      // Wider hit window for slow speeds
      final hitWindowMs = 80.0 * speedFactor;

      // Check each lane (0-7)
      for (var lane = 0; lane < 8; lane++) {
        if ((e.m & (1 << lane)) != 0) {
          notes.add(_FallingNote8Lane(
            lane: lane,
            y: y,
            opacity: opacity,
            isHit: (eventMs - _posMs).abs() <= hitWindowMs,
          ));
        }
      }
    }

    return notes;
  }
}

class _FallingNote8Lane {
  _FallingNote8Lane({
    required this.lane,
    required this.y,
    required this.opacity,
    required this.isHit,
  });
  final int lane;
  final double y;
  final double opacity;
  final bool isHit;
}
