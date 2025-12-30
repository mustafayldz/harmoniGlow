// songv2_player_view_neon_v3.dart
//
// ✅ Updates included (per your latest):
// - Full-screen immersive
// - Same look on all phones/tablets (fixed design canvas + FittedBox cover)
// - Removed prev/loop controls
// - Timer + progress start working on FIRST play (via _playerMsN notifier updates)
// - Drops: same WIDTH as old, but LONG tapered tail
// - Lane order (left->right): Crash, Hi-Hat, Snare, Tom1, Kick, Tom2, Floor Tom, Ride
// - Lane paths: straight vertical "road lanes" from top to bottom
// - Lane visuals: ALL WHITE lanes (band + rails), drawn once
// - Labels moved INSIDE circles
// - Background unified (no black bottom)
//
// NOTE: This file assumes your existing imports/models/constants/services exist.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:drumly/constants.dart';
import 'package:drumly/models/songv2_model.dart';
import 'package:drumly/services/songv2_service.dart';

/// ---------------------------------------------------------------------------
/// Small extensions
/// ---------------------------------------------------------------------------
extension ColorX on Color {
  int toARGB32() => value;
  Color withValues({double? alpha}) => alpha == null ? this : withOpacity(alpha);
}

/// ---------------------------------------------------------------------------
/// 1) Drum kit layout (unchanged)
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
/// 2) Lane order (left->right) given by user
/// Crash, Hi-hat, Snare, Tom1, Kick, Tom2, Floor Tom, Ride
///
/// DrumKitLayout indices:
/// Crash=1, HiHat=0, Snare=3, Tom1=4, Kick=7, Tom2=5, FloorTom=6, Ride=2
/// ---------------------------------------------------------------------------
const List<int> kLaneOrderToKitIndex = [1, 0, 3, 4, 7, 5, 6, 2];

/// ---------------------------------------------------------------------------
/// 3) Lane flash controller
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
    for (var i = 0; i < 8; i++) v[i] = 0.0;
    notifyListeners();
  }
}

/// ---------------------------------------------------------------------------
/// Lane Path (Quadratic Bezier helper)
/// We keep quadratic form but for vertical lanes we set p0,p1,p2 collinear.
/// ---------------------------------------------------------------------------
class LanePath {
  const LanePath(this.p0, this.p1, this.p2);
  final Offset p0;
  final Offset p1;
  final Offset p2;

  Offset at(double t) {
    final u = 1.0 - t;
    return Offset(
      (u * u) * p0.dx + 2 * u * t * p1.dx + (t * t) * p2.dx,
      (u * u) * p0.dy + 2 * u * t * p1.dy + (t * t) * p2.dy,
    );
  }
}

/// ---------------------------------------------------------------------------
/// 4) Background + road + grid + WHITE vertical lane "roads"
/// ---------------------------------------------------------------------------
class _NeonStagePainter extends CustomPainter {
  _NeonStagePainter({
    required this.dstRect,
    required this.roadTopY,
    required this.roadBottomY,
    required this.lanePaths,
  });

  final Rect dstRect;
  final double roadTopY;
  final double roadBottomY;
  final List<LanePath> lanePaths;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Full-screen sky gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.0, -0.75),
          radius: 1.25,
          colors: [
            Color(0xFF0B1D49),
            Color(0xFF050816),
            Color(0xFF02030A),
          ],
        ).createShader(rect),
    );

    // Bottom haze so no black band
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000),
            Color(0x1400E5FF),
            Color(0x1800FF99),
            Color(0x22000000),
          ],
          stops: [0.55, 0.78, 0.90, 1.0],
        ).createShader(rect),
    );

    _paintStars(canvas, size);
    _paintCity(canvas, size);

    // Road trapezoid
    final cx = size.width / 2;
    final topW = size.width * 0.52;
    final bottomW = size.width * 1.02;

    final tl = Offset(cx - topW / 2, roadTopY);
    final tr = Offset(cx + topW / 2, roadTopY);
    final bl = Offset(cx - bottomW / 2, roadBottomY);
    final br = Offset(cx + bottomW / 2, roadBottomY);

    final road = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.18),
            Colors.black.withOpacity(0.70),
          ],
        ).createShader(Rect.fromLTRB(0, roadTopY, size.width, roadBottomY)),
    );

    // Grid inside road
    canvas.save();
    canvas.clipPath(road);
    _paintGrid(canvas, tl, tr, bl, br);

    // ✅ WHITE lane "roads" (band + rails)
    for (int lane = 0; lane < 8; lane++) {
      final c = Colors.white;

      final centerPath = Path()
        ..moveTo(lanePaths[lane].p0.dx, lanePaths[lane].p0.dy)
        ..quadraticBezierTo(
          lanePaths[lane].p1.dx,
          lanePaths[lane].p1.dy,
          lanePaths[lane].p2.dx,
          lanePaths[lane].p2.dy,
        );

      final band = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c.withOpacity(0.07);

      final railGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c.withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final railCore = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c.withOpacity(0.22);

      canvas.drawPath(centerPath, band);
      canvas.drawPath(centerPath, railGlow);
      canvas.drawPath(centerPath, railCore);
    }

    canvas.restore();
  }

  void _paintStars(Canvas canvas, Size size) {
    final stars = Paint()..isAntiAlias = true;
    final rnd = math.Random(7);
    final topBand = dstRect.top * 0.9;
    for (int i = 0; i < 120; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * topBand;
      final r = 0.6 + rnd.nextDouble() * 1.8;
      final o = 0.06 + rnd.nextDouble() * 0.18;
      stars.color = Colors.white.withOpacity(o);
      canvas.drawCircle(Offset(x, y), r, stars);
    }
  }

  void _paintCity(Canvas canvas, Size size) {
    final baseY = dstRect.top * 0.98;

    final leftPaint = Paint()..color = const Color(0xFF0B234F).withOpacity(0.95);
    final glowL = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final left = Path()
      ..moveTo(0, baseY)
      ..lineTo(0, baseY - 220)
      ..lineTo(80, baseY - 220)
      ..lineTo(80, baseY - 160)
      ..lineTo(140, baseY - 160)
      ..lineTo(140, baseY - 280)
      ..lineTo(240, baseY - 280)
      ..lineTo(240, baseY - 120)
      ..lineTo(300, baseY - 120)
      ..lineTo(300, baseY)
      ..close();

    canvas.drawPath(left, leftPaint);
    canvas.drawPath(left, glowL);

    final rightPaint = Paint()..color = const Color(0xFF071A3E).withOpacity(0.95);
    final glowR = Paint()
      ..color = const Color(0xFFFF2D55).withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final w = size.width;
    final right = Path()
      ..moveTo(w, baseY)
      ..lineTo(w, baseY - 230)
      ..lineTo(w - 90, baseY - 230)
      ..lineTo(w - 90, baseY - 140)
      ..lineTo(w - 170, baseY - 140)
      ..lineTo(w - 170, baseY - 300)
      ..lineTo(w - 280, baseY - 300)
      ..lineTo(w - 280, baseY - 110)
      ..lineTo(w - 350, baseY - 110)
      ..lineTo(w - 350, baseY)
      ..close();

    canvas.drawPath(right, rightPaint);
    canvas.drawPath(right, glowR);
  }

  void _paintGrid(Canvas canvas, Offset tl, Offset tr, Offset bl, Offset br) {
    final topY = tl.dy;
    final bottomY = bl.dy;

    final gridH = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 1.0;
    final gridV = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 18; i++) {
      final t = i / 18.0;
      final y = topY + (bottomY - topY) * math.pow(t, 1.8).toDouble();
      final k = (y - topY) / (bottomY - topY);
      final lx = _lerp(tl.dx, bl.dx, k);
      final rx = _lerp(tr.dx, br.dx, k);
      canvas.drawLine(Offset(lx, y), Offset(rx, y), gridH);
    }

    for (int i = 0; i <= 12; i++) {
      final t = i / 12.0;
      final xb = _lerp(bl.dx, br.dx, t);
      final xt = _lerp(tl.dx, tr.dx, t);
      canvas.drawLine(Offset(xt, topY), Offset(xb, bottomY), gridV);
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _NeonStagePainter old) => old.dstRect != dstRect ||
        old.roadTopY != roadTopY ||
        old.roadBottomY != roadBottomY ||
        old.lanePaths != lanePaths;
}

/// ---------------------------------------------------------------------------
/// 5) Notes + kit painter
/// - Drops follow lanePaths using lane position (left->right)
/// - Drops color uses KIT index (LED colors)
/// - Labels inside circles
/// - Drop width like old, tail long/tapered
/// ---------------------------------------------------------------------------
class _NotesAndGlowPainter extends CustomPainter {
  _NotesAndGlowPainter({
    required this.song,
    required this.songMs,
    required this.dstRect,
    required this.laneColors,
    required this.flashCtrl,
    required this.noteSprite,
    required this.enableGlow,
    required this.maxNotesPerFrame,
    required this.dynamicLookahead,
    required this.lanePaths,
  }) : super(repaint: Listenable.merge([songMs, flashCtrl])) {
    _atlasPaint
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = true;
  }

  final SongV2Model song;
  final ValueListenable<int> songMs;

  final Rect dstRect;
  final List<Color> laneColors; // indexed by KIT index 0..7
  final LaneFlashController flashCtrl;
  final ui.Image? noteSprite;

  final bool enableGlow;
  final int maxNotesPerFrame;
  final int dynamicLookahead;

  final List<LanePath> lanePaths; // indexed by LANE POS 0..7 (left->right order)

  static const int pastMs = 160;
  static const int hitTightMs = 18;

  static Float32List? _rst;
  static Float32List? _rects;
  static Int32List? _colors;
  static int _cap = 0;
  static double _lastSpriteW = 0.0;
  static double _lastSpriteH = 0.0;

  static ui.Picture? _baseKitPicture;
  static double _baseW = 0.0;
  static double _baseH = 0.0;
  static double _baseL = 0.0;
  static double _baseT = 0.0;
  static int _baseColorHash = 0;

  static List<TextPainter>? _labelPainters;
  static double _lastDstW = 0.0;

  final Paint _atlasPaint = Paint();
  final Paint _outlinePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _hitOvalPaint = Paint()..style = PaintingStyle.stroke;

  static int _packColor(Color c, double opacity) {
    final oa = (opacity * 255.0).round().clamp(0, 255);
    final argb = c.toARGB32();
    final ca = (argb >> 24) & 0xff;
    final na = (ca * oa) ~/ 255;
    return (argb & 0x00FFFFFF) | (na << 24);
  }

  Offset _anchorToScreen(int kitIndex) {
    final a = DrumKitLayout.anchor[kitIndex]!;
    return Offset(
      dstRect.left + a.x * dstRect.width,
      dstRect.top + a.y * dstRect.height,
    );
  }

  double _anchorRadiusPx(int kitIndex) => DrumKitLayout.anchor[kitIndex]!.r * dstRect.width;

  int _laneColorsHash() {
    int h = 17;
    for (final c in laneColors) h = 37 * h + c.toARGB32();
    return h;
  }

  int _kitIndexToLanePos(int kitIndex) {
    for (int i = 0; i < 8; i++) {
      if (kLaneOrderToKitIndex[i] == kitIndex) return i;
    }
    return kitIndex.clamp(0, 7);
  }

  void _ensureLabelCache() {
    final needRebuild =
        _labelPainters == null || (_lastDstW - dstRect.width).abs() > 0.1;
    if (!needRebuild) return;

    _lastDstW = dstRect.width;

    _labelPainters = List.generate(8, (kitIndex) {
      final r = _anchorRadiusPx(kitIndex);
      final label = DrumKitLayout.labels[kitIndex] ?? '';
      final fontSize = (r * 0.34).clamp(10.0, 18.0);

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.85),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );
      tp.layout(maxWidth: r * 1.6);
      return tp;
    });
  }

  void _ensureBaseKitPicture() {
    _ensureLabelCache();

    final w = dstRect.width;
    final h = dstRect.height;
    final l = dstRect.left;
    final t = dstRect.top;
    final colorHash = _laneColorsHash();

    final need = _baseKitPicture == null ||
        (_baseW - w).abs() > 0.1 ||
        (_baseH - h).abs() > 0.1 ||
        (_baseL - l).abs() > 0.1 ||
        (_baseT - t).abs() > 0.1 ||
        _baseColorHash != colorHash;

    if (!need) return;

    _baseW = w;
    _baseH = h;
    _baseL = l;
    _baseT = t;
    _baseColorHash = colorHash;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    for (int kitIndex = 0; kitIndex < 8; kitIndex++) {
      final c = laneColors[kitIndex];
      final center = _anchorToScreen(kitIndex);
      final r = _anchorRadiusPx(kitIndex);

      _outlinePaint
        ..strokeWidth = 5.0
        ..color = Colors.black.withOpacity(0.65);
      canvas.drawCircle(center, r, _outlinePaint);

      _ringPaint
        ..strokeWidth = 3.0
        ..color = c.withOpacity(0.78);
      canvas.drawCircle(center, r, _ringPaint);

      _fillPaint.color = c.withOpacity(0.16);
      canvas.drawCircle(center, r, _fillPaint);

      final tp = _labelPainters![kitIndex];
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }

    _baseKitPicture?.dispose();
    _baseKitPicture = recorder.endRecording();
  }

  void _ensureAtlasBuffers(double spriteW, double spriteH) {
    if (_rst == null || _cap < maxNotesPerFrame) {
      _cap = maxNotesPerFrame;
      _rst = Float32List(_cap * 4);
      _rects = Float32List(_cap * 4);
      _colors = Int32List(_cap);
      _lastSpriteW = 0.0;
      _lastSpriteH = 0.0;
    }

    if (_lastSpriteW != spriteW || _lastSpriteH != spriteH) {
      _lastSpriteW = spriteW;
      _lastSpriteH = spriteH;
      for (int i = 0; i < _cap; i++) {
        final b = i * 4;
        _rects![b + 0] = 0.0;
        _rects![b + 1] = 0.0;
        _rects![b + 2] = spriteW;
        _rects![b + 3] = spriteH;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final tNow = songMs.value;
    final lookahead = dynamicLookahead;

    _ensureBaseKitPicture();
    if (_baseKitPicture != null) canvas.drawPicture(_baseKitPicture!);

    if (noteSprite != null) {
      _drawNotesRawAtlas(canvas, tNow, lookahead);
    } else {
      _drawNotesFallback(canvas, tNow, lookahead);
    }

    if (enableGlow) _paintHitGlows(canvas);
  }

  void _paintHitGlows(Canvas canvas) {
    for (int kitIndex = 0; kitIndex < 8; kitIndex++) {
      final intensity = (flashCtrl.v[kitIndex] / 180.0).clamp(0.0, 1.0);
      if (intensity <= 0.01) continue;

      final c = laneColors[kitIndex];
      final center = _anchorToScreen(kitIndex);
      final r = _anchorRadiusPx(kitIndex);

      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          r * (1.25 + 0.40 * intensity),
          [
            c.withOpacity(0.0),
            c.withOpacity(0.55 * intensity),
            c.withOpacity(0.0),
          ],
          const [0.0, 0.55, 1.0],
        );

      canvas.drawCircle(center, r * (1.25 + 0.40 * intensity), glowPaint);

      final oval =
          Rect.fromCenter(center: center, width: r * 2.25, height: r * 1.75);
      _hitOvalPaint
        ..strokeWidth = 2.4
        ..color = c.withOpacity(0.85 * intensity);

      canvas.drawOval(oval, _hitOvalPaint);
    }
  }

  void _drawNotesRawAtlas(Canvas canvas, int tNow, int lookahead) {
    final spriteW = noteSprite!.width.toDouble();
    final spriteH = noteSprite!.height.toDouble();
    _ensureAtlasBuffers(spriteW, spriteH);

    // sprite anchor near head (bottom-ish)
    final spriteCx = spriteW * 0.5;
    final spriteCy = spriteH * 0.82;

    final start = tNow - pastMs;
    final end = tNow + lookahead;

    int idx = _lowerBoundAbsT(song.absT, start);
    idx = math.max(0, idx - 16);

    // ✅ width like old
    final noteR = dstRect.width * 0.020;
    final scale = noteR / 16.0;

    int w = 0;

    for (int i = idx; i < song.absT.length && w < maxNotesPerFrame; i++) {
      final t = song.absT[i];
      if (t > end) break;

      final timeToHit = t - tNow;
      final timeSinceHit = tNow - t;
      if (timeSinceHit > pastMs) continue;
      if (timeToHit < 0) continue;

      final alphaRaw = (t - tNow) / lookahead;
      final alpha = alphaRaw.clamp(-pastMs / lookahead, 1.1);
      final progress = (1.0 - alpha).clamp(0.0, 1.0);

      final mask = song.m[i];

      for (int kitIndex = 0; kitIndex < 8; kitIndex++) {
        if ((mask & (1 << kitIndex)) == 0) continue;
        if (w >= maxNotesPerFrame) break;

        // ✅ map kitIndex -> lanePos (left->right order)
        final lanePos = _kitIndexToLanePos(kitIndex);
        final p = lanePaths[lanePos].at(progress);

        double opacity;
        if (timeToHit >= 0) {
          opacity = 1.0;
        } else {
          opacity = (1.0 - (timeSinceHit / pastMs)).clamp(0.0, 1.0);
        }

        final isHit = (t - tNow).abs() <= hitTightMs;
        final c = isHit ? const Color(0xFF10B981) : laneColors[kitIndex];

        final b = w * 4;
        _rst![b + 0] = scale;
        _rst![b + 1] = 0.0;
        _rst![b + 2] = p.dx - spriteCx * scale;
        _rst![b + 3] = p.dy - spriteCy * scale;

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
    }

    if (w == 0) return;

    canvas.drawRawAtlas(
      noteSprite!,
      _rst!,
      _rects!,
      _colors,
      BlendMode.modulate,
      null,
      _atlasPaint,
    );
  }

  void _drawNotesFallback(Canvas canvas, int tNow, int lookahead) {
    final start = tNow - pastMs;
    final end = tNow + lookahead;

    int idx = _lowerBoundAbsT(song.absT, start);
    idx = math.max(0, idx - 16);

    final noteR = dstRect.width * 0.020; // ✅ width like old
    final paint = Paint()..isAntiAlias = true;

    for (int i = idx; i < song.absT.length; i++) {
      final t = song.absT[i];
      if (t > end) break;

      final timeToHit = t - tNow;
      final timeSinceHit = tNow - t;
      if (timeSinceHit > pastMs) continue;
      // ✅ hit anında kaybolsun
      if (timeToHit < 0) continue;

      final alphaRaw = (t - tNow) / lookahead;
      final alpha = alphaRaw.clamp(-pastMs / lookahead, 1.1);
      final progress = (1.0 - alpha).clamp(0.0, 1.0);

      final mask = song.m[i];

      for (int kitIndex = 0; kitIndex < 8; kitIndex++) {
        if ((mask & (1 << kitIndex)) == 0) continue;

        final lanePos = _kitIndexToLanePos(kitIndex);
        final p = lanePaths[lanePos].at(progress);

        double opacity;
        if (timeToHit >= 0) {
          opacity = 1.0;
        } else {
          opacity = (1.0 - (timeSinceHit / pastMs)).clamp(0.0, 1.0);
        }

        final isHit = (t - tNow).abs() <= hitTightMs;
        final c = isHit ? const Color(0xFF10B981) : laneColors[kitIndex];

        paint.color = c.withOpacity(opacity);
        canvas.drawCircle(p, noteR, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NotesAndGlowPainter old) =>
      old.song != song ||
      old.dstRect != dstRect ||
      old.noteSprite != noteSprite ||
      old.enableGlow != enableGlow ||
      old.maxNotesPerFrame != maxNotesPerFrame ||
      old.dynamicLookahead != dynamicLookahead ||
      old.lanePaths != lanePaths ||
      !identical(old.laneColors, laneColors) ||
      old.flashCtrl != flashCtrl ||
      old.songMs != songMs;
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
/// 6) Main View
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

class _DrumSendInfo {
  const _DrumSendInfo(this.led, this.rgb);
  final int led;
  final List<int> rgb; // length 3
}

class _SongV2PlayerViewState extends State<SongV2PlayerView>
    with SingleTickerProviderStateMixin {
  // Fixed design canvas for “same look everywhere”
  static const double _designW = 390;
  static const double _designH = 844;

  bool _isPlaying = false;

  double _speed = 1.0;
  bool _showSpeedSlider = false;
  Timer? _speedSliderTimer;

  SongV2Model? _song;
  bool _isLoading = true;
  String? _error;

  late final Ticker _ticker;
  Duration? _lastElapsed;

  double _playerMs = 0.0;

  // ✅ used by UI always
  late final ValueNotifier<int> _playerMsN = ValueNotifier<int>(0);
  late final ValueNotifier<int> _songMsN = ValueNotifier<int>(0);

  YoutubePlayerController? _ytController;
  bool _ytReady = false;
  double _ytPollAccumMs = 0.0;

  late final LaneFlashController _flashCtrl = LaneFlashController();
  late final List<Color> _laneColors; // KIT index colors 0..7

  static const double kDrumAspect = 1.7777777778;

  int _hitCursor = 0;

  ui.Image? _noteSprite;

  int _dynamicLookahead = 2000;
  bool _enableGlow = true;
  int _maxNotesPerFrame = 900;
  int _overBudget = 0;

  final SongV2Service _service = SongV2Service();

  // Bluetooth
  final Set<int> _sentNoteIndices = {};
  BluetoothBloc? _bluetoothBloc;

  final List<_DrumSendInfo?> _drumSendCache =
      List<_DrumSendInfo?>.filled(8, null);
  Future<void> _btSendChain = Future.value();

  @override
  void initState() {
    super.initState();

    // Full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),);

    _bluetoothBloc = context.read<BluetoothBloc>();
    _ticker = createTicker(_onTick);

    _laneColors = List<Color>.generate(8, (i) => _getLedColor(i));
    _warmupDrumCache();
    _loadAll();
  }

  @override
  void dispose() {
    _speedSliderTimer?.cancel();
    _ticker.dispose();
    _ytController?.dispose();
    _flashCtrl.dispose();
    _songMsN.dispose();
    _playerMsN.dispose();
    _noteSprite?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _warmupDrumCache() {
    unawaited(() async {
      for (int lane = 0; lane < 8; lane++) {
        final drumPart = (lane + 1).toString();
        final drum = await StorageService.getDrumPart(drumPart);
        if (drum != null &&
            drum.led != null &&
            drum.rgb != null &&
            drum.rgb!.length == 3) {
          _drumSendCache[lane] =
              _DrumSendInfo(drum.led!, List<int>.from(drum.rgb!));
        }
      }
    }());
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

      // ✅ tapered tail sprite (narrow width, long height)
      _noteSprite = await _createNoteSpriteWaterDropTapered();

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
            if (ready && !_ytReady) setState(() => _ytReady = true);
          });

        _ytController!.setPlaybackRate(_nearestPlaybackRate(_speed));
      }

      // ✅ ensure timer/progress show correct initial state
      _playerMsN.value = _playerMs.round();
      _songMsN.value = (_playerMs - s.syncMs).round();

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

    // perf adapt
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
      if (_dynamicLookahead < _song!.lookaheadMs) {
        _dynamicLookahead =
            math.min(_dynamicLookahead + 50, _song!.lookaheadMs);
      }
      _maxNotesPerFrame = math.min(_maxNotesPerFrame + 40, 900);
    }

    // youtube sync only at 1.0 speed
    if (_ytController != null && _ytReady && _speed == 1.0) {
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

    if (_playerMs < 0) _playerMs = 0;

    final songMs = (_playerMs - _song!.syncMs).round();

    _updateLaneHitsCursor(songMs);
    _flashCtrl.decay(dtMs);

    if (_playerMs >= _song!.durationMs) {
      _playerMs = _song!.durationMs.toDouble();
      _isPlaying = false;
      _lastElapsed = null;
      _ticker.stop();
      if (_ytController != null && _ytReady) _ytController!.pause();
    }

    // ✅ Always update timer/progress notifiers
    _playerMsN.value = _playerMs.round();
    _songMsN.value = songMs;
  }

  void _queueBluetoothSend(List<int> bytes) {
    final bloc = _bluetoothBloc;
    if (bloc == null || bloc.characteristic == null) return;

    _btSendChain = _btSendChain.then((_) async {
      final b = _bluetoothBloc;
      if (b == null || b.characteristic == null) return;
      await SendData().sendHexData(b, bytes);
    });
  }

  void _sendBluetoothSignals(int noteIndex, int laneMask) {
    final bloc = _bluetoothBloc;
    if (bloc == null || bloc.characteristic == null) return;
    if (_sentNoteIndices.contains(noteIndex)) return;

    _sentNoteIndices.add(noteIndex);

    final data = <int>[];
    for (int lane = 0; lane < 8; lane++) {
      if ((laneMask & (1 << lane)) == 0) continue;

      final info = _drumSendCache[lane];
      if (info == null) continue;

      data.add(info.led);
      data.addAll(info.rgb);
    }

    if (data.isNotEmpty) _queueBluetoothSend(data);
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

        _sendBluetoothSignals(i, mask);

        for (int lane = 0; lane < 8; lane++) {
          if ((mask & (1 << lane)) != 0) {
            _flashCtrl.flashLane(lane, 180.0);
          }
        }
      }
    }
  }

  Future<void> _togglePlay() async {
    final s = _song;
    if (s == null) return;

    if (!_isPlaying) {
      if (_playerMs >= s.durationMs) {
        _playerMs = 0.0;
        _hitCursor = 0;
        _flashCtrl.reset();
        _sentNoteIndices.clear();
        _playerMsN.value = 0;
        _songMsN.value = (-s.syncMs).round();
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Countdown(),
      );

      setState(() => _isPlaying = true);
      _lastElapsed = Duration.zero;
      _ticker.start();

      if (_ytController != null && _ytReady && _speed == 1.0) {
        _ytController!.seekTo(Duration(milliseconds: _playerMs.round()));
        _ytController!.play();
      }
    } else {
      setState(() => _isPlaying = false);
      _lastElapsed = null;
      _ticker.stop();
      if (_ytController != null && _ytReady) _ytController!.pause();
    }
  }

  void _onSpeedChanged(double v) {
    final rate = _nearestPlaybackRate(v);
    final isNormalSpeed = rate == 1.0;

    setState(() => _speed = rate);

    _speedSliderTimer?.cancel();
    _speedSliderTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSpeedSlider = false);
    });

    if (_ytController != null && _ytReady) {
      if (isNormalSpeed) {
        _ytController!.seekTo(Duration(milliseconds: _playerMs.round()));
        _ytController!.setPlaybackRate(1.0);
        if (_isPlaying) _ytController!.play();
      } else {
        _ytController!.pause();
      }
    }
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

  String _fmtMs(int ms) {
    final s = (ms / 1000).floor();
    final m = (s ~/ 60).toString();
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _designW,
            height: _designH,
            child: _buildDesignCanvas(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignCanvas(BuildContext context) {
    final s = _song!;
    final size = const Size(_designW, _designH);

    final dstRect = computeDrumRect(
      screen: size,
      safe: EdgeInsets.zero,
      aspect: kDrumAspect,
    );

    // Controls are intentionally lower for notch/camera safety (in design space)
    const topY = 54.0;
    const progressY = 108.0;
    const speedY = 130.0;

    // Road geometry
    final roadTopY = progressY + 62.0;
    final roadBottomY = dstRect.top + dstRect.height * 0.10;

    // Vertical lanes (left->right order)
    final lanePaths = _computePerspectiveLanePaths(
  size: size,
  dstRect: dstRect,
  roadTopY: roadTopY,
);


    return Stack(
      children: [
        CustomPaint(
          painter: _NeonStagePainter(
            dstRect: dstRect,
            roadTopY: roadTopY,
            roadBottomY: roadBottomY,
            lanePaths: lanePaths,
          ),
          child: const SizedBox.expand(),
        ),

        RepaintBoundary(
          child: CustomPaint(
            painter: _NotesAndGlowPainter(
              song: s,
              songMs: _songMsN,
              dstRect: dstRect,
              laneColors: _laneColors,
              flashCtrl: _flashCtrl,
              noteSprite: _noteSprite,
              enableGlow: _enableGlow,
              maxNotesPerFrame: _maxNotesPerFrame,
              dynamicLookahead: _dynamicLookahead,
              lanePaths: lanePaths,
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
                onReady: () {
                  if (!_ytReady) setState(() => _ytReady = true);
                },
              ),
            ),
          ),

        // Back
        Positioned(
          top: topY,
          left: 12,
          child: _PillIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ),

        // Play
        Positioned(
          top: topY,
          left: 70,
          child: _PillIconButton(
            icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: _togglePlay,
          ),
        ),

        // Timer
        Positioned(
          top: topY,
          right: 12,
          child: ValueListenableBuilder<int>(
            valueListenable: _playerMsN,
            builder: (_, ms, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '${_fmtMs(ms)} / ${_fmtMs(s.durationMs)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ),
        ),

        // Progress
        Positioned(
          top: progressY,
          left: 12,
          right: 12,
          child: ValueListenableBuilder<int>(
            valueListenable: _playerMsN,
            builder: (_, ms, __) {
              final progress = (ms / s.durationMs).clamp(0.0, 1.0).toDouble();
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.yellowAccent.withOpacity(0.9),
                  ),
                ),
              );
            },
          ),
        ),

        // Speed chip/slider
        Positioned(
          top: speedY,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                _speedSliderTimer?.cancel();
                setState(() => _showSpeedSlider = !_showSpeedSlider);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                width: _showSpeedSlider ? 320 : 90,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24),
                ),
                child: _showSpeedSlider
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Speed',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '${_speed.toStringAsFixed(2)}x',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ Vertical lanes from top to bottom, left->right order fixed.
  List<LanePath> _computePerspectiveLanePaths({
  required Size size,
  required Rect dstRect,
  required double roadTopY,
}) {
  double lerp(double a, double b, double t) => a + (b - a) * t;

  Offset anchorOfKit(int kitIndex) {
    final a = DrumKitLayout.anchor[kitIndex]!;
    return Offset(
      dstRect.left + a.x * dstRect.width,
      dstRect.top + a.y * dstRect.height,
    );
  }

  // ✅ Yukarıda dar bir spawn band
  final topY = roadTopY + 8.0;
  final cx = size.width * 0.5;
  final topW = size.width * 0.36; // dar alan (görseldeki gibi)
  final topLeft = cx - topW / 2;
  final topRight = cx + topW / 2;

  final paths = <LanePath>[];

  // lanePos: 0..7 soldan sağa
  for (int lanePos = 0; lanePos < 8; lanePos++) {
    final kitIndex = kLaneOrderToKitIndex[lanePos];
    final t = lanePos / 7.0;

    // üstte dar band içinden çıkış
    final x0 = lerp(topLeft, topRight, t);

    // altta hedef = drum merkezleri
    final hit = anchorOfKit(kitIndex);

    final p0 = Offset(x0, topY);
    final p2 = Offset(hit.dx, hit.dy); // ✅ circle center (burada yok olacak)

    // hafif perspektif eğrisi
    final midY = lerp(p0.dy, p2.dy, 0.55);
    final midX = lerp(x0, p2.dx, 0.70);
    final p1 = Offset(midX, midY);

    paths.add(LanePath(p0, p1, p2));
  }

  return paths;
}

}

/// Button
class _PillIconButton extends StatelessWidget {
  const _PillIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 46,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  color: Colors.black.withOpacity(0.25),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      );
}

/// Helpers
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

/// ✅ Narrow width, LONG tapered tail
Future<ui.Image> _createNoteSpriteWaterDropTapered() async {
  const w = 48;
  const h = 160;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
  );

  final cx = w * 0.5;
  final headCy = h * 0.84;

  // Tail: very thin at top, thicker near head
  final tailTopY = 6.0;
  final tailBottomY = headCy - 18.0;

  const topHalf = 1.8;
  const bottomHalf = 7.5;

  final tail = Path()
    ..moveTo(cx - topHalf, tailTopY)
    ..quadraticBezierTo(
      cx - bottomHalf,
      (tailTopY + tailBottomY) * 0.55,
      cx - bottomHalf,
      tailBottomY,
    )
    ..lineTo(cx + bottomHalf, tailBottomY)
    ..quadraticBezierTo(
      cx + bottomHalf,
      (tailTopY + tailBottomY) * 0.55,
      cx + topHalf,
      tailTopY,
    )
    ..close();

  final tailPaint = Paint()
    ..isAntiAlias = true
    ..shader = ui.Gradient.linear(
      Offset(cx, tailTopY),
      Offset(cx, tailBottomY),
      [
        Colors.white.withOpacity(0.00),
        Colors.white.withOpacity(0.10),
        Colors.white.withOpacity(0.45),
      ],
      const [0.0, 0.55, 1.0],
    );

  canvas.drawPath(tail, tailPaint);

  // Head (drop)
  final s = 16.0;
  final head = Path()
    ..moveTo(cx, headCy - s * 1.05)
    ..cubicTo(
      cx + s * 1.10,
      headCy - s * 0.65,
      cx + s * 1.20,
      headCy + s * 0.20,
      cx,
      headCy + s * 1.10,
    )
    ..cubicTo(
      cx - s * 1.20,
      headCy + s * 0.20,
      cx - s * 1.10,
      headCy - s * 0.65,
      cx,
      headCy - s * 1.05,
    )
    ..close();

  canvas.drawPath(
    head,
    Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withOpacity(0.95),
  );

  // highlight
  canvas.drawCircle(
    Offset(cx - 4.5, headCy - 6.0),
    3.8,
    Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withOpacity(0.22),
  );

  final pic = recorder.endRecording();
  final img = await pic.toImage(w, h);
  pic.dispose();
  return img;
}
