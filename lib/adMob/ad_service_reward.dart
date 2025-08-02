import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:drumly/adMob/ad_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdServiceReward {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  Completer<void>? _loadCompleter;

  void loadRewardedAd() {
    _loadCompleter = Completer<void>();
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _loadCompleter?.complete();
        },
        onAdFailedToLoad: (err) {
          _isRewardedAdReady = false;
          _loadCompleter?.complete();
        },
      ),
    );
  }

  Future<bool> showRewardedAdWithConfetti(BuildContext context) async {
    final confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    if (!_isRewardedAdReady || _rewardedAd == null) {
      loadRewardedAd();
      await _loadCompleter?.future;

      if (!_isRewardedAdReady || _rewardedAd == null) {
        return false;
      }
    }

    final rewardCompleter = Completer<bool>();

    _rewardedAd!.setImmersiveMode(true);

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        confettiController.play();

        rewardCompleter.complete(true);
      },
    );

    _rewardedAd!.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
    loadRewardedAd();

    return rewardCompleter.future;
  }

  Future<bool> showRewardedAd(BuildContext context) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      loadRewardedAd();
      await _loadCompleter?.future;

      if (!_isRewardedAdReady || _rewardedAd == null) {
        return false;
      }
    }

    final rewardCompleter = Completer<bool>();

    _rewardedAd!.setImmersiveMode(true);

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewardCompleter.complete(true);
      },
    );

    _rewardedAd!.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
    loadRewardedAd();

    return rewardCompleter.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}
