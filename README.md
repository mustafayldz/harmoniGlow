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

Backend API: `https://drumly-backend.us-central1.run.app/api/`

Endpoints:

- `/users/` - Kullanıcı yönetimi
- `/songs/` - Şarkı listesi
- `/beats/` - Beat'ler
- `/song-types/` - Şarkı kategorileri

## 📄 Lisans

© 2025 Drumly. Tüm hakları saklıdır.

## 👥 İletişim

- **Güvenlik Sorunları:** security@drumly.com
- **Destek:** support@drumly.com

---

**Not:** Bu proje profesyonel güvenlik standartları ile geliştirilmiştir. API keys ve hassas bilgiler asla kaynak kodda saklanmaz.
