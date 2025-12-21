import 'dart:convert';

/// song_notes.json dosyasındaki score formatını temsil eder
class ScoreV2Model {

  ScoreV2Model({
    required this.ppq,
    required this.tempoMap,
    required this.events,
  });

  factory ScoreV2Model.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return ScoreV2Model.fromJson(json as Map<String, dynamic>);
  }

  factory ScoreV2Model.fromJson(Map<String, dynamic> json) => ScoreV2Model(
      ppq: json['ppq'] as int,
      tempoMap: (json['tempo_map'] as List<dynamic>)
          .map((e) => TempoMapEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List<dynamic>)
          .map((e) => EventEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  final int ppq;
  final List<TempoMapEntry> tempoMap;
  final List<EventEntry> events;

  Map<String, dynamic> toJson() => {
      'ppq': ppq,
      'tempo_map': tempoMap.map((e) => e.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
    };

  String toJsonString() => jsonEncode(toJson());
}

/// Tempo değişim noktaları
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

/// Müzik notası/event'i
class EventEntry {  // MIDI note veya mask değeri

  EventEntry({
    required this.t0,
    required this.dt,
    required this.m,
  });

  factory EventEntry.fromJson(Map<String, dynamic> json) => EventEntry(
      t0: json['t0'] as int,
      dt: json['dt'] as int,
      m: json['m'] as int,
    );
  final int t0; // Başlangıç zamanı (tick)
  final int dt; // Süre (duration in ticks)
  final int m;

  Map<String, dynamic> toJson() => {
      't0': t0,
      'dt': dt,
      'm': m,
    };
}
