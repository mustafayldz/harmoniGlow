import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AgeGateStatus { unknown, under18, adult }

class AgeGateService {
  AgeGateService._();
  static final AgeGateService instance = AgeGateService._();

  static const String _birthYearKey = 'age_gate_birth_year';

  int? _cachedBirthYear;
  bool _loaded = false;

  Future<int?> getBirthYear() async {
    if (_loaded) return _cachedBirthYear;
    final prefs = await SharedPreferences.getInstance();
    _cachedBirthYear = prefs.getInt(_birthYearKey);
    _loaded = true;
    return _cachedBirthYear;
  }

  Future<bool> hasBirthYear() async => (await getBirthYear()) != null;

  Future<void> setBirthYear(int year) async {
    final alreadySet = await hasBirthYear();
    if (alreadySet) return; // Kilitli - tekrar set etme

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_birthYearKey, year);
    _cachedBirthYear = year;
    _loaded = true;

    // Seçimden sonra AdMob config'ini güncelle
    await applyRequestConfiguration();
  }

  Future<AgeGateStatus> getStatus() async {
    if (!Platform.isAndroid) return AgeGateStatus.adult; // Android dışı: kısıtlama yok

    final year = await getBirthYear();
    if (year == null) return AgeGateStatus.unknown;

    final age = DateTime.now().year - year;
    return age >= 18 ? AgeGateStatus.adult : AgeGateStatus.under18;
  }

  Future<bool> canShowFullScreenAds() async =>
      (await getStatus()) == AgeGateStatus.adult;

  Future<void> applyRequestConfiguration() async {
    final status = await getStatus();

    final RequestConfiguration config = status == AgeGateStatus.adult
        ? RequestConfiguration(
            tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
            tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
          )
        : RequestConfiguration(
            maxAdContentRating: MaxAdContentRating.g,
            tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
            tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
          );

    await MobileAds.instance.updateRequestConfiguration(config);
  }
}
