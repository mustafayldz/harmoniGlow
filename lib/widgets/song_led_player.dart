import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// -----------------------------
/// Models
/// -----------------------------

class ScoreEvent {  // 8-bit mask

  const ScoreEvent({required this.t0, required this.dt, required this.m});

  factory ScoreEvent.fromJson(Map<String, dynamic> j) => ScoreEvent(
      t0: (j['t0'] as num).round(),
      dt: (j['dt'] as num).round(),
      m: (j['m'] as num).round(),
    );
  final int t0; // tick
  final int dt; // tick duration for glow
  final int m;
}

class TempoChange {

  const TempoChange({required this.tick, required this.bpm});

  factory TempoChange.fromJson(Map<String, dynamic> j) => TempoChange(
      tick: (j['tick'] as num).round(),
      bpm: (j['bpm'] as num).toDouble(),
    );
  final int tick;
  final double bpm;
}

class TempoIndexPoint {

  const TempoIndexPoint({required this.tick, required this.bpm, required this.msAtTick});
  final int tick;
  final double bpm;
  final double msAtTick;
}

class ScoreV2 {

  ScoreV2({
    required this.ppq,
    required this.tempoMap,
    required this.events,
  }) {
    // Ensure events sorted
    events.sort((a, b) => a.t0.compareTo(b.t0));
    _tempoIndex = _buildTempoIndex(tempoMap, ppq);
  }

  factory ScoreV2.fromJson(Map<String, dynamic> j) {
    final ppq = (j['ppq'] as num?)?.round() ?? 960;
    final tm = (j['tempo_map'] as List<dynamic>?)
            ?.map((e) => TempoChange.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <TempoChange>[];
    final ev = (j['events'] as List<dynamic>?)
            ?.map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <ScoreEvent>[];
    return ScoreV2(ppq: ppq, tempoMap: tm, events: ev);
  }
  final int ppq;
  final List<TempoChange> tempoMap;
  final List<ScoreEvent> events;

  late final List<TempoIndexPoint> _tempoIndex;

  List<TempoIndexPoint> get tempoIndex => _tempoIndex;
}

/// -----------------------------
/// Transport helpers (tick <-> ms)
/// -----------------------------

List<TempoIndexPoint> _buildTempoIndex(List<TempoChange> tempoMap, int ppq) {
  final tm = tempoMap
      .where((t) => t.tick >= 0 && t.bpm > 0)
      .toList()
    ..sort((a, b) => a.tick.compareTo(b.tick));

  // Ensure tick 0 exists
  if (tm.isEmpty || tm.first.tick != 0) {
    final fallbackBpm = tm.isNotEmpty ? tm.first.bpm : 120.0;
    tm.insert(0, TempoChange(tick: 0, bpm: fallbackBpm));
  }

  final idx = <TempoIndexPoint>[];
  var prevTick = tm[0].tick;
  var prevBpm = tm[0].bpm;
  var msAtTick = 0.0;

  idx.add(TempoIndexPoint(tick: prevTick, bpm: prevBpm, msAtTick: msAtTick));

  for (var i = 1; i < tm.length; i++) {
    final cur = tm[i];
    final dtTicks = cur.tick - prevTick;
    if (dtTicks > 0) {
      msAtTick += (dtTicks * 60000.0) / (prevBpm * ppq);
    }
    prevTick = cur.tick;
    prevBpm = cur.bpm;
    idx.add(TempoIndexPoint(tick: prevTick, bpm: prevBpm, msAtTick: msAtTick));
  }

  return idx;
}

/// Binary search: find tempo point <= tick
int _findTempoPoint(List<TempoIndexPoint> tempoIndex, int tick) {
  var lo = 0;
  var hi = tempoIndex.length - 1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    final mt = tempoIndex[mid].tick;
    if (mt == tick) return mid;
    if (mt < tick) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return math.max(0, hi);
}

double tickToMs(int tick, ScoreV2 score, {double speed = 1, double audioOffsetMs = 0}) {
  final ppq = score.ppq;
  final idx = score.tempoIndex;

  if (idx.isEmpty) {
    final bpm = 120.0;
    final ms = (tick * 60000.0) / (bpm * ppq);
    return (ms / speed) + audioOffsetMs;
  }

  final t = math.max(0, tick);
  final i = _findTempoPoint(idx, t);
  final p = idx[i];
  final deltaTicks = t - p.tick;
  final deltaMs = (deltaTicks * 60000.0) / (p.bpm * ppq);
  return (p.msAtTick + deltaMs) / speed + audioOffsetMs;
}

int msToTick(double ms, ScoreV2 score, {double speed = 1, double audioOffsetMs = 0}) {
  final ppq = score.ppq;
  final idx = score.tempoIndex;

  final targetMs = (ms - audioOffsetMs) * speed;

  if (idx.isEmpty) {
    final bpm = 120.0;
    return ((targetMs * bpm * ppq) / 60000.0).round();
  }

  var curBpm = idx[0].bpm;
  var prevTick = idx[0].tick;
  var accMs = 0.0;

  for (var i = 1; i < idx.length; i++) {
    final nextTick = idx[i].tick;
    final segTicks = math.max(0, nextTick - prevTick);
    final segMs = (segTicks * 60000.0) / (curBpm * ppq);

    if (targetMs <= accMs + segMs) {
      final remMs = targetMs - accMs;
      final addTicks = (remMs * curBpm * ppq) / 60000.0;
      return (prevTick + addTicks).round();
    }

    accMs += segMs;
    prevTick = nextTick;
    curBpm = idx[i].bpm;
  }

  final remMs = math.max(0.0, targetMs - accMs);
  final addTicks = (remMs * curBpm * ppq) / 60000.0;
  return (prevTick + addTicks).round();
}

int lastTickOf(ScoreV2 score) {
  if (score.events.isEmpty) return 0;
  final last = score.events.last;
  return last.t0 + last.dt;
}

int lowerBoundByT0(List<ScoreEvent> events, int tick) {
  var lo = 0;
  var hi = events.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (events[mid].t0 < tick) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

int maskAtTick(ScoreV2 score, int tick) {
  final events = score.events;
  if (events.isEmpty) return 0;

  final idx = lowerBoundByT0(events, tick);
  final start = math.max(0, idx - 60);
  var mask = 0;

  for (var i = start; i < events.length; i++) {
    final e = events[i];
    if (e.t0 > tick) break;
    if (tick < e.t0 + e.dt) mask |= e.m;
  }
  return mask;
}

/// -----------------------------
/// Falling notes (top -> hit zones)
/// -----------------------------

const double kLookAheadMs = 2200; // spawn this many ms before hit
const double kPastMs = 160;       // keep notes a bit after hit
const double kHitWindowMs = 70;   // green when near hit

List<int> lanesFromMask(int mask) {
  final out = <int>[];
  for (var i = 0; i < 8; i++) {
    if ((mask & (1 << i)) != 0) out.add(i);
  }
  return out;
}

double clamp(double v, double a, double b) => math.max(a, math.min(b, v));

class FallingNote {

  const FallingNote({
    required this.key,
    required this.lane,
    required this.x,
    required this.y,
    required this.isHit,
    required this.opacity,
  });
  final String key;
  final int lane; // 0..7
  final double x; // px
  final double y; // px
  final bool isHit;
  final double opacity;
}

List<FallingNote> buildVisibleFallingNotes({
  required ScoreV2 score,
  required double posMs,
  required double speed,
  required double audioOffsetMs,
  required double stageW,
  required double stageH,
}) {
  final events = score.events;
  if (events.isEmpty) return const [];

  // geometry scaled from React numbers
  final padAreaH = stageH * 0.452; // ~190/420
  final padRowH = padAreaH / 2;
  final spawnY = stageH * 0.057;   // ~24/420

  final startMs = posMs - kPastMs;
  final endMs = posMs + kLookAheadMs;

  final startTick = math.max(0, msToTick(startMs, score, speed: speed, audioOffsetMs: audioOffsetMs));
  final endTick = math.max(0, msToTick(endMs, score, speed: speed, audioOffsetMs: audioOffsetMs)) + 1;

  final idx = lowerBoundByT0(events, startTick);
  final notes = <FallingNote>[];

  for (var i = idx; i < events.length; i++) {
    final e = events[i];
    if (e.t0 > endTick) break;

    final eventMs = tickToMs(e.t0, score, speed: speed, audioOffsetMs: audioOffsetMs);
    final alphaRaw = (eventMs - posMs) / kLookAheadMs; // 0 at hit, 1 at spawn time
    final alpha = clamp(alphaRaw, -kPastMs / kLookAheadMs, 1.1);

    final isHit = (eventMs - posMs).abs() <= kHitWindowMs;

    final lanes = lanesFromMask(e.m);
    for (final lane in lanes) {
      final col = lane % 4;
      final row = lane < 4 ? 0 : 1;

      final padTop = stageH - padAreaH;
      final targetY = padTop + row * padRowH + padRowH / 2;

      final y = targetY + (spawnY - targetY) * alpha;

      final x = (col + 0.5) / 4 * stageW;

      double opacity;
      if (alphaRaw < 0) {
        opacity = clamp(1 + alphaRaw * 6, 0, 1);
      } else {
        opacity = clamp(1 - (alphaRaw - 0.85) * 3, 0.2, 1);
      }

      if (y < -40 || y > stageH + 60 || opacity <= 0.02) continue;

      notes.add(FallingNote(
        key: '${e.t0}-$lane',
        lane: lane,
        x: x,
        y: y,
        isHit: isHit,
        opacity: opacity,
      ),);
    }
  }

  return notes;
}

/// -----------------------------
/// Flutter Play Area (what you asked for)
/// -----------------------------

class SongLedPlayer extends StatefulWidget {

  const SongLedPlayer({
    super.key,
    this.scoreJson,
    this.onActiveMask,
  });
  final String? scoreJson;

  /// If you want to push mask to BLE, use this.
  final void Function(int mask)? onActiveMask;

  @override
  State<SongLedPlayer> createState() => _SongLedPlayerState();
}

class _SongLedPlayerState extends State<SongLedPlayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  bool _isPlaying = false;
  Duration? _lastElapsed;

  double _posMs = 0;
  double _speed = 1.0;

  final double _audioOffsetMs = 0; // offset UI yok — default 0

  int _lastMask = -1;
  
  ScoreV2? _score;

  double get _durationMs {
    if (_score == null) return 0;
    final lt = lastTickOf(_score!);
    return tickToMs(lt, _score!, audioOffsetMs: _audioOffsetMs);
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
    super.dispose();
  }

  void _loadScore() {
    if (widget.scoreJson == null || widget.scoreJson!.trim().isEmpty) {
      setState(() => _score = null);
      return;
    }

    try {
      final json = (widget.scoreJson!.startsWith('{')) 
          ? jsonDecode(widget.scoreJson!) as Map<String, dynamic>
          : <String, dynamic>{};
      setState(() => _score = ScoreV2.fromJson(json));
    } catch (e) {
      debugPrint('Failed to parse score JSON: $e');
      setState(() => _score = null);
    }
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying || _score == null) return;

    final last = _lastElapsed;
    _lastElapsed = elapsed;

    if (last == null) return;

    final dtMs = (elapsed - last).inMicroseconds / 1000.0;

    setState(() {
      _posMs += dtMs;
      final dur = _durationMs;
      if (dur > 0 && _posMs >= dur) {
        _posMs = dur;
        _isPlaying = false;
        _lastElapsed = null;
        _ticker.stop();
      }
    });

    // Compute active mask + emit if changed
    final curTick = msToTick(_posMs, _score!, speed: _speed, audioOffsetMs: _audioOffsetMs);
    final mask = maskAtTick(_score!, curTick);
    if (mask != _lastMask) {
      _lastMask = mask;
      widget.onActiveMask?.call(mask);
    }
  }

  void _togglePlay() {
    if (_score == null) return;
    
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      _lastElapsed = null;
      _ticker.stop();
    } else {
      setState(() => _isPlaying = true);
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _setScrub(double v) {
    setState(() {
      _posMs = v;
    });

    if (_score == null) return;

    // update mask immediately on scrub
    final curTick = msToTick(_posMs, _score!, speed: _speed, audioOffsetMs: _audioOffsetMs);
    final mask = maskAtTick(_score!, curTick);
    if (mask != _lastMask) {
      _lastMask = mask;
      widget.onActiveMask?.call(mask);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_score == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No score data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final dur = math.max(1.0, _durationMs);

    final curTick = msToTick(_posMs, _score!, speed: _speed, audioOffsetMs: _audioOffsetMs);
    final activeMask = maskAtTick(_score!, curTick);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Controls row
          Row(
            children: [
              ElevatedButton(
                onPressed: _togglePlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPlaying ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_isPlaying ? 'Pause' : 'Play'),
              ),
              const SizedBox(width: 16),

              // Speed
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Speed', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                    Slider(
                      min: 0.5,
                      max: 1.5,
                      divisions: 20,
                      value: _speed,
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                    Text('${_speed.toStringAsFixed(2)}×', style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Text('t = ${_posMs.round()} ms', style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),

          const SizedBox(height: 12),

          // Scrub
          Slider(
            max: dur,
            value: _posMs.clamp(0, dur),
            onChanged: (v) => _setScrub(v),
          ),

          const SizedBox(height: 12),

          // Falling stage
          SizedBox(
            height: 420,
            child: _FallingNotesStageFlutter(
              score: _score!,
              posMs: _posMs,
              speed: _speed,
              audioOffsetMs: _audioOffsetMs,
              activeMask: activeMask,
            ),
          ),

          const SizedBox(height: 12),

          // Debug
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              'currentTick: $curTick · activeMask: $activeMask (0b${activeMask.toRadixString(2).padLeft(8, '0')})',
              style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------
/// Stage widget (Stack layout)
/// -----------------------------

class _FallingNotesStageFlutter extends StatelessWidget {

  const _FallingNotesStageFlutter({
    required this.score,
    required this.posMs,
    required this.speed,
    required this.audioOffsetMs,
    required this.activeMask,
  });
  final ScoreV2 score;
  final double posMs;
  final double speed;
  final double audioOffsetMs;
  final int activeMask;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;

        final padAreaH = h * 0.452;
        final hitLineY = h - padAreaH;

        final notes = buildVisibleFallingNotes(
          score: score,
          posMs: posMs,
          speed: speed,
          audioOffsetMs: audioOffsetMs,
          stageW: w,
          stageH: h,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // background
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  border: Border.all(color: const Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              // lane columns
              Row(
                children: List.generate(4, (i) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: i == 0
                              ? BorderSide.none
                              : const BorderSide(color: Color.fromRGBO(51, 65, 85, 0.5)),
                        ),
                      ),
                    ),
                  ),),
              ),

              // notes
              ...notes.map((n) {
                const noteSize = 18.0;
                return Positioned(
                  left: n.x - noteSize / 2,
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
                              : const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: n.isHit
                                ? const Color.fromRGBO(16, 185, 129, 0.55)
                                : const Color.fromRGBO(59, 130, 246, 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.12)),
                      ),
                    ),
                  ),
                );
              }),

              // hit zone separator
              Positioned(
                left: 0,
                right: 0,
                top: hitLineY,
                child: Container(height: 1, color: const Color.fromRGBO(51, 65, 85, 0.9)),
              ),

              // pads
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                height: padAreaH - 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(30, 41, 59, 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color.fromRGBO(51, 65, 85, 0.8)),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: 8,
                    itemBuilder: (_, i) {
                      final led = i + 1;
                      final on = (activeMask & (1 << (led - 1))) != 0;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: on ? const Color(0xFF10B981) : const Color(0xFF334155),
                            width: on ? 2 : 1,
                          ),
                          gradient: on
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                )
                              : null,
                          color: on ? null : const Color.fromRGBO(15, 23, 42, 0.85),
                          boxShadow: on
                              ? const [
                                  BoxShadow(
                                    color: Color.fromRGBO(16, 185, 129, 0.35),
                                    blurRadius: 18,
                                    offset: Offset(0, 10),
                                  ),
                                ]
                              : const [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$led',
                          style: TextStyle(
                            color: on ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // debug overlay
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(2, 6, 23, 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color.fromRGBO(51, 65, 85, 0.7)),
                  ),
                  child: Text(
                    'lookAhead: ${kLookAheadMs.toInt()}ms · speed: ${speed.toStringAsFixed(2)}×',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
}
