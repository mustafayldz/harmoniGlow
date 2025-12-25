/// songsv2 API response modeli
class SongV2Model {
  SongV2Model({
    required this.songv2Id, required this.v, required this.title, required this.artist, required this.bpm, required this.ts, required this.durationMs, required this.source, this.id,
    this.syncMs = 0,
    this.lookaheadMs = 2200,
    this.hitMs = 80,
    this.calibrateSpeed = 1.0,
    this.lanes = const [],
    this.dt = const [],
    this.m = const [],
    this.chart,
    this.isLocked = false,
    this.createdAt,
    this.updatedAt,
  });

  factory SongV2Model.fromJson(Map<String, dynamic> json) => SongV2Model(
        id: json['_id'] as String?,
        songv2Id: json['songv2_id'] as String,
        v: json['v'] as int,
        title: json['title'] as String,
        artist: json['artist'] as String,
        bpm: json['bpm'] as int,
        ts: json['ts'] as String,
        durationMs: json['duration_ms'] as int,
        source: SongSource.fromJson(json['source'] as Map<String, dynamic>),
        syncMs: json['sync_ms'] as int? ?? 0,
        lookaheadMs: json['lookahead_ms'] as int? ?? 2200,
        hitMs: json['hit_ms'] as int? ?? 80,
        calibrateSpeed: (json['calibrate_speed'] as num?)?.toDouble() ?? 1.0,
        lanes: (json['lanes'] as List<dynamic>?)
                ?.map((e) => LaneInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        dt: (json['dt'] as List<dynamic>?)?.cast<int>() ?? [],
        m: (json['m'] as List<dynamic>?)?.cast<int>() ?? [],
        chart: json['chart'] != null
            ? ChartData.fromJson(json['chart'] as Map<String, dynamic>)
            : null,
        isLocked: json['is_locked'] as bool? ?? false,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  final String? id; // MongoDB ID
  final String songv2Id; // UUID
  final int v; // Version
  final String title;
  final String artist;
  final int bpm;
  final String ts; // Time signature (e.g., "4/4")
  final int durationMs;
  final SongSource source;
  final int syncMs;
  final int lookaheadMs;
  final int hitMs;
  final double calibrateSpeed;
  final List<LaneInfo> lanes;
  final List<int> dt; // Delta times
  final List<int> m; // Lane masks
  final ChartData? chart;
  final bool isLocked;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'songv2_id': songv2Id,
        'v': v,
        'title': title,
        'artist': artist,
        'bpm': bpm,
        'ts': ts,
        'duration_ms': durationMs,
        'source': source.toJson(),
        'sync_ms': syncMs,
        'lookahead_ms': lookaheadMs,
        'hit_ms': hitMs,
        'calibrate_speed': calibrateSpeed,
        'lanes': lanes.map((e) => e.toJson()).toList(),
        'dt': dt,
        'm': m,
        if (chart != null) 'chart': chart!.toJson(),
        'is_locked': isLocked,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

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
}

class SongSource {
  SongSource({
    required this.type,
    required this.url,
    required this.videoId,
  });

  factory SongSource.fromJson(Map<String, dynamic> json) => SongSource(
        type: json['type'] as String,
        url: json['url'] as String,
        videoId: json['video_id'] as String,
      );
  final String type; // "youtube"
  final String url;
  final String videoId;

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        'video_id': videoId,
      };
}

class LaneInfo {
  LaneInfo({
    required this.lane,
    required this.name,
    required this.midiNotes,
  });

  factory LaneInfo.fromJson(Map<String, dynamic> json) => LaneInfo(
        lane: json['lane'] as int,
        name: json['name'] as String,
        midiNotes: (json['midi_notes'] as List<dynamic>).cast<int>(),
      );
  final int lane; // 0-7
  final String name;
  final List<int> midiNotes;

  Map<String, dynamic> toJson() => {
        'lane': lane,
        'name': name,
        'midi_notes': midiNotes,
      };
}

class ChartData {
  ChartData({
    required this.ppq,
    required this.tempoMap,
    required this.events,
    this.format = 'score_v2',
  });

  factory ChartData.fromJson(Map<String, dynamic> json) => ChartData(
        format: json['format'] as String? ?? 'score_v2',
        ppq: json['ppq'] as int,
        tempoMap: (json['tempo_map'] as List<dynamic>)
            .map((e) => TempoMapEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        events: (json['events'] as List<dynamic>)
            .map((e) => ChartEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  final String format;
  final int ppq; // Pulses per quarter
  final List<TempoMapEntry> tempoMap;
  final List<ChartEvent> events;

  Map<String, dynamic> toJson() => {
        'format': format,
        'ppq': ppq,
        'tempo_map': tempoMap.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
      };
}

class TempoMapEntry {
  TempoMapEntry({
    required this.tick,
    required this.bpm,
  });

  factory TempoMapEntry.fromJson(Map<String, dynamic> json) => TempoMapEntry(
        tick: json['tick'] as int,
        bpm: json['bpm'] as int,
      );
  final int tick;
  final int bpm;

  Map<String, dynamic> toJson() => {
        'tick': tick,
        'bpm': bpm,
      };
}

class ChartEvent {
  ChartEvent({
    required this.t0,
    required this.dt,
    required this.m,
  });

  factory ChartEvent.fromJson(Map<String, dynamic> json) => ChartEvent(
        t0: json['t0'] as int,
        dt: json['dt'] as int,
        m: json['m'] as int,
      );
  final int t0; // Start tick
  final int dt; // Duration
  final int m; // Lane mask

  Map<String, dynamic> toJson() => {
        't0': t0,
        'dt': dt,
        'm': m,
      };
}

/// API Response wrapper
class SongV2Response {
  SongV2Response({
    required this.success,
    required this.message,
    this.data,
    this.total,
    this.limit,
    this.offset,
  });

  factory SongV2Response.fromJson(Map<String, dynamic> json) => SongV2Response(
        success: json['success'] as bool,
        message: json['message'] as String,
        data: json['data'] != null
            ? (json['data'] is List
                ? (json['data'] as List<dynamic>)
                    .map((e) => SongV2Model.fromJson(e as Map<String, dynamic>))
                    .toList()
                : [SongV2Model.fromJson(json['data'] as Map<String, dynamic>)])
            : null,
        total: json['total'] as int?,
        limit: json['limit'] as int?,
        offset: json['offset'] as int?,
      );
  final bool success;
  final String message;
  final List<SongV2Model>? data;
  final int? total;
  final int? limit;
  final int? offset;

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.map((e) => e.toJson()).toList(),
        if (total != null) 'total': total,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
}
