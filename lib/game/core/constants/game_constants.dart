import 'package:flutter/painting.dart';

/// ============================================================================
/// GAME CONSTANTS - Oyun genelinde kullanılan sabitler
/// ============================================================================
///
/// Bu dosya oyunun tüm sabit değerlerini merkezi bir yerde toplar.
/// Renk paleti, lane isimleri, süre ayarları ve UI sabitleri burada tanımlanır.
/// ============================================================================

/// Oyun ayarları ve sabitleri.
///
/// Tüm sabitler static const olarak tanımlanmıştır.
/// Bu sayede compile-time optimization sağlanır ve bellek kullanımı minimize edilir.
abstract final class GameConstants {
  // ===========================================================================
  // LANE (ENSTRÜMAN) AYARLARI
  // ===========================================================================

  /// Toplam lane (enstrüman) sayısı.
  ///
  /// Drum kit üzerindeki 8 farklı vuruş bölgesini temsil eder:
  /// 0-Hi-Hat, 1-Crash, 2-Ride, 3-Snare,
  /// 4-Tom 1, 5-Tom 2, 6-Tom Floor, 7-Kick
  static const int laneCount = 8;

  /// Her lane için renk paleti.
  ///
  /// Index sıralaması lane numarasına karşılık gelir.
  /// Renkler notaların ve flash efektlerinin rengini belirler.
  ///
  /// | Lane | Enstrüman  | Renk       |
  /// |------|------------|------------|
  /// | 0    | Hi-Hat     | Kırmızı    |
  /// | 1    | Crash      | Pembe      |
  /// | 2    | Ride       | Turuncu    |
  /// | 3    | Snare      | Yeşil      |
  /// | 4    | Tom 1      | Turkuaz    |
  /// | 5    | Tom 2      | Mavi       |
  /// | 6    | Tom Floor  | Mor        |
  /// | 7    | Kick       | Sarı       |
  static const List<Color> laneColors = [
    Color(0xFFDC0000), // 0: Hi-Hat
    Color(0xFFD0979A), // 1: Crash
    Color(0xFFFF7D00), // 2: Ride
    Color(0xFF07DB02), // 3: Snare
    Color(0xFF00D49A), // 4: Tom 1
    Color(0xFF1519CF), // 5: Tom 2
    Color(0xFFEB00FF), // 6: Tom Floor
    Color(0xFFF2FF00), // 7: Kick
  ];

  /// Her lane'in okunabilir ismi.
  ///
  /// Debug modunda ve UI'da gösterim için kullanılır.
  static const List<String> laneNames = [
    'Hi-Hat', // Lane 0
    'Crash Cymbal', // Lane 1
    'Ride Cymbal', // Lane 2
    'Snare Drum', // Lane 3
    'Tom 1', // Lane 4
    'Tom 2', // Lane 5
    'Tom Floor', // Lane 6
    'Kick Drum', // Lane 7
  ];

  // ===========================================================================
  // OYUN SÜRESİ AYARLARI
  // ===========================================================================

  /// Bir oyun seansının süresi (saniye).
  ///
  /// Oyun bu süre dolduğunda otomatik olarak biter ve game over ekranına geçer.
  static const double gameDurationSeconds = 60.0;

  // ===========================================================================
  // NOT HIZI AYARLARI (pixel/saniye)
  // ===========================================================================

  /// Kolay modda not düşme hızı (px/s).
  static const double noteSpeedEasy = 180.0;

  /// Orta modda not düşme hızı (px/s).
  static const double noteSpeedMedium = 220.0;

  /// Zor modda not düşme hızı (px/s).
  static const double noteSpeedHard = 260.0;

  // ===========================================================================
  // UI SABİTLERİ
  // ===========================================================================

  /// Arka plan rengi (koyu lacivert).
  static const Color backgroundColor = Color(0xFF0A0A15);

  /// Menü arka plan dekor rengi.
  static const Color menuDecorColor = Color(0xFF1A1A2E);

  /// Hit çizgisi rengi.
  static const Color hitLineColor = Color(0xFF333355);

  /// Progress bar dolduğunda renk (turkuaz).
  static const Color progressBarFullColor = Color(0xFF4ECDC4);

  /// Progress bar azaldığında renk (kırmızı).
  static const Color progressBarLowColor = Color(0xFFFF6B6B);

  /// Progress bar arka plan rengi.
  static const Color progressBarBackgroundColor = Color(0xFF222233);

  // ===========================================================================
  // COMBO VE FEVER AYARLARI
  // ===========================================================================

  /// Fever modunu aktifleştirmek için gereken combo sayısı.
  ///
  /// Her 20 combo'da fever modu 4 saniye aktif olur ve puan x2 olur.
  static const int feverComboThreshold = 20;

  /// Fever modu süresi (saniye).
  static const double feverDurationSeconds = 4.0;

  /// Shield kazanmak için gereken ardışık Perfect sayısı.
  static const int shieldPerfectStreak = 5;

  // ===========================================================================
  // PUAN TABLOSU
  // ===========================================================================

  /// Perfect vuruş puanı.
  static const int pointsPerfect = 100;

  /// Great vuruş puanı.
  static const int pointsGreat = 75;

  /// Good vuruş puanı.
  static const int pointsGood = 50;

  /// OK vuruş puanı.
  static const int pointsOk = 25;

  // ===========================================================================
  // DRUM KIT GÖRSEL AYARLARI
  // ===========================================================================

  /// Drum kit görseli aspect ratio (genişlik / yükseklik).
  ///
  /// drum_kit.jpg dosyası 1024x559 piksel boyutundadır.
  static const double drumKitAspectRatio = 1024.0 / 559.0;

  /// Drum flash efekti süresi (saniye).
  static const double drumFlashDuration = 0.15;
}
