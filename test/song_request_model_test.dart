import 'package:drumly/models/song_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SongRequestCreate sends only public mobile fields', () {
    const request = SongRequestCreate(
      artistName: ' maNga ',
      songTitle: ' Bir Kadın Çizeceksin ',
      songLink: ' https://youtu.be/M-rZ3602Lm8 ',
      albumName: ' maNga ',
      genre: ' rock ',
      releaseYear: 2004,
      language: ' Türkçe ',
      description: ' İlk albüm versiyonu ',
    );

    expect(request.toJson(), {
      'artist_name': 'maNga',
      'song_title': 'Bir Kadın Çizeceksin',
      'song_link': 'https://youtu.be/M-rZ3602Lm8',
      'album_name': 'maNga',
      'genre': 'rock',
      'release_year': 2004,
      'language': 'Türkçe',
      'description': 'İlk albüm versiyonu',
    });
  });

  test('SongRequestCreate omits empty optional and server-owned fields', () {
    const request = SongRequestCreate(
      artistName: 'Artist',
      songTitle: 'Song',
      songLink: ' ',
      description: '',
    );

    final json = request.toJson();
    expect(json, {'artist_name': 'Artist', 'song_title': 'Song'});
    for (final forbidden in [
      'user_id',
      'user_email',
      'user_name',
      'status',
      'priority',
      'is_deleted',
      'processed_by',
      'admin_notes',
      'completed_song_id',
      'created_at',
      'updated_at',
    ]) {
      expect(json, isNot(contains(forbidden)));
    }
  });

  test('SongRequestModel parses backend-owned and nullable fields', () {
    final model = SongRequestModel.fromJson({
      '_id': 'mongo-id',
      'request_id': 'req_123',
      'artist_name': 'maNga',
      'song_title': 'Bir Kadın Çizeceksin',
      'release_year': 2004,
      'status': 'pending',
      'priority': 'normal',
      'is_deleted': false,
      'created_at': '2026-07-27T14:30:00+00:00',
      'updated_at': '2026-07-27T14:30:00+00:00',
      'deleted_at': null,
      'admin_notes': null,
    });

    expect(model.id, 'mongo-id');
    expect(model.requestId, 'req_123');
    expect(model.releaseYear, 2004);
    expect(model.createdAt, isNotNull);
    expect(model.deletedAt, isNull);
    expect(model.adminNotes, isNull);
  });
}
