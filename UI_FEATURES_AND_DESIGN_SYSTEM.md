# 🎨 Drumly App - UI Özellikleri ve Tasarım Sistemi

## 📱 Proje Özeti

**Proje Adı:** Drumly (harmoniGlow)  
**Tür:** Flutter Müzik Eğitim Uygulaması  
**Slogan:** "Light Up Your Beat"  
**Dil:** Dart, Flutter 3.5.4+  
**Temel Kütüphaneler:** Flame (Oyun Motoru), Provider, Firebase, AdMob

---

## 🎯 Ana Ekranlar ve Özellikler

### 1. **Splash Screen** (`/splash`)
**Dosya:** `lib/screens/splash/splash.dart`

- **Amaç:** Uygulamayı başlatırken başlatma ekranı göstermek
- **Özellikleri:**
  - Lottie animasyon ile logo gösterimi
  - Hive database başlatma
  - Firebase Messaging konfigürasyonu
  - Kullanıcı yetkilendirme kontrolü
  - Otomatik yönlendirme (Auth veya Home'a)
- **Tasarım:** Minimal, çok hafif animasyon
- **UX:** Kullanıcı etkileşimi olmadan otomatik ilerliyor

---

### 2. **Kimlik Doğrulama (Auth)** (`/auth`)
**Dosya:** `lib/screens/auth/auth_view.dart` + `auth_viewmodel.dart`

- **Amaç:** Kullanıcı giriş/kaydı işlemleri
- **Özellikleri:**
  - Email/Password giriş formu
  - Google/Apple Sign-in (Firebase Auth)
  - Şifre sıfırlama
  - Yeni hesap oluşturma
  - Form validasyonu
  - Loading state göstericileri
- **Tasarım:**
  - Modern gradient background
  - Responsive input fields
  - Dark/Light mode desteği
  - Hata mesajları ve başarı göstergeleri
- **Renkler:**
  - Arka plan: Gradient (Dark: #0F172A → #334155)
  - Input: #2E2E2E (Dark) / #F2F2F2 (Light)
  - Button: #0066FF veya Siyah

---

### 3. **Anasayfa (Home)** (`/home`)
**Dosya:** `lib/screens/home/home_view.dart` + `home_viewmodel.dart`  
**Components:** 
- `modern_app_bar.dart` - Modern başlık çubuğu
- `home_cards_grid.dart` - Özellik kartları
- `modern_card.dart` - Tekli kart widget
- `promotion_card.dart` - Promosyon kartı
- `bluetooth_banner.dart` - Bluetooth bağlantı durumu
- `notification_button.dart` - Bildirim butonu

- **Amaç:** Ana navigasyon merkezi ve ana menü
- **Özellikleri:**
  - **Modern App Bar:** 
    - Kullanıcı adı/email gösterimi
    - Bluetooth bağlantı durumu
    - Bildirim butonu
    - Saatı gösteren saat widget
  - **Özellik Kartları (Grid Layout):**
    - 🎓 **Training** (Eğitim) - Yeşil (#22C55E)
    - 🎵 **Songs** (Şarkılar) - Pembe (#EC4899)
    - 🥁 **My Drum** (Davulum) - Mavi (#3B82F6)
    - ⚙️ **Settings** (Ayarlar) - Kırmızı (#EF4444)
    - 🎮 **Drum Hero** (Oyun) - Mor
  - **Promosyon Kartı:** Yeni özellikleri tanıtma
  - **Bluetooth Banner:** Bağlı cihaz adı ve durum
  - **Animasyonlar:** Fade-in ve slide animations
- **Tasarım:**
  - CustomScrollView ile SliverList
  - Gradient background
  - İkon + Metin kombinasyonu
  - Tap animasyonları
  - Firebase Analytics entegrasyonu
- **UX Akışı:**
  1. App Bar yükleniyor
  2. Promosyon kartı fade-in
  3. Özellik kartları sequential animasyon
  4. Tap → Navigation işlemi

---

### 4. **Bluetooth Cihaz Bulma** (`/findDevices`)
**Dosya:** `lib/screens/bluetooth/find_devices_view.dart` + `find_device_viewmodel.dart`

- **Amaç:** Bluetooth drum pad cihazlarını tarama ve bağlanma
- **Özellikleri:**
  - Bluetooth tarama başlatma/durma
  - Bulunmuş cihazlar listesi
  - İşaret gücü (RSSI) gösterimi
  - Cihaz bağlanma işlevi
  - Bağlantı durumu gösterimi
- **Tasarım:**
  - ListView ile cihaz listesi
  - Her cihaz: Ad, adres, RSSI göstergesi
  - Yeşil (#34D399) action button
  - Loading spinner
- **Workflow:** Tara → Bağlan → Home'a dön

---

### 5. **Şarkılar** (`/songsv2`)
**Dosya:** `lib/screens/songs/songv2_view.dart` + `songv2_viewmodel.dart`

- **Amaç:** Müzik şarkılarını görmek ve seçmek
- **Özellikleri:**
  - **Arama Çubuğu:** Şarkı adı/sanatçı araması
  - **Grid/List View Toggle:** Görünüm değiştirme
  - **Şarkı Kartları:**
    - Kapak resmi
    - Başlık, sanatçı, zorluk seviyesi
    - Kilit durumu (Locked/Unlocked)
    - Tamamlanma yüzdesi (Progress bar)
    - Derecelendirme (Stars)
  - **Kategorileme:** Zorluk seviyelerine göre filtreleme
  - **Confetti Animasyonu:** Şarkı bitişinde
- **Tasarım:**
  - Responsive grid (1-2 columns screen size'a göre)
  - Kapak resimleri yüksek çözünürlük
  - Glow effect (opsiyonel)
  - Scroll physics: Bouncing
- **İşlevler:**
  - Şarkı seç → Player'a yönlendir
  - Kilitsiz şarkılar maviye, kilitliler griye
  - Arama debounce (performans)

---

### 6. **Şarkı Çalar** (`/player`)
**Dosya:** `lib/screens/player/songv2_player_view.dart`

- **Amaç:** Seçilen şarkıyı çalmak ve Bluetooth pad'e kontrol sinyalleri göndermek
- **Özellikleri:**
  - **Falling Notes Animasyonu:** Müzik notaları ekrandan aşağıya düşüyor
  - **Drum Pad Görsel Representation:** 8 drum (Hi-Hat, Crash, Ride, Snare, Tom 1-2, Tom Floor, Kick)
  - **Touch/Tap Detection:** Doğru zamanda drum pad'e tıklama
  - **Score Sistemi:**
    - Perfect, Good, OK, Miss skorları
    - Combo sayacı
    - Toplam score göstericisi
  - **Timing Göstergesi:** Doğru zamanda vuru yapma derecesi
  - **Bluetooth Kontrol:** Tap atıldığında Bluetooth sinyali gönderme
  - **Audio Offset:** Sincronizasyon ayarı
  - **Speed Control:** Hız ayarı (slow-down)
- **Tasarım:**
  - Full-screen responsive layout
  - Drum pad'ler alttan sıralı
  - Notes falling from top
  - Hit zone indicators
  - Real-time score display
  - Glow effects, neon colors
- **UX:**
  - Countdown overlay (başlangıç)
  - Pause overlay (ara ver)
  - Game over overlay (bitişte sonuçlar)
  - Confetti animation (başarılı bitişte)

---

### 7. **Drum Ayarları / My Drum** (`/my_drum`)
**Dosya:** `lib/screens/my_drum/drum_adjustment.dart`  
**Components:** 
- `drum_painter.dart` - Modern davul görselleştirmesi
- `drum_painter_classic.dart` - Klasik görüş
- `drum_adjustment.dart` - Ana kontrol ekranı

- **Amaç:** Bluetooth pad renglerini ve ayarlarını özelleştirmek
- **Özellikleri:**
  - **Davul Görselleştirmesi:** 8 drum parçası
  - **Renk Seçimi:** 
    - Flex color picker entegrasyonu
    - RGB değer düzenleme
    - Preset renkler
  - **Modern/Klasik Görüş:** İki farklı temel görselleştirme
  - **Tap to Test:** Her drum parçasını test etmek
  - **Bluetooth Gönderme:** RGB değerlerini pad'e sende etme
  - **Local Storage:** Seçimi Hive DB'de kaydetme
- **Davul Parçaları & Varsayılan Renkler:**
  1. Hi-Hat → Kırmızı (220, 0, 0)
  2. Crash Cymbal → Pastel (208, 151, 154)
  3. Ride Cymbal → Turuncu (255, 125, 0)
  4. Snare Drum → Yeşil (7, 219, 2)
  5. Tom 1 → Turkuaz (0, 212, 154)
  6. Tom 2 → Mavi (21, 25, 207)
  7. Tom Floor → Mor (235, 0, 255)
  8. Kick Drum → Sarı (242, 255, 0)
- **Tasarım:**
  - CustomPaint widget ile vektörel davul çizimi
  - Renkler gerçek zamanda güncelleniyor
  - Soft shadow, anti-aliasing
  - Light/Dark theme desteği

---

### 8. **Eğitim / Training** (`/training`)
**Dosya:** `lib/screens/training/traning_view.dart` + `traning_viewmodel.dart`

- **Amaç:** Başlangıç seviyesi davul eğitimi veya farklı zorluk seviyeleri
- **Özellikleri:**
  - **Tab Sistemi:** Beginner, Intermediate, Advanced tabs
  - **Egzersiz Listesi:** Seviye başına birden fazla egzersiz
  - **Her Egzersiz:**
    - Başlık
    - Açıklama
    - Zorluk göstergesi
    - Başla butonu
    - Tamamlanma durumu
  - **Progress Tracking:** Tamamlanan egzersizleri işaretleme
- **Tasarım:**
  - Modern tab bar (custom)
  - Card-based exercises
  - Gradient background
  - Color-coded difficulty (green/yellow/red)
- **UX:** Egzersiz seç → Player'a git

---

### 9. **Eğitim / Drum Hero Oyunu** (`/drum-hero`)
**Dosya:** `lib/game/drum_hero_screen.dart`

- **Amaç:** Falling notes oyunu şeklinde interaktif davul eğitimi
- **Teknoloji:** Flame game engine
- **Özellikleri:**
  - **Falling Notes:** Müzik ritmine göre notalar düşüyor
  - **Touch Input:** Notaları tap ederek vuruş yapma
  - **Score Sistemi:** Perfect/Good/OK/Miss
  - **Combo System:** Ardışık doğru vuruşlar
  - **Game Over Screen:** Sonuç özeti
  - **Debug Mode:** Pad alanlarını gösterme (geliştirme için)
  - **Performance Mode:** Glow efektlerini kapatma
- **Overlay'ler:**
  - Game Over Overlay (Puanlar, Restart, Ev)
  - Pause Overlay (Devam, Çık)
- **Renkler:**
  - Neon/Glow effects
  - Her drum parçası kendi rengi
  - Dark background (#0F172A)
- **UX:** Intro countdown → Oyun oynanıyor → Game Over → Menu

---

### 10. **Şarkı İsteği** (`/song-request`)
**Dosya:** `lib/screens/song_request/song_request_page.dart`

- **Amaç:** Kullanıcıların yeni şarkıları talep etmesi
- **Özellikleri:**
  - **Form Alanları:**
    - Şarkı Adı
    - Sanatçı
    - Tür (Genre)
    - Yayın Yılı
    - Dil
    - Açıklama (notes)
  - **Form Validasyonu:** Zorunlu alanlar
  - **Gönderme:** Firebase'e kaydetme
  - **Success Message:** Başarılı gönderi mesajı
- **Tasarım:**
  - Modern gradient background
  - Clean input fields
  - Submit button
  - Custom app bar
- **UX:** Doldur → Gönder → Başarı mesajı → Ana sayfaya dön

---

### 11. **Talep Edilen Şarkılar** (`/requested-songs`)
**Dosya:** `lib/screens/requested_songs/requested_songs_page.dart`

- **Amaç:** Kullanıcı tarafından talep edilen şarkılar listesini görmek
- **Özellikleri:**
  - Şarkı isteği listesi
  - Durum göstergesi (Pending, In Progress, Completed)
  - Talep tarihini gösterme
  - Her talep seçilince detayları görmek
- **Tasarım:** ListView/Grid
- **UX:** Liste → Detay görünümü (opsiyonel)

---

### 12. **Bildirimler** (`/notifications`)
**Dosya:** `lib/screens/notifications/notification_view.dart`

- **Amaç:** Push bildirimleri ve uygulama içi mesajları görmek
- **Özellikleri:**
  - **Bildirim Listesi:** En yeni bildirimler üstte
  - **Bildirim Kartları:**
    - Başlık
    - Mesaj
    - Tarih/Saat
    - Sil butonu
    - Okundu/Okunmadı göstergesi
  - **Max Limit:** Maks 50 bildirim saklanması
  - **Empty State:** Bildirim yoksa özel mesaj
  - **Sayaç:** "X/Y bildirim" gösterimi
- **Tasarım:**
  - CustomScrollView
  - Gradient background
  - Modern app bar
  - Card-based notifications
- **Kaynak:**
  - Firebase Cloud Messaging
  - Local notifications
  - Custom notification handler

---

### 13. **Ayarlar** (`/settings`)
**Dosya:** `lib/screens/settings/setting_view.dart` + `settings_viewmodel.dart`

- **Amaç:** Uygulama ayarları ve kullanıcı bilgisi yönetimi
- **Özellikleri:**
  - **Profil Bölümü:**
    - Kullanıcı avatarı
    - Ad/Email
    - Profil düzenleme (Name, Bio)
  - **Hesap Bilgisi:**
    - Toplam şarkı sayısı
    - Bağlı cihazlar
    - Giriş tarihi
  - **Ayarlar:**
    - **Görüntü:** Dark/Light mode toggle
    - **Ses:** Ses efektleri, müzik ses seviyesi
    - **Bluetooth:** Bağlı cihaz yönetimi
    - **Dil:** Çok dil desteği (en, tr, ru, es, fr)
    - **Bildirimler:** Push bildiri tercihləri
  - **Hakkında:**
    - Versiyon numarası
    - Build number
    - Lisans bilgisi
  - **İşlemler:**
    - Şifremi değiştir
    - Hesabı sil
    - Çıkış

- **Tasarım:**
  - CustomScrollView
  - Section-based layout
  - Modern cards
  - Expandable profile header
  - Toggle switches
  - Radio buttons
- **Renkler:** Ayar kategorisine göre degradeli kartlar

---

## 🎨 Tasarım Sistemi

### Renk Paleti

#### **Temel Renkler (Modern Palette)**
```dart
Primary        → #6366F1 (Indigo)
Primary Dark   → #4F46E5
Secondary      → #8B5CF6 (Violet)  
Secondary Dark → #7C3AED
Accent         → #06B6D4 (Cyan)
Accent Dark    → #0891B2
Success        → #10B981 (Green)
Success Dark   → #059669
Warning        → #F59E0B (Amber)
Warning Dark   → #D97706
Error          → #EF4444 (Red)
Error Dark     → #DC2626
```

#### **Tema Renkleri (Dark Mode)**
```dart
Background 1   → #0F172A (Darkest)
Background 2   → #1E293B (Dark)
Background 3   → #334155 (Medium)
Surface        → #475569 (Surface)
Text           → #FFFFFF (White)
Text Secondary → FFFFFF 80% opacity
Border         → #FFFFFF 20% opacity
```

#### **Tema Renkleri (Light Mode)**
```dart
Background 1   → #F8FAFC (Lightest)
Background 2   → #E2E8F0 (Light)
Background 3   → #CBD5E1 (Medium)
Surface        → #94A3B8 (Surface)
Text           → #000000 (Black)
Text Secondary → #000000 80% opacity
Border         → #000000 20% opacity
```

#### **Özel Renkler (Features)**
```dart
Emerald        → #34D399 (Bluetooth, Primary Action)
Rose           → #FB7185 (Notification Badge)
Training       → #22C55E (Green)
Songs          → #EC4899 (Pink)
My Drum        → #3B82F6 (Blue)
Settings       → #EF4444 (Red)
Drum Lighting  → Özel RGB (Hi-Hat, Crash, vb.)
```

### Gradient Sistemi

#### **Background Gradients**
- **Dark Mode:** Top-left to bottom-right
  ```
  #0F172A → #1E293B → #334155
  ```
- **Light Mode:** Top-left to bottom-right
  ```
  #F8FAFC → #E2E8F0 → #CBD5E1
  ```

#### **Card Gradients**
- **Primary Card:** Indigo
- **Secondary Card:** Violet
- **Accent Card:** Cyan
- **Success Card:** Green
- **Warning Card:** Amber
- **Error Card:** Red

### Tipografi

#### **Font Families**
- **Default:** System font (Roboto - Android, SF Pro - iOS)
- **Monospace:** 'monospace' (LED değerleri için)

#### **Font Sizes**
- **Başlık (H1):** 32px, Bold
- **Başlık (H2):** 28px, Bold
- **Başlık (H3):** 24px, Bold
- **Gövde Büyük:** 18px, Medium
- **Gövde Normal:** 16px, Regular
- **Gövde Küçük:** 14px, Regular
- **Label:** 12px, Medium
- **Hint:** 12px, Regular (Opacity 60%)

#### **Font Weights**
- **Bold:** 700
- **SemiBold:** 600
- **Medium:** 500
- **Regular:** 400

### Shadow Sistemi (ModernShadows)

```dart
Small:   blurRadius: 8, offset: (0, 2)
Medium:  blurRadius: 12, offset: (0, 4)
Large:   blurRadius: 16, offset: (0, 6)
ExtraLarge: blurRadius: 20, offset: (0, 8)
```

### Spacing System

```dart
4px   → XSmall gap
8px   → Small gap (default padding)
12px  → Medium gap
16px  → Large gap (page padding)
20px  → XLarge gap
24px  → 2XLarge gap
32px  → 3XLarge gap
```

### Border Radius

```dart
8px    → Small buttons, input
12px   → Cards, containers
16px   → Large containers
20px   → Dialogs
24px   → Full cards, glass effects
100px  → Circular (avatars, badges)
```

### Animasyonlar

#### **Durations**
- **Quick:** 100-200ms (micro-interactions)
- **Normal:** 300-400ms (standard transitions)
- **Slow:** 600-800ms (entrance animations)
- **Very Slow:** 1000ms+ (special effects)

#### **Kullanılan Animasyonlar**
- **Fade In/Out:** Ekranlar, kartlar
- **Slide Transition:** Navigation, bottom sheets
- **Scale Animation:** Buttons, cards (tap)
- **Rotation:** Loading spinners
- **Custom Curves:** Easing functions (Ease, EaseOut, vb.)
- **Lottie Animations:** Splash screen, success states
- **Confetti:** Başarılı oyun bitişi

---

## 📐 Responsive Design

### Breakpoints

```dart
XSmall  (Phone)   → 320px - 480px
Small   (Phone)   → 480px - 600px
Medium  (Tablet)  → 600px - 840px
Large   (Tablet)  → 840px - 1200px
XLarge  (Desktop) → 1200px+
```

### Adaptation Strategy

- **Phone (< 600px):**
  - Single column layouts
  - Full-width cards
  - Bottom navigation
  - Vertical scrolling

- **Tablet (600px - 1200px):**
  - 2-column grids
  - Side navigation
  - Optimized spacing
  - Landscape support

- **Desktop (> 1200px):**
  - Multi-column layouts
  - Side panel navigation
  - Full-size widgets

---

## 🎮 Game Visual Assets

### Drum Kit Visual
- **8 Pad Layout:** Alttan sıralı düzenleme
- **Shape:** Kare veya dairesel
- **Lighting:** LED simülasyonu, glow effect
- **Interaction:** Tap bölgeleri göstergesi

### Falling Notes
- **Şekil:** Kare veya çember
- **Renkler:** Drum parçasının rengi
- **Animasyon:** Düşme (top → bottom)
- **Timing Göstergesi:** Hit zone'a girmek
- **Visual Feedback:** Başarı animasyonları (particle, glow)

---

## 🌍 Çok Dil Desteği

- **English** (en)
- **Turkish** (tr)
- **Russian** (ru)
- **Spanish** (es)
- **French** (fr)

**Implementasyon:** easy_localization package  
**Asset Konum:** `assets/langs/`

---

## 🔔 Bildirim Sistemi

### Push Notifications
- **Firebase Cloud Messaging (FCM)** entegrasyonu
- **Local Notifications** (flutter_local_notifications)
- **Custom notification handler**

### Notification Types
1. **Song Available:** Talep edilen şarkı hazır
2. **Feature Update:** Yeni özellik duyurusu
3. **Challenge:** Günlük/haftalık zorluk
4. **Friend Activity:** (Gelecek özellik)

---

## 📊 State Management

- **Provider:** UI state, user data, app settings
- **Bloc:** Bluetooth connectivity
- **Hive:** Local storage (drum colors, user preferences)
- **Firebase:** Cloud storage, authentication

---

## ♿ Accessibility Features

- **Text Scaling:** Sistem ayarlarına uyum
- **High Contrast Mode:** Desteği
- **Screen Reader Support:** Semantic labels
- **Touch Target Size:** Min 48x48dp
- **Color Contrast:** WCAG AA standard

---

## 📦 Bağımlılıklar

**UI/Rendering:**
- flutter_blue_plus (Bluetooth)
- flame (Game engine)
- lottie (Animations)
- confetti (Effects)
- flex_color_picker (Color picker)

**State & Data:**
- provider
- flutter_bloc
- hive & hive_flutter
- shared_preferences

**Backend & Services:**
- firebase_core
- firebase_auth
- firebase_analytics
- firebase_messaging
- google_mobile_ads

**Localization & Utilities:**
- easy_localization
- intl
- url_launcher
- path_provider
- just_audio

---

## 🎯 Tasarım Prensipleri

1. **Modern Minimal:** Temiz, sade arayüz
2. **Dark-First:** Dark mode varsayılan, light mode desteği
3. **Glass Morphism:** Yarı saydam efektler
4. **Responsive First:** Mobil öncelikli tasarım
5. **Accessibility:** Herkes için erişilebilir
6. **Performance:** Smooth 60 FPS animasyonları
7. **Consistency:** Tekrarlanan pattern ve bileşenler
8. **Feedback:** Her aksiyon için görsel yanıt

---

## 🚀 Yeni Tasarımda Kullanılacak Bilgiler

### Tasarım Sabitler
```dart
// Color
const primaryColor = Color(0xFF6366F1);
const darkBg1 = Color(0xFF0F172A);
const darkBg2 = Color(0xFF1E293B);

// Spacing
const defaultPadding = 16.0;
const defaultRadius = 12.0;

// Animation
const defaultDuration = Duration(milliseconds: 300);
```

### İçerik Grid
- **9 Ana Sayfa (Screens)**
- **30+ Reusable Widgets**
- **8 Drum Parçası (Fixed)**
- **5 Dil Desteği**
- **Light + Dark Mode** (2x tasarımlar)

### Görsel Hiyerarşisi
1. **Primary Action:** Indigo (#6366F1)
2. **Secondary Action:** Violet (#8B5CF6)
3. **Tertiary:** Cyan (#06B6D4)
4. **Destructive:** Red (#EF4444)

### Interaction Patterns
- **Tap → Scale 0.95**
- **Swipe ← Dismiss / Navigate**
- **Long Press → Context Menu**
- **Scroll → Momentum, Bouncing**

---

## 📝 Dosya Yapısı

```
lib/
├── screens/
│   ├── auth/              # Auth screen + VM
│   ├── home/              # Home + Components
│   ├── player/            # Song player
│   ├── songs/             # Song list
│   ├── song_request/      # Request form
│   ├── requested_songs/   # Request list
│   ├── training/          # Training exercises
│   ├── my_drum/           # Drum customization
│   ├── settings/          # Settings
│   ├── notifications/     # Notifications list
│   ├── bluetooth/         # Device discovery
│   └── splash/            # Splash screen
├── game/
│   ├── drum_hero_screen.dart
│   ├── game/              # Flame game logic
│   ├── presentation/      # Game UI components
│   │   ├── components/
│   │   ├── game/
│   │   └── overlays/
├── widgets/               # Reusable widgets
├── shared/                # Shared components & utilities
│   ├── modern_components.dart
│   ├── app_gradients.dart
│   └── ...
├── provider/              # State management
├── blocs/                 # Bloc state management
├── services/              # API & external services
├── models/                # Data models
├── hive/                  # Local DB
└── constants.dart         # App constants
```

---

**Güncelleme Tarihi:** 2024-2025  
**Tasarım Felsefesi:** Modern, Dark-first, Accessible, Performant
