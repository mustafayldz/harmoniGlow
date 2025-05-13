class NoteModel {
  NoteModel({
    required this.i,
    required this.sM,
    required this.eM,
    required this.led,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        i: json['i'] as int,
        sM: json['sM'] as int,
        eM: json['eM'] as int,
        led:
            List<int>.from((json['led'] as List<dynamic>).map((n) => n as int)),
      );
  final int i;
  final int sM;
  final int eM;
  final List<int> led;

  Map<String, dynamic> toJson() => {
        'i': i,
        'sM': sM,
        'eM': eM,
        'led': led,
      };
}
