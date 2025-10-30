# 🔐 Drumly - Güvenlik Kurulum Rehberi

## ⚠️ ÖNEMLİ: İlk Kurulum

Bu proje hassas bilgileri environment variables ile yönetir. Çalıştırmadan önce aşağıdaki adımları tamamlayın.

## 1️⃣ Environment Variables Kurulumu

### `.env` Dosyası Oluşturun

```bash
cp .env.example .env
```

### `.env` Dosyasını Düzenleyin

```bash
# Firebase Configuration (Firebase Console'dan alın)
FIREBASE_ANDROID_API_KEY=AIzaSy...
FIREBASE_IOS_API_KEY=AIzaSy...
FIREBASE_PROJECT_ID=drumly-mobile
FIREBASE_MESSAGING_SENDER_ID=914876532693
FIREBASE_APP_ID_ANDROID=1:914876532693:android:...
FIREBASE_APP_ID_IOS=1:914876532693:ios:...
FIREBASE_STORAGE_BUCKET=drumly-mobile.firebasestorage.app

# AdMob Configuration (AdMob Console'dan alın)
ADMOB_BANNER_ANDROID=ca-app-pub-8628075241374370/2951126614
ADMOB_BANNER_IOS=ca-app-pub-8628075241374370/2832782514
ADMOB_REWARDED_ANDROID=ca-app-pub-8628075241374370/5569852413
ADMOB_REWARDED_IOS=ca-app-pub-8628075241374370/7819469591
```

## 2️⃣ Android Keystore Kurulumu

### `android/key.properties` Dosyası Oluşturun

```bash
cp android/key.properties.example android/key.properties
```

### Gerçek Değerlerle Doldurun

```properties
storePassword=GERÇEK_ŞIFRE
keyPassword=GERÇEK_ŞIFRE
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

## 3️⃣ Uygulamayı Çalıştırma

### Development (Test AdMob ID'leri ile)

```bash
flutter run --dart-define-from-file=.env
```

### Production Build

```bash
# Android
flutter build apk --dart-define-from-file=.env --release

# iOS
flutter build ios --dart-define-from-file=.env --release
```

## 🚫 ASLA GIT'E COMMIT ETMEYİN

Aşağıdaki dosyalar `.gitignore`'da ekli:

- ❌ `.env` (sadece `.env.example` commit edilmeli)
- ❌ `android/key.properties`
- ❌ `android/app/*.jks`
- ❌ `android/app/google-services.json`
- ❌ `lib/firebase_options.dart` (eski dosya)

## 🔒 Güvenlik Kontrol Listesi

- [ ] `.env` dosyası oluşturuldu ve gerçek değerler eklendi
- [ ] `android/key.properties` oluşturuldu
- [ ] `.gitignore` kontrol edildi
- [ ] Eski `lib/firebase_options.dart` dosyası silindi
- [ ] Git history'den hassas dosyalar temizlendi (aşağıya bakın)

## 🧹 Git History Temizleme

Eğer hassas bilgiler daha önce commit edildiyse:

```bash
# Git cache'i temizle
git rm --cached android/key.properties
git rm --cached android/app/google-services.json
git rm --cached lib/firebase_options.dart

# Commit et
git add .gitignore
git commit -m "🔒 Security: Remove sensitive files and add .gitignore rules"

# Git history'den tamamen sil (opsiyonel ama önerilen)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch android/key.properties android/app/google-services.json" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (dikkatli olun!)
git push origin --force --all
```

## 📱 CI/CD Kurulumu

GitHub Actions, GitLab CI veya benzeri kullanıyorsanız:

1. Repository Secrets'a environment variables ekleyin
2. Build script'lerinizde `--dart-define-from-file` kullanın
3. Keystore dosyasını base64 encode ederek secrets'a ekleyin

### GitHub Actions Örneği

```yaml
- name: Create .env file
  run: |
    echo "FIREBASE_ANDROID_API_KEY=${{ secrets.FIREBASE_ANDROID_API_KEY }}" >> .env
    echo "FIREBASE_IOS_API_KEY=${{ secrets.FIREBASE_IOS_API_KEY }}" >> .env
    # ... diğer secrets

- name: Build APK
  run: flutter build apk --dart-define-from-file=.env --release
```

## 🆘 Sorun mu Yaşıyorsunuz?

### "Environment variable not found" Hatası

```bash
# .env dosyasının var olduğundan emin olun
ls -la .env

# Doğru format ile çalıştırın
flutter run --dart-define-from-file=.env
```

### AdMob Test ID'leri Görünüyor

Development modunda test ID'leri varsayılan olarak gelir. Production build için gerçek ID'leri `.env`'e ekleyin.

## 📞 İletişim

Güvenlik sorunları için: [security@drumly.com](mailto:security@drumly.com)

---

**Son Güncelleme:** 30 Ekim 2025
