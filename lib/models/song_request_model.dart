class SongRequestModel {
  const SongRequestModel({
    required this.artistName,
    required this.songTitle,
    this.id = '',
    this.requestId = '',
    this.songLink,
    this.albumName,
    this.genre,
    this.releaseYear,
    this.language,
    this.description,
    this.status = 'pending',
    this.priority = 'normal',
    this.isDeleted = false,
    this.adminNotes,
    this.processedBy,
    this.completedSongId,
  });

  factory SongRequestModel.fromJson(Map<String, dynamic> json) =>
      SongRequestModel(
        id: _string(json['_id'] ?? json['id']) ?? '',
        requestId: _string(json['request_id']) ?? '',
        artistName: _string(json['artist_name']) ?? '',
        songTitle: _string(json['song_title']) ?? '',
        songLink: _string(json['song_link']),
        albumName: _string(json['album_name']),
        genre: _string(json['genre']),
        releaseYear: _int(json['release_year']),
        language: _string(json['language']),
        description: _string(json['description']),
        status: _string(json['status']) ?? 'pending',
        priority: _string(json['priority']) ?? 'normal',
        isDeleted: _bool(json['is_deleted']),
        adminNotes: _string(json['admin_notes']),
        processedBy: _string(json['processed_by']),
        completedSongId: _string(json['completed_song_id']),
      );

  final String id;
  final String requestId;
  final String artistName;
  final String songTitle;
  final String? songLink;
  final String? albumName;
  final String? genre;
  final int? releaseYear;
  final String? language;
  final String? description;
  final String status;
  final String priority;
  final bool isDeleted;
  final String? adminNotes;
  final String? processedBy;
  final String? completedSongId;

  /// Server-owned fields are intentionally excluded from this payload.
  Map<String, dynamic> toCreateJson() => {
        'artist_name': artistName.trim(),
        'song_title': songTitle.trim(),
        if (_hasValue(songLink)) 'song_link': songLink!.trim(),
        if (_hasValue(albumName)) 'album_name': albumName!.trim(),
        if (_hasValue(genre)) 'genre': genre!.trim(),
        if (releaseYear != null) 'release_year': releaseYear,
        if (_hasValue(language)) 'language': language!.trim(),
        if (_hasValue(description)) 'description': description!.trim(),
      };

  static bool _hasValue(String? value) => value?.trim().isNotEmpty ?? false;

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }
}
