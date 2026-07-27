# 🥁 Drumly - Modern Drum Training App

<div align="center">
  <h3>Smart Drum Learning Platform</h3>
</div>

## 📱 Proje Hakkında

Drumly, Bluetooth bağlantılı davul seti ile çalışan, modern ve interaktif bir davul eğitim uygulamasıdır.

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / Xcode
- Firebase Account
- AdMob Account

### 🔐 Güvenlik Kurulumu (ÖNEMLİ!)

**İlk adım olarak [SECURITY_SETUP.md](SECURITY_SETUP.md) dosyasını mutlaka okuyun!**

Uygulama hassas bilgileri environment variables ile yönetir:

```bash
# 1. Environment dosyasını oluştur
cp .env.example .env

# 2. .env dosyasını gerçek API keys ile doldur
nano .env

# 3. Android keystore ayarlarını yap
cp android/key.properties.example android/key.properties
nano android/key.properties
```

### 📦 Bağımlılıkları Yükle

```bash
flutter pub get
```

### ▶️ Uygulamayı Çalıştır

```bash
# Development mode (test AdMob ID'leri ile)
flutter run --dart-define-from-file=.env

# Production build
flutter build apk --dart-define-from-file=.env --release
```

## 🏗️ Proje Yapısı

```
lib/
├── adMob/              # AdMob reklam servisleri
├── blocs/              # State management (Bloc)
├── hive/               # Local database
├── models/             # Data models
├── provider/           # Provider state management
├── screens/            # UI ekranları
├── services/           # API servisleri
├── shared/             # Paylaşılan komponenler
├── widgets/            # Custom widget'lar
├── env.dart            # Environment variables
├── firebase_options_secure.dart  # Güvenli Firebase config
└── main.dart           # Entry point
```

## 🔑 Özellikler

- ✅ Bluetooth davul bağlantısı
- ✅ Real-time beat tracking
- ✅ Interaktif eğitim modları
- ✅ Şarkı kütüphanesi
- ✅ Beat maker
- ✅ Performans analizi
- ✅ Firebase Authentication
- ✅ Push notifications
- ✅ AdMob entegrasyonu

## 🛡️ Güvenlik

Bu proje hassas bilgileri korumak için environment variables kullanır. Detaylı bilgi için [SECURITY_SETUP.md](SECURITY_SETUP.md) dosyasına bakın.

### ❌ Asla Commit Etmeyin

- `.env` dosyası
- `android/key.properties`
- `android/app/*.jks`
- `android/app/google-services.json`
- Keystore şifreleri

## 🧪 Test

```bash
flutter test
```

## 📱 Build

### Android

```bash
flutter build apk --dart-define-from-file=.env --release
flutter build appbundle --dart-define-from-file=.env --release
```

### iOS

```bash
flutter build ios --dart-define-from-file=.env --release
```

## 🌐 API Entegrasyonu

Backend API: `https://drumly-backend.us-central1.run.app/api/v1/`

Endpoints:

- `/users/me` - Kullanıcı profili
- `/songs` - Şarkı kataloğu
- `/users/me/notification-devices` - Bildirim cihazı kaydı
- `/users/me/notifications` - Kullanıcı bildirimleri

## 📄 Lisans

© 2025 Drumly. Tüm hakları saklıdır.

## 👥 İletişim



**Not:** Bu proje profesyonel güvenlik standartları ile geliştirilmiştir. API keys ve hassas bilgiler asla kaynak kodda saklanmaz.

# 🧩 Kilit Fonksiyonlar ve Sınıflar

Proje içindeki ana fonksiyonlar ve önemli sınıflar:

| Sınıf/Fonksiyon                | Açıklama                                 | Dosya/Yol                           |
|--------------------------------|------------------------------------------|-------------------------------------|
| `AppProvider`                  | Uygulama genel state yönetimi            | lib/provider/app_provider.dart      |
| `SongService`                  | Şarkı API işlemleri                      | lib/services/song_service.dart      |
| `SongV2Service`                | Yeni nesil şarkı API işlemleri           | lib/services/songv2_service.dart    |
| `UserService`                  | Kullanıcı işlemleri                      | lib/services/user_service.dart      |
| `FirebaseNotificationService`  | Push notification yönetimi               | lib/services/firebase_notification_service.dart |
| `SongViewModel`                | Şarkı ekranı state yönetimi              | lib/screens/songs/songs_viewmodel.dart |
| `SongV2ViewModel`              | SongsV2 ekranı state yönetimi            | lib/screens/songs/songv2_viewmodel.dart |
| `SongLedPlayer`                | LED'li şarkı oynatıcı widget'ı           | lib/widgets/song_led_player.dart    |
| `AdService`                    | AdMob reklam yönetimi                    | lib/adMob/ad_service.dart           |
| `StorageService`               | Local storage işlemleri                  | lib/services/local_service.dart     |
| `NotificationHandler`          | Bildirim routing ve yönetimi             | lib/services/notification_handler.dart |
| `VersionControlService`        | Sürüm kontrol ve güncelleme              | lib/services/version_control_service.dart |
| `DrumPainter`                  | Davul görsel çizimi                      | lib/screens/my_drum/drum_painter.dart |

Tüm fonksiyonlar ve class'lar için ilgili dosyaları inceleyebilirsiniz. Daha fazla detay için kodun ilgili kısmına bakınız.
