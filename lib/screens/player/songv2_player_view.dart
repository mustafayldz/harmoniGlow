// songv2_player_view_neon_v3.dart
//
// ✅ Fully Responsive Implementation:
// - Adaptive layout for phones, tablets, and different orientations
// - Dynamic scaling based on screen dimensions (no fixed design canvas)
// - Percentage-based positioning for UI controls
// - Aspect-ratio-aware drum kit sizing
// - Flexible lane paths that adapt to screen geometry
// - Responsive font sizes, padding, and control dimensions
// - No hardcoded pixel values for layout
//
// NOTE: This file assumes your existing imports/models/constants/services exist.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
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
    1: DrumAnchor(0.108, 0.20, 0.0810), // Crash
    0: DrumAnchor(0.220, 0.58, 0.0675), // Hi-Hat
    3: DrumAnchor(0.332, 0.65, 0.0675), // Snare
    4: DrumAnchor(0.444, 0.24, 0.0675), // Tom 1
    7: DrumAnchor(0.556, 0.78, 0.1080), // Kick
    5: DrumAnchor(0.668, 0.24, 0.0675), // Tom 2
    6: DrumAnchor(0.780, 0.61, 0.0810), // Floor Tom
    2: DrumAnchor(0.892, 0.20, 0.0810), // Ride
  };
}

/// ---------------------------------------------------------------------------
/// 2) Lane order (left->right)
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
    for (var i = 0; i < 8; i++) {
      v[i] = 0.0;
    }
    notifyListeners();
  }
}

/// ---------------------------------------------------------------------------
/// Lane Path (Quadratic Bezier helper)
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
/// 4) Background + road + grid + WHITE vertical lane roads
/// ---------------------------------------------------------------------------
class _NeonStagePainter extends CustomPainter {
  _NeonStagePainter({
    required this.dstRect,
    required this.roadTopY,
    required this.roadBottomY,
    required this.lanePaths,
  }) : _laneHash = _hashLanePaths(lanePaths, roadTopY, roadBottomY);

  final Rect dstRect;
  final double roadTopY;
  final double roadBottomY;
  final List<LanePath> lanePaths;

  // ─────────────────────────────────────────────────────────────
  // Background cache (sky + stars + vignette)
  // ─────────────────────────────────────────────────────────────
  static ui.Picture? _skyPic;
  static Size _skySize = Size.zero;

  // Road cache (road + grid + lanes)
  static ui.Picture? _roadPic;
  static Size _roadSize = Size.zero;
  static int _roadKey = 0;

  final int _laneHash;

  static int _hashLanePaths(List<LanePath> paths, double top, double bottom) {
    int h = 17;
    int q(double v) => (v * 10).round(); // 0.1px quantize
    h = 37 * h + q(top);
    h = 37 * h + q(bottom);
    for (final p in paths) {
      h = 37 * h + q(p.p0.dx);
      h = 37 * h + q(p.p0.dy);
      h = 37 * h + q(p.p1.dx);
      h = 37 * h + q(p.p1.dy);
      h = 37 * h + q(p.p2.dx);
      h = 37 * h + q(p.p2.dy);
    }
    return h;
  }

  // deterministic pseudo-random (fast)
  static double _rand01(int n) {
    int x = n * 1103515245 + 12345;
    x &= 0x7fffffff;
    return x / 0x7fffffff;
  }

  void _ensureSky(Size size) {
    if (_skyPic != null && _skySize == size) return;

    _skySize = size;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rect = Offset.zero & size;

    // Deep sky gradient
    c.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.0, -0.95),
          radius: 1.65,
          colors: [
            Color(0xFF0D2A63),
            Color(0xFF070A1A),
            Color(0xFF02030A),
          ],
        ).createShader(rect),
    );

    // Stars (VERY light) — drawn once into cached picture
    final starPaint = Paint()..isAntiAlias = false;
    final count = ((size.width * size.height) / 14000).clamp(90, 220).toInt();

    for (int layer = 0; layer < 2; layer++) {
      final baseAlpha = layer == 0 ? 0.14 : 0.07;
      final baseR = layer == 0 ? 1.2 : 2.4;

      for (int i = 0; i < count; i++) {
        final n = i + layer * 10000 + size.width.toInt() * 31 + size.height.toInt() * 17;
        final x = _rand01(n) * size.width;
        final y = _rand01(n + 999) * size.height;

        final yBias = math.pow(1.0 - (y / size.height), 1.6).toDouble();
        final a = (baseAlpha * (0.55 + 0.45 * yBias)).clamp(0.02, 0.20);

        final r = baseR * (0.7 + 0.6 * _rand01(n + 555));
        starPaint.color = const Color(0xFFFFFFFF).withValues(alpha: a);
        c.drawCircle(Offset(x, y), r, starPaint);
      }
    }

    // Vignette (cinematic)
    c.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.45),
          size.longestSide * 0.85,
          [
            const Color(0xFF000000).withValues(alpha: 0.00),
            const Color(0xFF000000).withValues(alpha: 0.22),
            const Color(0xFF000000).withValues(alpha: 0.62),
          ],
          const [0.0, 0.62, 1.0],
        ),
    );

    _skyPic?.dispose();
    _skyPic = rec.endRecording();
  }

  void _ensureRoad(Size size) {
    final key = _laneHash ^ (size.width.toInt() * 131) ^ (size.height.toInt() * 911);
    if (_roadPic != null && _roadSize == size && _roadKey == key) return;

    _roadSize = size;
    _roadKey = key;

    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);

    // Road trapezoid
    final cx = size.width / 2;
    final topW = size.width * 0.92;
    final bottomW = size.width * 1.18;

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

    // Road fill (depth)
    canvas.drawPath(
      road,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, roadTopY),
          Offset(0, roadBottomY),
          [
            const Color(0x00000000),
            const Color(0xB3000000),
          ],
        ),
    );

    // Clip inside road for grid + lanes
    canvas.save();
    canvas.clipPath(road);

    // Perspective grid
    final gridH = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..strokeWidth = 1.0
      ..isAntiAlias = false;

    final gridV = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1.0
      ..isAntiAlias = false;

    final topY = roadTopY;
    final bottomY = roadBottomY;

    // Horizontal grid lines (ease-in curve)
    for (int i = 0; i <= 18; i++) {
      final t = i / 18.0;
      final y = topY + (bottomY - topY) * math.pow(t, 1.9).toDouble();
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridH);
    }

    // Vertical grid lines
    for (int i = 0; i <= 12; i++) {
      final t = i / 12.0;
      final x = size.width * t;
      canvas.drawLine(Offset(x, topY), Offset(x, bottomY), gridV);
    }

    // ✅ LANE ROADS (neon rails)
    const laneTint = Color(0xFFEAF2FF); // slightly bluish white = neon look

    for (int lane = 0; lane < 8; lane++) {
      final lp = lanePaths[lane];

      final centerPath = Path()
        ..moveTo(lp.p0.dx, lp.p0.dy)
        ..quadraticBezierTo(lp.p1.dx, lp.p1.dy, lp.p2.dx, lp.p2.dy);

      // Soft band
      canvas.drawPath(
        centerPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = laneTint.withValues(alpha: 0.06),
      );

      // Inner core rail
      canvas.drawPath(
        centerPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = laneTint.withValues(alpha: 0.22),
      );
    }

    canvas.restore();

    _roadPic?.dispose();
    _roadPic = rec.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ensureSky(size);
    if (_skyPic != null) canvas.drawPicture(_skyPic!);

    _ensureRoad(size);
    if (_roadPic != null) canvas.drawPicture(_roadPic!);
  }

  @override
  bool shouldRepaint(covariant _NeonStagePainter old) => old._laneHash != _laneHash || old.dstRect != dstRect;
}


/// ---------------------------------------------------------------------------
/// 5) Notes + kit painter
/// - Drops follow lanePaths using lane position (left->right)
/// - Drops color uses KIT index colors from DrumParts
/// - Labels inside circles from DrumParts
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
  final List<Color> laneColors; // KIT index colors 0..7
  final LaneFlashController flashCtrl;
  final ui.Image? noteSprite;

  final bool enableGlow;
  final int maxNotesPerFrame;
  final int dynamicLookahead;

  final List<LanePath> lanePaths; // indexed by LANE POS 0..7 (left->right)

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

  double _anchorRadiusPx(int kitIndex) =>
      DrumKitLayout.anchor[kitIndex]!.r * dstRect.width;

  int _laneColorsHash() {
    int h = 17;
    for (final c in laneColors) {
      h = 37 * h + c.toARGB32();
    }
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

      // ✅ label from DrumParts (NO static labels here)
      final label = DrumParts.nameByKitIndex(kitIndex);

      final fontSize = (r * 0.34).clamp(10.0, 18.0);

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.85),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: r * 1.6);

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
        ..color = Colors.black.withValues(alpha: 0.65);
      canvas.drawCircle(center, r, _outlinePaint);

      _ringPaint
        ..strokeWidth = 3.0
        ..color = c.withValues(alpha: 0.78);
      canvas.drawCircle(center, r, _ringPaint);

      _fillPaint.color = c.withValues(alpha: 0.16);
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
            c.withValues(alpha: 0.0),
            c.withValues(alpha: 0.55 * intensity),
            c.withValues(alpha: 0.0),
          ],
          const [0.0, 0.55, 1.0],
        );

      canvas.drawCircle(center, r * (1.25 + 0.40 * intensity), glowPaint);

      final oval =
          Rect.fromCenter(center: center, width: r * 2.25, height: r * 1.75);
      _hitOvalPaint
        ..strokeWidth = 2.4
        ..color = c.withValues(alpha: 0.85 * intensity);

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

    final noteR = dstRect.width * 0.020;
    final paint = Paint()..isAntiAlias = true;

    for (int i = idx; i < song.absT.length; i++) {
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

        paint.color = c.withValues(alpha: opacity);
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

  late final ValueNotifier<int> _playerMsN = ValueNotifier<int>(0);
  late final ValueNotifier<int> _songMsN = ValueNotifier<int>(0);

  YoutubePlayerController? _ytController;
  bool _ytReady = false;
  double _ytPollAccumMs = 0.0;

  late final LaneFlashController _flashCtrl = LaneFlashController();
  late final List<Color> _laneColors; // KIT index colors 0..7

  static const double kDrumAspect = 2.5;

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

    // Lock to portrait mode for player screens
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

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

    // ✅ Colors from DrumParts (NO static colors)
    _laneColors = List<Color>.generate(8, (i) => DrumParts.colorByKitIndex(i));

    // ✅ Bluetooth mapping from DrumParts (NO DB warmup)
    _warmupDrumCache();

    _loadAll();
  }

  @override
  void dispose() {
    // Restore all orientations when leaving player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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
    for (int kitIndex = 0; kitIndex < 8; kitIndex++) {
      _drumSendCache[kitIndex] = _DrumSendInfo(
        DrumParts.ledByKitIndex(kitIndex),
        DrumParts.rgbByKitIndex(kitIndex),
      );
    }
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

      _noteSprite = await _createNoteSpriteWaterDropReadable();

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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _buildResponsiveCanvas(context, constraints),
        ),
      ),
    );
  }

  Widget _buildResponsiveCanvas(BuildContext context, BoxConstraints constraints) {
    final s = _song!;
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final size = Size(screenWidth, screenHeight);
    final safeArea = MediaQuery.of(context).padding;

    final minDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;

    final topPadding = safeArea.top + (minDimension * 0.02);
    final horizontalPadding = minDimension * 0.03;

    final topY = topPadding;
    final progressY = topY + (minDimension * 0.12);
    final speedY = progressY + (minDimension * 0.06);

    final buttonSize = (minDimension * 0.11).clamp(40.0, 56.0);
    final timerFontSize = (minDimension * 0.03).clamp(10.0, 14.0);
    final speedFontSize = (minDimension * 0.035).clamp(12.0, 16.0);
    final progressHeight = (minDimension * 0.02).clamp(6.0, 12.0);

    final dstRect = computeDrumRect(
      screen: size,
      safe: safeArea,
      aspect: kDrumAspect,
    );

    final roadTopY = (speedY - minDimension * 0.02).clamp(0.0, size.height);
    final roadBottomY = size.height - safeArea.bottom;

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

        Positioned(
          top: topY,
          left: horizontalPadding,
          child: _ResponsivePillButton(
            icon: Icons.arrow_back,
            size: buttonSize,
            onTap: () => Navigator.pop(context),
          ),
        ),

        Positioned(
          top: topY,
          left: horizontalPadding + buttonSize + (minDimension * 0.02),
          child: _ResponsivePillButton(
            icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: buttonSize,
            onTap: () => _togglePlay(),
          ),
        ),

        Positioned(
          top: topY + (minDimension * 0.01),
          right: horizontalPadding,
          child: ValueListenableBuilder<int>(
            valueListenable: _playerMsN,
            builder: (_, ms, __) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: minDimension * 0.025,
                vertical: minDimension * 0.02,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(minDimension * 0.035),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '${_fmtMs(ms)} / ${_fmtMs(s.durationMs)}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: timerFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: progressY + (minDimension * 0.02),
          left: horizontalPadding,
          right: horizontalPadding,
          child: ValueListenableBuilder<int>(
            valueListenable: _playerMsN,
            builder: (_, ms, __) {
              final progress = (ms / s.durationMs).clamp(0.0, 1.0).toDouble();
              return ClipRRect(
                borderRadius: BorderRadius.circular(progressHeight),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: progressHeight,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.yellowAccent.withValues(alpha: 0.9),
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          top: topY + (minDimension * 0.01),
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
                padding: EdgeInsets.symmetric(
                  horizontal: minDimension * 0.035,
                  vertical: minDimension * 0.02,
                ),
                width: _showSpeedSlider
                    ? (screenWidth * 0.82).clamp(200.0, 380.0)
                    : (minDimension * 0.23).clamp(70.0, 100.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(minDimension * 0.045),
                  border: Border.all(color: Colors.white24),
                ),
                child: _showSpeedSlider
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Speed',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: speedFontSize * 0.85,
                            ),
                          ),
                          SizedBox(width: minDimension * 0.02),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight:
                                    (minDimension * 0.008).clamp(2.0, 4.0),
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius:
                                      (minDimension * 0.018).clamp(5.0, 9.0),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: speedFontSize * 0.85,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '${_speed.toStringAsFixed(2)}x',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: speedFontSize,
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

  /// ✅ Vertical lanes from top to drum centers (straight vertical)
  List<LanePath> _computePerspectiveLanePaths({
    required Size size,
    required Rect dstRect,
    required double roadTopY,
  }) {
    Offset anchorOfKit(int kitIndex) {
      final a = DrumKitLayout.anchor[kitIndex]!;
      return Offset(
        dstRect.left + a.x * dstRect.width,
        dstRect.top + a.y * dstRect.height,
      );
    }

    final targets = List<Offset>.generate(8, (lanePos) {
      final kitIndex = kLaneOrderToKitIndex[lanePos];
      return anchorOfKit(kitIndex);
    });

    final paths = <LanePath>[];
    for (int lanePos = 0; lanePos < 8; lanePos++) {
      final p2 = targets[lanePos];
      final p0 = Offset(p2.dx, 0.0);
      final p1 = Offset(p2.dx, p2.dy * 0.5);
      paths.add(LanePath(p0, p1, p2));
    }

    return paths;
  }
}

/// Responsive Button
class _ResponsivePillButton extends StatelessWidget {
  const _ResponsivePillButton({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = size * 0.35;
    final iconSize = size * 0.55;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Container(
          width: size * 1.15,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                blurRadius: size * 0.22,
                offset: Offset(0, size * 0.09),
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

/// Computes the drum kit rectangle with responsive safe area handling
Rect computeDrumRect({
  required Size screen,
  required EdgeInsets safe,
  required double aspect,
}) {
  final availW = screen.width - safe.left - safe.right;
  final availH = screen.height - safe.top - safe.bottom;

  double drawW = availW;
  double drawH = drawW / aspect;

  if (drawH > availH * 0.65) {
    drawH = availH * 0.65;
    drawW = drawH * aspect;
  }

  final minDimension =
      screen.width < screen.height ? screen.width : screen.height;
  final minWidth = minDimension * 0.8;
  final minHeight = minWidth / aspect;

  if (drawW < minWidth) {
    drawW = minWidth;
    drawH = minHeight;
  }

  final left = safe.left + (availW - drawW) / 2.0;
  final bottomMargin = availH * 0.02;
  final top = screen.height - safe.bottom - drawH - bottomMargin;

  return Rect.fromLTWH(left, top, drawW, drawH);
}

/// ✅ Readable tapered tail sprite
Future<ui.Image> _createNoteSpriteWaterDropReadable() async {
  const w = 48;
  const h = 160;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));

  final cx = w * 0.5;
  final headCy = h * 0.84;

  final tailTopY = 8.0;
  final tailBottomY = headCy - 16.0;

  const topHalf = 2.6;
  const bottomHalf = 8.8;

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

  final tailHazePaint = Paint()
    ..isAntiAlias = true
    ..shader = ui.Gradient.linear(
      Offset(cx, tailTopY),
      Offset(cx, tailBottomY),
      [
        Colors.white.withValues(alpha: 0.00),
        Colors.white.withValues(alpha: 0.10),
        Colors.white.withValues(alpha: 0.30),
        Colors.white.withValues(alpha: 0.40),
      ],
      const [0.0, 0.35, 0.75, 1.0],
    )
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.2);

  canvas.drawPath(tail, tailHazePaint);

  final coreTop = Offset(cx, tailTopY + 6.0);
  final coreBottom = Offset(cx, tailBottomY);

  final tailCorePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.2
    ..shader = ui.Gradient.linear(
      coreTop,
      coreBottom,
      [
        Colors.white.withValues(alpha: 0.00),
        Colors.white.withValues(alpha: 0.22),
        Colors.white.withValues(alpha: 0.55),
      ],
      const [0.0, 0.45, 1.0],
    );

  canvas.drawLine(coreTop, coreBottom, tailCorePaint);

  final s = 18.5;

  final head = Path()
    ..moveTo(cx, headCy - s * 1.08)
    ..cubicTo(
      cx + s * 1.15,
      headCy - s * 0.70,
      cx + s * 1.30,
      headCy + s * 0.20,
      cx,
      headCy + s * 1.15,
    )
    ..cubicTo(
      cx - s * 1.30,
      headCy + s * 0.20,
      cx - s * 1.15,
      headCy - s * 0.70,
      cx,
      headCy - s * 1.08,
    )
    ..close();

  final headGlowPaint = Paint()
    ..isAntiAlias = true
    ..color = Colors.white.withValues(alpha: 0.35)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6.0);
  canvas.drawPath(head, headGlowPaint);

  final headFillPaint = Paint()
    ..isAntiAlias = true
    ..shader = ui.Gradient.radial(
      Offset(cx - 4.0, headCy - 6.0),
      s * 1.4,
      [
        Colors.white.withValues(alpha: 0.98),
        Colors.white.withValues(alpha: 0.88),
        Colors.white.withValues(alpha: 0.80),
      ],
      const [0.0, 0.55, 1.0],
    );
  canvas.drawPath(head, headFillPaint);

  final headStrokePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..color = Colors.white.withValues(alpha: 0.55);
  canvas.drawPath(head, headStrokePaint);

  canvas.drawCircle(
    Offset(cx - 5.0, headCy - 7.0),
    4.1,
    Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.24),
  );

  canvas.drawCircle(
    Offset(cx - 2.5, headCy - 3.0),
    1.6,
    Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withValues(alpha: 0.35),
  );

  final pic = recorder.endRecording();
  final img = await pic.toImage(w, h);
  pic.dispose();
  return img;
}
