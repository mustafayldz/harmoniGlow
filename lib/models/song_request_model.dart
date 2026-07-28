class SongRequestCreate {
  const SongRequestCreate({
    required this.artistName,
    required this.songTitle,
    this.songLink,
    this.albumName,
    this.genre,
    this.releaseYear,
    this.language,
    this.description,
  });

  final String artistName;
  final String songTitle;
  final String? songLink;
  final String? albumName;
  final String? genre;
  final int? releaseYear;
  final String? language;
  final String? description;

  Map<String, dynamic> toJson() => {
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
}

class SongRequestModel {
  const SongRequestModel({
    required this.id,
    required this.requestId,
    required this.artistName,
    required this.songTitle,
    required this.status,
    required this.priority,
    required this.isDeleted,
    this.userId,
    this.userEmail,
    this.userName,
    this.songLink,
    this.albumName,
    this.genre,
    this.releaseYear,
    this.language,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.estimatedCompletion,
    this.adminNotes,
    this.processedBy,
    this.completedSongId,
  });

  factory SongRequestModel.fromJson(Map<String, dynamic> json) =>
      SongRequestModel(
        id: _string(json['_id'] ?? json['id']) ?? '',
        requestId: _string(json['request_id']) ?? '',
        userId: _string(json['user_id']),
        userEmail: _string(json['user_email']),
        userName: _string(json['user_name']),
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
        createdAt: _dateTime(json['created_at']),
        updatedAt: _dateTime(json['updated_at']),
        deletedAt: _dateTime(json['deleted_at']),
        estimatedCompletion: _dateTime(json['estimated_completion']),
        adminNotes: _string(json['admin_notes']),
        processedBy: _string(json['processed_by']),
        completedSongId: _string(json['completed_song_id']),
      );

  final String id;
  final String requestId;
  final String? userId;
  final String? userEmail;
  final String? userName;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? estimatedCompletion;
  final String? adminNotes;
  final String? processedBy;
  final String? completedSongId;

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

  static DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
