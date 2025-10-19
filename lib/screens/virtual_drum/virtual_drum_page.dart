import 'package:drumly/screens/virtual_drum/virtual_drum_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drumly/provider/app_provider.dart';

class VirtualDrumPage extends StatefulWidget {
  const VirtualDrumPage({super.key});

  @override
  State<VirtualDrumPage> createState() => _VirtualDrumPageState();
}

class _VirtualDrumPageState extends State<VirtualDrumPage>
    with SingleTickerProviderStateMixin {
  late VirtualDrumViewModel _viewModel;
  bool _effectsExpanded = false;
  bool _playbackExpanded = false;
  final List<Offset> _padPositions = [];

  @override
  void initState() {
    super.initState();
    _viewModel = VirtualDrumViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initialize();

    // Generate random positions for pads
    _generateRandomPositions();
  }

  void _generateRandomPositions() {
    _padPositions.clear();

    // Professional drum kit layout (like the reference image):
    // Top row: Cymbals (Crash, Hi-Hats, Ride)
    // Middle: Tom1, Tom2
    // Center: Kick
    // Bottom: Snare (left), Floor Tom (right)

    _padPositions.addAll([
      // 0: Kick - center of kit
      const Offset(0.50, 1),

      // 1: Snare - left-bottom
      const Offset(0.32, 0.80),

      // 2: HiHat Close - left cymbal
      const Offset(0.20, 0.80),

      // 3: HiHat Open - left cymbal (slightly lower)
      const Offset(0.25, 0.4),

      // 4: Tom1 - upper left (high tom)
      const Offset(0.4, 0.175),

      // 5: Tom2 - upper center (mid tom)
      const Offset(0.6, 0.175),

      // 6: Floor Tom - right-bottom
      const Offset(0.7, 0.75),

      // 7: Crash - left-top cymbal
      const Offset(0.10, 0.05),

      // 8: Ride - right-top cymbal
      const Offset(0.9, 0.05),
    ]);
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).isDarkMode;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // If portrait, show reminder to rotate
    if (!isLandscape) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.screen_rotation,
                size: 80,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 24),
              Text(
                'Please rotate your device',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Rotate to landscape for the best experience',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: !_viewModel.isInitialized
          ? _buildLoadingScreen(isDark)
          : Column(
              children: [
                // Top Bar: Back button + Title + Menu buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        iconSize: 26,
                        color: isDark ? Colors.white : Colors.black,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),

                      // Title
                      const Expanded(child: SizedBox()),

                      // Effects toggle button
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => setState(
                            () => _effectsExpanded = !_effectsExpanded,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: _effectsExpanded
                                ? Colors.orange
                                : Colors.grey[600],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🎛️',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _effectsExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Playback toggle button
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => setState(
                            () => _playbackExpanded = !_playbackExpanded,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: _playbackExpanded
                                ? Colors.orange
                                : Colors.grey[600],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🎵',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _playbackExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),

                // Main content area
                Expanded(
                  child: Row(
                    children: [
                      // Left side: Drum Pads (responsive sizing)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _buildDrumPads(isDark),
                        ),
                      ),

                      // Right side: Effects and Playback (expandable)
                      if (_effectsExpanded || _playbackExpanded)
                        Expanded(
                          child: Container(
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    if (_effectsExpanded) ...[
                                      _buildExpandableEffects(isDark),
                                      const SizedBox(height: 8),
                                    ],
                                    if (_playbackExpanded)
                                      _buildExpandablePlayback(isDark),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Loading Screen
  Widget _buildLoadingScreen(bool isDark) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDark ? Colors.white : Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Virtual Drum...',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading audio engine',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  /// 🥁 Drum Pads - Random positions in circular shape
  Widget _buildDrumPads(bool isDark) => LayoutBuilder(
        builder: (context, constraints) {
          const basePadSize = 65.0; // Base size for medium pads (1.0x)
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: List.generate(
              _viewModel.drumPads.length,
              (index) {
                final pad = _viewModel.drumPads[index];
                final normalizedPos = _padPositions[index];
                final actualPadSize = basePadSize * pad.size;
                final left = normalizedPos.dx * (width - actualPadSize);
                final top = normalizedPos.dy * (height - actualPadSize);

                return Positioned(
                  left: left,
                  top: top,
                  child: _buildDrumPad(
                    pad,
                    isDark,
                    index,
                    actualPadSize,
                  ),
                );
              },
            ),
          );
        },
      );

  /// Single Drum Pad - Circular shape
  Widget _buildDrumPad(DrumPadModel pad, bool isDark, int index, double size) =>
      ValueListenableBuilder<Set<int>>(
        valueListenable: _viewModel.activePadsNotifier,
        builder: (context, activePads, _) {
          final isActive = activePads.contains(index);

          return SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              onTap: () => _viewModel.playDrumSound(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 30),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: pad.color.withOpacity(0.8),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    if (isActive)
                      BoxShadow(
                        color: pad.color.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                transform: isActive
                    ? (Matrix4.identity()..scale(0.9))
                    : Matrix4.identity(),
                child: ClipOval(
                  child: Image.asset(
                    pad.imagePath,
                    fit: BoxFit.cover,
                    opacity: AlwaysStoppedAnimation(
                      isActive ? 1.0 : 0.85,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  /// 🎛️ Expandable Effects Panel
  Widget _buildExpandableEffects(bool isDark) => Card(
        color: isDark ? Colors.grey[800] : Colors.white,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _effectsExpanded = !_effectsExpanded),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(_effectsExpanded ? 0 : 12),
                    bottomRight: Radius.circular(_effectsExpanded ? 0 : 12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🎛️ Effects',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _effectsExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_effectsExpanded)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEffectSlider(
                      label: '🌊 Reverb',
                      valueNotifier: _viewModel.reverbNotifier,
                      onChanged: _viewModel.setReverb,
                    ),
                    const SizedBox(height: 10),
                    _buildEffectSlider(
                      label: '📢 Echo',
                      valueNotifier: _viewModel.echoNotifier,
                      onChanged: _viewModel.setEcho,
                    ),
                    const SizedBox(height: 10),
                    _buildEffectSlider(
                      label: '🔊 Bass Boost',
                      valueNotifier: _viewModel.bassBoostNotifier,
                      onChanged: _viewModel.setBassBoost,
                    ),
                    const SizedBox(height: 10),
                    _buildEffectSlider(
                      label: '🎵 Pitch Shift',
                      valueNotifier: _viewModel.pitchShiftNotifier,
                      onChanged: _viewModel.setPitchShift,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  /// Effect Slider (compact)
  Widget _buildEffectSlider({
    required String label,
    required ValueNotifier<double> valueNotifier,
    required Function(double) onChanged,
    double min = 0,
    double max = 1,
    bool enabled = true,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? Colors.white : Colors.grey,
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: valueNotifier,
                builder: (context, value, _) => Text(
                  min == 0 && max == 1
                      ? '${(value * 100).toStringAsFixed(0)}%'
                      : '${value.toStringAsFixed(2)}x',
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ValueListenableBuilder<double>(
            valueListenable: valueNotifier,
            builder: (context, value, _) => Slider(
              value: value,
              onChanged: enabled ? onChanged : null,
              min: min,
              max: max,
              divisions: 100,
            ),
          ),
        ],
      );

  /// 🎵 Expandable Playback Controls
  Widget _buildExpandablePlayback(bool isDark) => Card(
        color: isDark ? Colors.grey[800] : Colors.white,
        child: Column(
          children: [
            GestureDetector(
              onTap: () =>
                  setState(() => _playbackExpanded = !_playbackExpanded),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(_playbackExpanded ? 0 : 12),
                    bottomRight: Radius.circular(_playbackExpanded ? 0 : 12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🎵 Playback',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _playbackExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_playbackExpanded)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _viewModel.recordStart,
                            icon: const Icon(Icons.mic, size: 16),
                            label: const Text(
                              'Record',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _viewModel.recordStop,
                            icon: const Icon(Icons.stop, size: 16),
                            label: const Text(
                              'Stop',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _viewModel.clearAll,
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text(
                              'Clear',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _viewModel.playRecording,
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text(
                              'Play',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _viewModel.pauseRecording,
                            icon: const Icon(Icons.pause, size: 16),
                            label: const Text(
                              'Pause',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
