#!/bin/bash

# 🔒 Git History Cleaner Script
# Bu script hassas dosyaları Git geçmişinden tamamen siler

echo "⚠️  DİKKAT: Bu işlem Git history'yi değiştirecek!"
echo "Devam etmeden önce backup aldığınızdan emin olun."
echo ""
read -p "Devam etmek istiyor musunuz? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "🧹 Git history temizleniyor..."

# BFG Repo-Cleaner kullanımı (önerilen)
# Kurulum: brew install bfg
if command -v bfg &> /dev/null
then
    echo "✅ BFG bulundu, hızlı temizleme yapılıyor..."
    bfg --delete-files google-services.json
    bfg --delete-files key.properties
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
else
    echo "⚠️  BFG bulunamadı, git filter-branch kullanılıyor (yavaş)..."
    
    # Git filter-branch ile temizleme
    git filter-branch --force --index-filter \
      'git rm --cached --ignore-unmatch android/app/google-services.json android/key.properties' \
      --prune-empty --tag-name-filter cat -- --all
    
    # Refs temizleme
    rm -rf .git/refs/original/
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
fi

echo ""
echo "✅ Temizleme tamamlandı!"
echo ""
echo "📤 Değişiklikleri uzak repoya göndermek için:"
echo "   git push origin --force --all"
echo "   git push origin --force --tags"
echo ""
echo "⚠️  NOT: Tüm takım üyelerinin repoyu yeniden clone etmesi gerekecek!"
