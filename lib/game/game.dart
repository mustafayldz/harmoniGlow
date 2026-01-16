/// ============================================================================
/// GAME MODULE - Barrel Export
/// ============================================================================
///
/// Bu dosya, game modülünün tüm public API'sini dışa aktarır.
/// Diğer modüller sadece bu dosyayı import ederek tüm game
/// fonksiyonalitesine erişebilir.
///
/// ## Kullanım
///
/// ```dart
/// import 'package:drumly/game/game.dart';
///
/// // Artık tüm game sınıflarına erişebilirsiniz
/// final screen = DrumHeroScreen();
/// ```
///
/// ## Modül Yapısı - V2 (Modernized)
///
/// ```
/// game/
/// ├── core/
/// │   ├── constants/    # GameConstants
/// │   ├── enums/        # Difficulty, GameState
/// │   └── services/     # DeviceProfile, LayoutService
/// │
/// ├── domain/
/// │   ├── entities/     # PadSpec, NoteEvent, ScheduledNote, HitWindows, HitResult
/// │   ├── controllers/  # GameController, InputController, ScoreController, TimingController
/// │   └── services/     # DrumAudioService, BeatGeneratorService, BeatClock, PatternGenerator
/// │
/// ├── presentation/
/// │   ├── components/   # CircleLaneComponent, ModernUI, ParticleEffects
/// │   └── game/         # DrumGame (Flame game)
/// │
/// ├── data/
/// │   └── repositories/ # LocalStorageRepository
/// ```
/// │   └── repositories/ # LocalStorageRepository
/// ============================================================================
library;

// =============================================================================
// CORE - Temel sabitler ve servisler
// =============================================================================

/// Oyun sabitleri: renkler, hızlar, süre, puanlar vb.
export 'core/constants/game_constants.dart';

/// Modern renk paleti ve stil sistemi
export 'core/constants/drumly_colors.dart';

/// Typography sistem - text styles
export 'core/constants/drumly_text_styles.dart';

/// Oyun enum'ları: Difficulty, GameState
export 'core/enums/game_enums.dart';

/// Oyun metinleri için yerelleştirme sınıfı
export 'core/localizations/game_localizations.dart';

/// Cihaz profili ve responsive hesaplamalar
export 'core/services/device_profile.dart';
export 'core/services/layout_service.dart';

/// Object pooling sistemi (FAZ 5)
export 'core/services/object_pool.dart';

// =============================================================================
// DOMAIN - İş mantığı (Entities, Controllers, Services)
// =============================================================================

// Entities
/// Drum pad tanımı (daire bazlı hit detection)
export 'domain/entities/pad_spec.dart';

/// Beat generator'dan gelen ham nota olayı
export 'domain/entities/note_event.dart';

/// Spawn zamanı hesaplanmış nota
export 'domain/entities/scheduled_note.dart';

/// MS bazlı timing judgement pencereleri
export 'domain/entities/hit_windows.dart';

/// Hit result ve quality
export 'domain/entities/hit_result.dart';

// Controllers (FAZ 0)
/// Ana oyun kontrolcüsü
export 'domain/controllers/game_controller.dart';

/// Input kontrolcüsü (tap to lane)
export 'domain/controllers/input_controller.dart';

/// Skor kontrolcüsü
export 'domain/controllers/score_controller.dart';

/// Timing kontrolcüsü
export 'domain/controllers/timing_controller.dart';

// Services
/// Ses servisi (drum sesleri)
export 'domain/services/drum_audio_service.dart';

/// Beat generator servisi (V2 - Pattern based)
export 'domain/services/beat_generator_service.dart';

/// Beat clock (BPM bazlı timing)
export 'domain/services/beat_clock.dart';

/// Pattern generator (müzikal drum patterns)
export 'domain/services/pattern_generator.dart';
// =============================================================================
// PRESENTATION - UI ve Component'ler
// =============================================================================

// Components
/// Düşen nota diski component'i
export 'presentation/components/note_component.dart';

/// Menü butonu component'i
export 'presentation/components/menu_button_component.dart';

/// Circle lane component (FAZ 3)
export 'presentation/components/circle_lane_component.dart';

/// Hit feedback ring - expanding animation (FAZ 3)
export 'presentation/components/hit_feedback_ring.dart';

/// Floating hit text - Perfect/Good/Miss feedback (FAZ 5)
export 'presentation/components/floating_hit_text.dart';

/// Neon button component - Modern UI buttons (FAZ 4)
export 'presentation/components/neon_button.dart';

/// Modern UI components (FAZ 4)
export 'presentation/components/modern_ui_components.dart';

/// Particle effects (FAZ 5)
export 'presentation/components/particle_effects.dart';

// Overlays (FAZ 4)
/// Game over overlay - Modern glassmorphism screen
export 'presentation/overlays/game_over_overlay.dart';

/// Pause overlay - Modern pause menu
export 'presentation/overlays/pause_overlay.dart';

// Game
/// Ana Flame oyun sınıfı
export 'presentation/game/game.dart';

// =============================================================================
// DATA - Veri katmanı
// =============================================================================

/// Local storage (SharedPreferences) wrapper
export 'data/repositories/local_storage_repository.dart';

// =============================================================================
// SCREEN - Flutter widget
// =============================================================================

/// Oyunu barındıran Flutter ekranı (Android geri tuşu desteği ile)
export 'drum_hero_screen.dart';

