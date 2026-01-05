import 'package:drumly/adMob/ad_service.dart';
import 'package:flutter/material.dart';

/// AdView - Reklam geçiş ekranı
/// 
/// ⚠️ ÖNEMLİ: Families Policy uyumluluğu için bu ekran,
/// reklam gösterildiğinde TAMAMEN GİZLENİR.
/// Böylece reklamın X (kapat) butonu engellenmiş olmaz.
class AdView extends StatefulWidget {
  const AdView({required this.onAdFinished, super.key});
  final VoidCallback onAdFinished;

  @override
  State<AdView> createState() => _AdViewState();
}

class _AdViewState extends State<AdView> {
  bool _adShowing = false;

  @override
  void initState() {
    super.initState();
    _showAd();
  }

  Future<void> _showAd() async {
    // Kısa bir gecikme ile reklamı göster
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      setState(() => _adShowing = true);

      // Reklam göster ve bittiğinde callback çağır
      await AdService.instance.showInterstitialAd();
      
      if (mounted) {
        widget.onAdFinished();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 Reklam gösterilirken bu ekranı GİZLE
    // Böylece reklamın X butonu üstüne hiçbir şey binmez
    // Bu Families Policy için kritik!
    if (_adShowing) {
      return const SizedBox.shrink(); // Boş widget - reklam tam görünsün
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sadece reklam yüklenirken kısa bir loading göster
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
