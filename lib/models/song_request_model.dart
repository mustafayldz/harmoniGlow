class SongRequestModel {
  const SongRequestModel({
    required this.songTitle,
    this.requestId,
    this.userId,
    this.artist,
    this.notes,
    this.status = 'pending',
    this.publishedSongId,
    this.createdAt,
    this.updatedAt,
  });

  factory SongRequestModel.fromJson(Map<String, dynamic> json) =>
      SongRequestModel(
        requestId: (json['request_id'] ?? json['id']) as String?,
        userId: json['user_id'] as String?,
        songTitle: json['song_title'] as String? ?? '',
        artist: json['artist'] as String?,
        notes: json['notes'] as String?,
        status: json['status'] as String? ?? 'pending',
        publishedSongId: json['published_song_id'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      );

  final String? requestId;
  final String? userId;
  final String songTitle;
  final String? artist;
  final String? notes;
  final String status;
  final String? publishedSongId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The public mobile endpoint must derive `user_id` from the bearer token.
  Map<String, dynamic> toCreateJson() => {
        'song_title': songTitle.trim(),
        if (artist?.trim().isNotEmpty ?? false) 'artist': artist!.trim(),
        if (notes?.trim().isNotEmpty ?? false) 'notes': notes!.trim(),
      };
}
