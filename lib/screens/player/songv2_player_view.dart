import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/models/songv2_model.dart';
import 'package:drumly/services/songv2_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  required SongV2Model song,
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

  var idx = _lowerBoundAbsT(absT, start);
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

/// SongV2 Player View - Backend'den veri çekerek LED player gösterir
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
  bool _showControls = false;
  bool _showSpeedControl = false;
  SongV2Model? _song;
  Timer? _speedControlTimer;
  bool _isLoading = true;
  String? _errorMessage;

  late Ticker _ticker;
  Duration? _lastElapsed;
  double _playerMs = 0.0; // Player time in ms

  // YouTube player
  YoutubePlayerController? _ytController;
  bool _ytReady = false;

  final SongV2Service _songV2Service = SongV2Service();

  // Helper to get LED color from constants
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
    _loadSongFromBackend();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _speedControlTimer?.cancel();
    _ytController?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying || _song == null) return;

    final last = _lastElapsed;
    _lastElapsed = elapsed;

    if (last == null) return;

    // Prefer syncing to YouTube player's position if available
    if (_ytController != null && _ytReady) {
      final pos = _ytController!.value.position;
      setState(() {
        _playerMs = pos.inMilliseconds.toDouble();
        final dur = _song!.durationMs;
        if (_playerMs >= dur) {
          _playerMs = dur.toDouble();
          _isPlaying = false;
          _lastElapsed = null;
          _ticker.stop();
        }
      });
      return;
    }

    // Fallback: advance with local ticker
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
      if (_playerMs >= _song!.durationMs) {
        _playerMs = 0.0;
      }
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _lastElapsed = Duration.zero;
      _ticker.start();
      // Sync and play YouTube
      if (_ytController != null && _ytReady) {
        _ytController!.seekTo(Duration(milliseconds: _playerMs.toInt()));
        _ytController!.play();
      }
    } else {
      _lastElapsed = null;
      _ticker.stop();
      if (_ytController != null && _ytReady) {
        _ytController!.pause();
      }
    }
  }

  void _toggleSpeedControl() {
    setState(() {
      _showSpeedControl = !_showSpeedControl;
    });

    _speedControlTimer?.cancel();

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
    final rate = _nearestPlaybackRate(value);
    setState(() {
      _speed = rate;
    });

    // Apply to YouTube player
    if (_ytController != null && _ytReady) {
      _ytController!.setPlaybackRate(rate);
    }

    _speedControlTimer?.cancel();
    _speedControlTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSpeedControl = false;
        });
      }
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

      setState(() {
        _song = song;
        _isLoading = false;
      });

      // Initialize YouTube controller if source is YouTube
      try {
        if (song.source.type.toLowerCase() == 'youtube') {
          _ytController = YoutubePlayerController(
            initialVideoId: song.source.videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              controlsVisibleAtStart: false,
              hideControls: true,
              disableDragSeek: false,
              enableCaption: false,
              forceHD: false,
            ),
          )..addListener(() {
              final ready = _ytController?.value.isReady ?? false;
              if (ready != _ytReady) {
                setState(() => _ytReady = ready);
              }
            });

          // Set initial playback rate
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
      debugPrint('Failed to load song: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading song...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    _buildLanesView(
                      hitZoneHeight,
                      drumNameFontSize,
                      screenHeight,
                      screenWidth,
                    ),

                    // Hidden YouTube player (audio source)
                    if (_ytController != null)
                      Positioned(
                        top: -1000, // keep offscreen
                        child: SizedBox(
                          width: 1,
                          height: 1,
                          child: YoutubePlayer(
                            controller: _ytController!,
                            showVideoProgressIndicator: false,
                            onReady: () {
                              setState(() => _ytReady = true);
                            },
                          ),
                        ),
                      ),

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

                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
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
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            trackHeight: 3,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                              enabledThumbRadius: 8,
                                            ),
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
                      _buildControlsOverlay(
                        controlsPadding,
                        controlsTitleSize,
                        controlsTextSize,
                        infoTextSize,
                      ),

                    // Play/Pause button
                    Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: (_isPlaying &&
                                _playerMs < (_song?.durationMs ?? 0))
                            ? 0.3
                            : 0.8,
                        child: FloatingActionButton.large(
                          backgroundColor:
                              _isPlaying ? Colors.red : Colors.green,
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

  Widget _buildLanesView(
    double hitZoneHeight,
    double drumNameFontSize,
    double screenHeight,
    double screenWidth,
  ) {
    final songMs = (_playerMs - (_song?.syncMs ?? 0)).round();

    int activeMask = 0;
    if (_song != null) {
      final absT = _song!.absT;
      for (var i = 0; i < absT.length; i++) {
        if ((absT[i] - songMs).abs() <= (_song!.hitMs / 2)) {
          activeMask |= _song!.m[i];
        }
      }
    }

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
                                    color:
                                        _getLedColor(index).withOpacity(0.6),
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
            ),
          ),
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
                            min: 0.25,
                            max: 2.0,
                            divisions: 7,
                            label: '${_speed.toStringAsFixed(2)}x',
                            onChanged: (value) => _onSpeedChanged(value),
                          ),
                        ),
                        Text(
                          '${_speed.toStringAsFixed(2)}x',
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
