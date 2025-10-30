#!/bin/bash

# 🎯 Drumly Güvenlik Kontrol Scripti
# Bu script hassas dosyaların Git'e commit edilmediğini kontrol eder

echo "🔍 Güvenlik Kontrolleri Yapılıyor..."
echo ""

ERRORS=0

# 1. .env dosyası kontrolü
if git ls-files --error-unmatch .env 2>/dev/null; then
    echo "❌ HATA: .env dosyası Git'te tracked!"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ .env dosyası güvenli (untracked)"
fi

# 2. key.properties kontrolü
if git ls-files --error-unmatch android/key.properties 2>/dev/null; then
    echo "❌ HATA: android/key.properties dosyası Git'te tracked!"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ android/key.properties güvenli (untracked)"
fi

# 3. Keystore dosyaları kontrolü
if git ls-files --error-unmatch android/app/*.jks 2>/dev/null; then
    echo "❌ HATA: Keystore dosyaları Git'te tracked!"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Keystore dosyaları güvenli (untracked)"
fi

# 4. google-services.json kontrolü
if git ls-files --error-unmatch android/app/google-services.json 2>/dev/null; then
    echo "❌ HATA: google-services.json Git'te tracked!"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ google-services.json güvenli (untracked/removed)"
fi

# 5. Eski firebase_options.dart kontrolü
if [ -f "lib/firebase_options.dart" ]; then
    if grep -q "AIzaSy" lib/firebase_options.dart 2>/dev/null; then
        echo "⚠️  UYARI: lib/firebase_options.dart hala hardcoded keys içeriyor!"
        echo "   Lütfen lib/firebase_options_secure.dart kullanın"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 6. .env dosyasının varlığı kontrolü
if [ ! -f ".env" ]; then
    echo "⚠️  UYARI: .env dosyası bulunamadı!"
    echo "   Lütfen .env.example dosyasından oluşturun"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ .env dosyası mevcut"
fi

# 7. Örnek dosyaların varlığı
if [ -f ".env.example" ] && [ -f "android/key.properties.example" ]; then
    echo "✅ Örnek dosyalar mevcut"
else
    echo "⚠️  UYARI: Örnek dosyalar eksik"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ]; then
    echo "✅ TÜM GÜVENLİK KONTROLLERİ BAŞARILI!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo "❌ $ERRORS GÜVENLIK SORUNU BULUNDU!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Düzeltme için:"
    echo "  git rm --cached <dosya_adi>"
    echo "  git commit -m 'Remove sensitive files'"
    exit 1
fi
