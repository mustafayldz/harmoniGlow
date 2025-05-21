import 'package:drumly/adMob/ad_service.dart';
import 'package:flutter/material.dart';

class AdView extends StatelessWidget {
  const AdView({required this.onAdFinished, super.key});
  final VoidCallback onAdFinished;

  @override
  Widget build(BuildContext context) {
    // Reklam gösterimi tamamlandığında çağır:
    AdService.instance.showInterstitialAd().whenComplete(() {
      if (context.mounted) {
        onAdFinished(); // SongView'a yönlendirir
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
