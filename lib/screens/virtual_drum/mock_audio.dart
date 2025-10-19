/// Alternative Virtual Drum Implementation without flutter_soloud
/// This uses waveform generation for audio instead of loading asset files

import 'dart:math';
import 'package:flutter/material.dart';

class SimpleDrumPadModel {
  final String name;
  final String emoji;
  final Color color;
  final String key;
  final double frequency; // Hz - for sound generation

  SimpleDrumPadModel({
    required this.name,
    required this.emoji,
    required this.color,
    required this.key,
    required this.frequency,
  });
}

class MockAudioProvider {
  /// Generate a mock audio signal based on frequency
  /// This can be used when flutter_soloud native binding fails
  List<double> generateDrumSound(double frequency, {int durationMs = 200}) {
    const int sampleRate = 44100;
    final int samples = (sampleRate * durationMs / 1000).toInt();
    final List<double> audioData = [];

    for (int i = 0; i < samples; i++) {
      final double t = i / sampleRate;
      // Exponential decay for drum-like sound
      final double decay = exp(-3 * t);
      // Sine wave with frequency
      final double sample = decay * sin(2 * pi * frequency * t);
      audioData.add(sample);
    }

    return audioData;
  }

  /// Get waveform data from generated sound
  List<double> getWaveformData(double frequency, {int points = 100}) {
    final List<double> waveform = [];

    for (int i = 0; i < points; i++) {
      final double phase = (i / points) * (2 * pi);
      final double sample = sin(phase);
      waveform.add(sample);
    }

    return waveform;
  }
}

/// If you need this, use frequencies:
/// Kick: 60-80 Hz
/// Snare: 200-300 Hz
/// Hi-Hat Close: 8000-12000 Hz
/// Hi-Hat Open: 10000-15000 Hz
/// Tom: 300-500 Hz (various tones)
/// Crash: 4000-8000 Hz
/// Ride: 5000-9000 Hz

// Example usage in VirtualDrumViewModel:
/*
final MockAudioProvider _mockAudio = MockAudioProvider();

// When flutter_soloud fails:
final waveformData = _mockAudio.generateDrumSound(200); // Snare-like sound

// For visualization:
final waveform = _mockAudio.getWaveformData(200);
waveformNotifier.value = waveform;
*/
