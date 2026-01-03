import 'dart:async';

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/player/drum_part_badge.dart';
import 'package:drumly/screens/player/player_shared.dart';
import 'package:drumly/screens/training/trraning_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class PlayerView extends StatefulWidget {
  const PlayerView(this.songModel, {super.key, this.hideTimeControls = false});
  final TraningModel songModel;
  final bool hideTimeControls;

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  final AudioPlayer _player = AudioPlayer();
  late AppProvider appProvider;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double playerSpeed = 1.0;

  Color? turtleColor;
  Color? rabbitColor;

  bool showSpeedText = false;
  Timer? _speedTextTimer;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<ProcessingState>? _processingStateSub;
  
  List<int> curretnData = [];
  final Set<int> _sentNoteIndices = {};
  static const int baseLedDuration = 100;
  final List<String> sentDrumParts = [];
  Color rondomColor = Colors.black;
  Duration prevPos = Duration.zero;
  
  // 🚀 OPTIMIZATION: Track disposal state
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    appProvider = Provider.of<AppProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) _initAudio();
    });
  }

  Future<void> _initAudio() async {
    if (_isDisposed) return;
    
    try {
      // 🚀 OPTIMIZATION: Fire-and-forget analytics
      unawaited(
        FirebaseAnalytics.instance.logEvent(name: widget.songModel.title ?? 'unknown'),
      );

      _playerStateSub = _player.playerStateStream.listen((_) {
        if (mounted && !_isDisposed) setState(() {});
      });

      await _player.setUrl(widget.songModel.fileUrl!);
      _duration = _player.duration ?? Duration.zero;

      if (mounted && !_isDisposed) setState(() {});
      _listenPosition();

      _processingStateSub = _player.processingStateStream.listen((state) async {
        if (_isDisposed) return;
        if (state == ProcessingState.completed) {
          await _player.seek(Duration.zero);
          if (!_isDisposed) {
            setState(() {
              prevPos = Duration.zero;
              _sentNoteIndices.clear();
            });
          }
        }
      });
    } catch (e, stack) {
      debugPrint('Audio load error: $e\n$stack');
    }
  }

  void _listenPosition() {
    if (_isDisposed) return;
    
    final bluetoothBloc = context.read<BluetoothBloc>();

    _positionSub = _player
        .createPositionStream(minPeriod: const Duration(milliseconds: 10))
        .listen((pos) async {
      if (!mounted || _isDisposed) return;

      for (var note in widget.songModel.notes!) {
        final idx = note.i;
        final start = Duration(milliseconds: note.sM);

        if (prevPos < start &&
            pos >= start &&
            !_sentNoteIndices.contains(idx)) {
          _sentNoteIndices.add(idx);

          curretnData.clear();
          sentDrumParts.clear();

          for (int drumPart in note.led) {
            if (drumPart <= 0 || drumPart > 8) continue;
            final drum = await StorageService.getDrumPart(drumPart.toString());
            if (drum?.led == null || drum?.rgb == null) continue;
            sentDrumParts.add(drum!.name!);
            curretnData.add(drum.led!);
            curretnData.addAll(drum.rgb!);
            rondomColor = getRandomColor(appProvider.isDarkMode);
          }

          debugPrint('► Note $idx triggered: $curretnData');
          await SendData().sendHexData(bluetoothBloc, curretnData);
        }
      }

      prevPos = pos;
      if (!_isDisposed) setState(() => _position = pos);
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _processingStateSub?.cancel();
    _player.stop();
    _player.dispose();
    _speedTextTimer?.cancel();
    
    super.dispose();
  }

  void _updateButtonColors() {
    setState(() {
      turtleColor = null;
      rabbitColor = null;
      if (playerSpeed == 0.5) {
        turtleColor = Colors.deepPurple[900];
      } else if (playerSpeed == 0.75) {
        turtleColor = Colors.deepPurple[300];
      } else if (playerSpeed == 1.25) {
        rabbitColor = Colors.deepPurple[300];
      } else if (playerSpeed == 1.5) {
        rabbitColor = Colors.deepPurple[900];
      }
    });
  }

  void _showSpeedTextTemporarily() {
    setState(() => showSpeedText = true);
    _speedTextTimer?.cancel();
    _speedTextTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => showSpeedText = false);
    });
  }

  void _onTurtlePressed(BluetoothBloc bluetoothBloc) async {
    if (playerSpeed > 0.5) {
      playerSpeed = (playerSpeed - 0.25).clamp(0.5, 1.5);
      await _applySpeedAndReset(bluetoothBloc);
      _updateButtonColors();
      _showSpeedTextTemporarily();
    }
  }

  void _onRabbitPressed(BluetoothBloc bluetoothBloc) async {
    if (playerSpeed < 1.5) {
      playerSpeed = (playerSpeed + 0.25).clamp(0.5, 1.5);
      await _applySpeedAndReset(bluetoothBloc);
      _updateButtonColors();
      _showSpeedTextTemporarily();
    }
  }

  Future<void> _applySpeedAndReset(BluetoothBloc bluetoothBloc) async {
    await _player.setSpeed(playerSpeed);
    final int ledDuration = (baseLedDuration / playerSpeed).round();
    await SendData().sendHexData(bluetoothBloc, splitToBytes(ledDuration));
    _updateButtonColors();
    _showSpeedTextTemporarily();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final safeArea = mediaQuery.padding;
    
    // Calculate responsive dimensions
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
    final availableWidth = screenSize.width - safeArea.left - safeArea.right;
    final minDimension = availableWidth < availableHeight 
        ? availableWidth 
        : availableHeight;
    
    // Responsive spacing ratios
    final topSpacing = availableHeight * 0.02;
    final bottomSpacing = availableHeight * 0.03;
    final horizontalPadding = availableWidth * 0.05;
    final titleFontSize = (minDimension * 0.055).clamp(18.0, 28.0);
    final timeFontSize = (minDimension * 0.035).clamp(12.0, 18.0);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentHeight = constraints.maxHeight;
            final contentWidth = constraints.maxWidth;
            
            // Calculate proportional sizes for each section
            final visualizerHeight = contentHeight * 0.5;
            
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                  children: [
                    // Top spacer
                    SizedBox(height: topSpacing),
                    
                    // Drum visualizer area - flexible
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentWidth * 0.95,
                            maxHeight: visualizerHeight,
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: sentDrumParts.isNotEmpty || _player.playing
                                ? DrumOverlayView(
                                    selectedParts: sentDrumParts,
                                    highlightColor: rondomColor,
                                  )
                                : Lottie.asset(
                                    'assets/animation/drummer.json',
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Title area - flexible
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.songModel.title ?? 'Unknown Title',
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Progress slider area - flexible
                    if (!widget.hideTimeControls)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: (minDimension * 0.008).clamp(3.0, 6.0),
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: (minDimension * 0.02).clamp(8.0, 14.0),
                                  ),
                                ),
                                child: Slider(
                                  max: _duration.inSeconds.toDouble(),
                                  value: _position.inSeconds
                                      .clamp(0, _duration.inSeconds)
                                      .toDouble(),
                                  onChanged: (value) =>
                                      _player.seek(Duration(seconds: value.toInt())),
                                  allowedInteraction: SliderInteraction.tapAndSlide,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding * 0.3,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_position),
                                      style: TextStyle(fontSize: timeFontSize),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: TextStyle(fontSize: timeFontSize),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Control buttons area - flexible
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                controlButton(
                                  imagePath: 'assets/images/icons/turtle.png',
                                  onPressed: () => _onTurtlePressed(bluetoothBloc),
                                  backgroundColor: turtleColor,
                                ),
                                controlButton(
                                  icon: _player.playing ? Icons.pause : Icons.play_arrow,
                                  onPressed: () async {
                                    if (_player.playing) {
                                      await _player.pause();
                                      await SendData().sendHexData(bluetoothBloc, [0]);
                                    } else {
                                      await showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Countdown(),
                                      );
                                      if (mounted) await _player.play();
                                    }
                                  },
                                  iconSize: 52,
                                ),
                                controlButton(
                                  imagePath: 'assets/images/icons/rabbit.png',
                                  onPressed: () => _onRabbitPressed(bluetoothBloc),
                                  backgroundColor: rabbitColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Bottom spacer
                    SizedBox(height: bottomSpacing),
                  ],
                ),
                
                // Speed indicator overlay
                if (showSpeedText)
                  Positioned(
                    bottom: contentHeight * 0.18,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: minDimension * 0.04,
                        vertical: minDimension * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(minDimension * 0.05),
                      ),
                      child: Text(
                        'Speed: ${playerSpeed.toStringAsFixed(2)}x',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: timeFontSize,
                        ),
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
