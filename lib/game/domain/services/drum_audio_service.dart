import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// DRUM AUDIO SERVICE - Lane bazlı drum ses yönetimi
/// ============================================================================
///
/// Bu servis, her drum pad'i için ses havuzu (AudioPool) yönetir.
/// Düşük gecikmeli ses çalma için önceden yüklenmiş ses havuzları kullanır.
///
/// ## Platform Desteği
///
/// - iOS/macOS: .m4a format (daha iyi codec desteği)
/// - Android: .m4a format (emulatör/cihaz uyumluluğu için)
///
/// ## Ses Dosyaları (assets/audio/)
///
/// | Lane | Dosya Adı     | Açıklama                |
/// |------|---------------|-------------------------|
/// | 0    | close_hihat   | Hi-hat (tık)            |
/// | 1    | crash_2       | Crash cymbal (çan)      |
/// | 2    | ride_1        | Ride cymbal (ping)      |
/// | 3    | snare_hard    | Snare (sert)            |
/// | 4    | tom_1         | Tom 1 (dong)            |
/// | 5    | tom_2         | Tom 2 (dong)            |
/// | 6    | tom_floor     | Floor tom (düm)         |
/// | 7    | kick          | Kick (boom)             |
///
/// ## Örnek Kullanım
///
/// ```dart
/// // Oyun başında bir kez çağır:
/// await DrumAudioService.init();
///
/// // Oyuncu bir pad'e dokunduğunda:
/// DrumAudioService.playLane(7); // Kick sesi çalar
/// ```
/// ============================================================================
class DrumAudioService {
  DrumAudioService._();

  /// Her lane için ses dosyası base isimleri.
  ///
  /// Index sıralaması lane numarasına karşılık gelir.
  /// Dosya uzantısı platforma göre otomatik eklenir.
  static final List<String> _soundFilesByLane = [
    'close_hihat', // Lane 0: Hi-hat
    'crash_2', // Lane 1: Crash cymbal
    'ride_1', // Lane 2: Ride cymbal
    'snare_hard', // Lane 3: Snare
    'tom_1', // Lane 4: Tom 1
    'tom_2', // Lane 5: Tom 2
    'tom_floor', // Lane 6: Floor tom
    'kick', // Lane 7: Kick
  ];

  /// Platforma göre belirlenen ses dosyası uzantısı.
  static String _extension = 'm4a';

  /// Her lane için çözülmüş dosya adı (extension dahil).
  static List<String> _soundFilesByLaneWithExt = [];

  /// Lane başına minimum tetikleme aralığı (ms).
  static const int _minIntervalMs = 35;

  /// Global maksimum SFX hızı (ms penceresinde).
  static const int _globalWindowMs = 1000;
  static const int _globalMaxPlays = 80;

  static late List<int> _lastPlayMsByLane;
  static int _globalWindowStartMs = 0;
  static int _globalPlayCount = 0;

  /// Servisin initialize edilip edilmediği.
  static bool _initialized = false;

  /// Servisi başlatır ve tüm ses havuzlarını yükler.
  ///
  /// Bu metod oyun başlamadan önce bir kez çağrılmalıdır.
  /// İkinci çağrılarda hiçbir şey yapmaz (idempotent).
  ///
  /// Throws: Ses dosyaları bulunamazsa veya yüklenemezse hata fırlatır.
  static Future<void> init() async {
    // Zaten initialize edildiyse çık
    if (_initialized) return;

    // Platforma göre uzantı belirle
    // iOS/macOS: .m4a (AAC codec, daha iyi kalite)
    // Android: .m4a (emulatör/cihazlarda ogg decode hatalarını önlemek için)
    _extension = 'm4a';

    _soundFilesByLaneWithExt = _soundFilesByLane
        .map((base) => '$base.$_extension')
        .toList();

    _lastPlayMsByLane = List<int>.filled(_soundFilesByLane.length, 0);
    _globalWindowStartMs = 0;
    _globalPlayCount = 0;

    // SFX'leri preload et (AudioCache prefix = assets/audio/)
    try {
      await FlameAudio.audioCache.loadAll(_soundFilesByLaneWithExt);
    } catch (e) {
      debugPrint('DrumAudioService preload error: $e');
    }

    _initialized = true;
  }

  /// Belirtilen lane için drum sesini çalar.
  ///
  /// [lane] Çalınacak sesin lane numarası (0-7).
  /// [volume] Ses seviyesi (0.0-1.0, varsayılan 1.0).
  ///
  /// Servis initialize edilmemişse veya geçersiz lane verilmişse
  /// sessizce hiçbir şey yapmaz.
  static void playLane(int lane, {double volume = 1.0}) {
    // Guard: Servis hazır değilse çık
    if (!_initialized) return;

    // Guard: Geçersiz lane numarası
    if (lane < 0 || lane >= _soundFilesByLaneWithExt.length) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPlayMsByLane[lane] < _minIntervalMs) return;

    if (now - _globalWindowStartMs > _globalWindowMs) {
      _globalWindowStartMs = now;
      _globalPlayCount = 0;
    }
    if (_globalPlayCount >= _globalMaxPlays) return;

    _lastPlayMsByLane[lane] = now;
    _globalPlayCount++;

    final fileName = _soundFilesByLaneWithExt[lane];
    try {
      FlameAudio.play(
        fileName,
        volume: volume,
      );
    } catch (e) {
      debugPrint('DrumAudioService play error (lane $lane): $e');
    }
  }

  /// Tüm SFX cache'i temizler ve çalmayı durdurur.
  static Future<void> stopAll() async {
    _initialized = false;
    _soundFilesByLaneWithExt = [];
    _globalWindowStartMs = 0;
    _globalPlayCount = 0;
    _lastPlayMsByLane = List<int>.filled(_soundFilesByLane.length, 0);
    try {
      await FlameAudio.audioCache.clearAll();
    } catch (e) {
      debugPrint('DrumAudioService stopAll error: $e');
    }
  }

  /// Servisin kullanıma hazır olup olmadığını döndürür.
  static bool get isReady => _initialized;
}
