import 'package:shared_preferences/shared_preferences.dart';

import 'package:drumly/game/core/enums/game_enums.dart';

/// ============================================================================
/// LOCAL STORAGE REPOSITORY - SharedPreferences ile yerel veri saklama
/// ============================================================================
///
/// Bu repository, oyun verilerini cihazda kalıcı olarak saklar.
/// High score, son seçilen zorluk gibi verileri yönetir.
///
/// ## Saklanan Veriler
///
/// | Key Pattern           | Açıklama                    | Örnek Key          |
/// |-----------------------|-----------------------------|--------------------|
/// | dh_high_{difficulty}  | Zorluk bazlı high score     | dh_high_easy       |
/// | dh_last_diff          | Son seçilen zorluk          | dh_last_diff       |
///
/// ## Örnek Kullanım
///
/// ```dart
/// // Oyun başında bir kez çağır
/// await LocalStorageRepository.init();
///
/// // High score okuma
/// final score = LocalStorageRepository.highScore(Difficulty.easy);
///
/// // High score kaydetme
/// await LocalStorageRepository.setHighScore(Difficulty.easy, 5000);
/// ```
/// ============================================================================
class LocalStorageRepository {
  LocalStorageRepository._();

  /// SharedPreferences instance'ı.
  static SharedPreferences? _prefs;

  /// Repository'yi başlatır ve SharedPreferences'ı yükler.
  ///
  /// Bu metod oyun başlamadan önce bir kez çağrılmalıdır.
  /// İkinci çağrılarda zaten yüklüyse tekrar yüklemez (idempotent).
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ===========================================================================
  // HIGH SCORE YÖNETİMİ
  // ===========================================================================

  /// Belirtilen zorluk için high score'u döndürür.
  ///
  /// [difficulty] Sorgulanacak zorluk seviyesi.
  /// Returns: Kaydedilmiş high score, yoksa 0.
  static int highScore(Difficulty difficulty) => _prefs?.getInt('dh_high_${difficulty.name}') ?? 0;

  /// Belirtilen zorluk için high score'u kaydeder.
  ///
  /// [difficulty] Kaydedilecek zorluk seviyesi.
  /// [score] Yeni high score değeri.
  static Future<void> setHighScore(Difficulty difficulty, int score) async {
    await _prefs?.setInt('dh_high_${difficulty.name}', score);
  }

  // ===========================================================================
  // ZORLUK SEVİYESİ TERCİHİ
  // ===========================================================================

  /// Son seçilen zorluk seviyesini döndürür.
  ///
  /// Returns: Kaydedilmiş zorluk seviyesi string'i (örn: 'easy'), yoksa null.
  static String? lastDifficulty() => _prefs?.getString('dh_last_diff');

  /// Son seçilen zorluk seviyesini kaydeder.
  ///
  /// [difficulty] Kaydedilecek zorluk seviyesi.
  static Future<void> setLastDifficulty(Difficulty difficulty) async {
    await _prefs?.setString('dh_last_diff', difficulty.name);
  }

  // ===========================================================================
  // YARDIMCI METODLAR
  // ===========================================================================

  /// Repository'nin kullanıma hazır olup olmadığını döndürür.
  static bool get isReady => _prefs != null;

  /// Tüm oyun verilerini temizler.
  ///
  /// DİKKAT: Bu işlem geri alınamaz!
  static Future<void> clearAll() async {
    final keys = _prefs?.getKeys().where((k) => k.startsWith('dh_')) ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }
}
