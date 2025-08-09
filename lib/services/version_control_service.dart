import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/main.dart';

class VersionControlService {
  static final VersionControlService _instance = VersionControlService._internal();
  factory VersionControlService() => _instance;
  VersionControlService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;

  /// 🚀 Remote Config'i başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Remote Config ayarları
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(seconds: 10), // Test için 10 saniye
      ));

      // Fetch ve activate - Default değer kullanmıyoruz
      await _remoteConfig.fetchAndActivate();
      
      _isInitialized = true;
      debugPrint('✅ [VERSION] Remote Config başlatıldı');
    } catch (e) {
      debugPrint('❌ [VERSION] Remote Config hatası: $e');
    }
  }

  /// 🔍 Version kontrol sonucu
  Future<VersionCheckResult> checkVersion() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      debugPrint('📱 [VERSION] Mevcut versiyon: $currentVersion');

      // Maintenance mode kontrolü
      final maintenanceMode = _remoteConfig.getBool('maintenance_mode');
      if (maintenanceMode) {
        return VersionCheckResult(
          status: VersionStatus.maintenance,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          message: _getMaintenanceMessage(),
          storeUrl: '',
        );
      }

      // Remote Config'den version bilgilerini al
      String minVersion = _remoteConfig.getString('android_min_version');
      String latestVersion = _remoteConfig.getString('android_latest_version');
      
      // iOS için ayrı kontrol
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosMinVersion = _remoteConfig.getString('ios_min_version');
        final iosLatestVersion = _remoteConfig.getString('ios_latest_version');
        
        if (iosMinVersion.isNotEmpty) minVersion = iosMinVersion;
        if (iosLatestVersion.isNotEmpty) latestVersion = iosLatestVersion;
      }
      
      debugPrint('🔍 [VERSION] Min: $minVersion, Latest: $latestVersion');
      debugPrint('🔍 [VERSION] Current: $currentVersion');
      debugPrint('🔍 [VERSION] Platform: ${defaultTargetPlatform == TargetPlatform.android ? "Android" : "iOS"}');

      final storeUrl = _getStoreUrl(defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios');

      // Force update kontrolü
      final forceUpdate = _remoteConfig.getBool('force_update');
      
      debugPrint('🔍 [VERSION] Force update: $forceUpdate');
      debugPrint('🔍 [VERSION] Maintenance mode: $maintenanceMode');
      
      // Version karşılaştırması
      final isMinVersionMet = _compareVersions(currentVersion, minVersion) >= 0;
      final isLatestVersion = _compareVersions(currentVersion, latestVersion) >= 0;
      
      debugPrint('🔍 [VERSION] isMinVersionMet: $isMinVersionMet');
      debugPrint('🔍 [VERSION] isLatestVersion: $isLatestVersion');

      if (!isMinVersionMet || forceUpdate) {
        // Zorunlu güncelleme
        return VersionCheckResult(
          status: VersionStatus.forceUpdate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: _getUpdateMessage('force_update_message'),
          storeUrl: storeUrl,
        );
      } else if (!isLatestVersion) {
        // Opsiyonel güncelleme
        return VersionCheckResult(
          status: VersionStatus.updateAvailable,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: _getUpdateMessage('update_message'),
          storeUrl: storeUrl,
        );
      } else {
        // Güncel versiyon
        return VersionCheckResult(
          status: VersionStatus.upToDate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: '',
          storeUrl: storeUrl,
        );
      }
    } catch (e) {
      debugPrint('❌ [VERSION] Version check hatası: $e');
      return VersionCheckResult(
        status: VersionStatus.error,
        currentVersion: '0.0.0',
        latestVersion: '0.0.0',
        message: 'Version kontrolü yapılamadı',
        storeUrl: '',
      );
    }
  }

  /// 🛍️ Store URL'ini al
  String _getStoreUrl(String platform) {
    try {
      final storeUrls = _remoteConfig.getString('store_urls');
      if (storeUrls.isEmpty) {
        return '';
      }
      
      final Map<String, dynamic> urls = json.decode(storeUrls);
      return urls[platform] ?? '';
    } catch (e) {
      debugPrint('❌ [VERSION] Store URL parse hatası: $e');
      return '';
    }
  }

  /// 💬 Update mesajını al (dil desteği ile)
  String _getUpdateMessage(String messageKey) {
    try {
      final messageJson = _remoteConfig.getString(messageKey);
      if (messageJson.isEmpty) {
        return '';
      }
      
      final Map<String, dynamic> messages = json.decode(messageJson);
      
      // Uygulamanın mevcut dilini al
      final currentLocale = EasyLocalization.of(navigatorKey.currentContext!)?.locale;
      final languageCode = currentLocale?.languageCode ?? 'tr';
      
      // Önce mevcut dili kontrol et, yoksa fallback'leri dene
      return messages[languageCode] ?? 
             messages['tr'] ?? 
             messages['en'] ?? 
             '';
    } catch (e) {
      debugPrint('❌ [VERSION] Update message parse hatası: $e');
      return '';
    }
  }

  /// 🔧 Maintenance mesajını al
  String _getMaintenanceMessage() {
    try {
      final messageJson = _remoteConfig.getString('maintenance_message');
      if (messageJson.isEmpty) {
        return '';
      }
      
      final Map<String, dynamic> messages = json.decode(messageJson);
      
      // Uygulamanın mevcut dilini al
      final currentLocale = EasyLocalization.of(navigatorKey.currentContext!)?.locale;
      final languageCode = currentLocale?.languageCode ?? 'tr';
      
      // Önce mevcut dili kontrol et, yoksa fallback'leri dene
      return messages[languageCode] ?? 
             messages['tr'] ?? 
             messages['en'] ?? 
             '';
    } catch (e) {
      debugPrint('❌ [VERSION] Maintenance message parse hatası: $e');
      return '';
    }
  }

  /// 🔢 Version karşılaştırması (1.2.3 formatında)
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    // Eşit uzunluğa getir
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0; // Eşit
  }

  /// 🔄 Manuel fetch (debug için)
  Future<void> fetchLatestConfig() async {
    if (!_isInitialized) return;
    
    try {
      await _remoteConfig.fetch();
      await _remoteConfig.activate();
      debugPrint('✅ [VERSION] Config güncellendi');
    } catch (e) {
      debugPrint('❌ [VERSION] Config fetch hatası: $e');
    }
  }

  /// 🎹 Feature flag'leri kontrol et
  bool isBeatMakerEnabled() {
    if (!_isInitialized) return true;
    return _remoteConfig.getBool('beat_maker_enabled');
  }

  bool isAdvancedDrumkitEnabled() {
    if (!_isInitialized) return true;
    return _remoteConfig.getBool('advanced_drumkit_enabled');
  }

  bool isPremiumFeaturesEnabled() {
    if (!_isInitialized) return true;
    return _remoteConfig.getBool('premium_features_enabled');
  }

  bool isAnalyticsEnabled() {
    if (!_isInitialized) return true;
    return _remoteConfig.getBool('analytics_enabled');
  }

  bool isCrashReportingEnabled() {
    if (!_isInitialized) return true;
    return _remoteConfig.getBool('crash_reporting_enabled');
  }

  int getMaxSongRequestsPerUser() {
    if (!_isInitialized) return 10;
    return _remoteConfig.getInt('max_song_requests_per_user');
  }
}

/// 📊 Version kontrol sonucu
class VersionCheckResult {
  final VersionStatus status;
  final String currentVersion;
  final String latestVersion;
  final String message;
  final String storeUrl;

  VersionCheckResult({
    required this.status,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
    required this.storeUrl,
  });

  @override
  String toString() {
    return 'VersionCheckResult{status: $status, current: $currentVersion, latest: $latestVersion}';
  }
}

/// 📱 Version durumları
enum VersionStatus {
  upToDate,        // Güncel
  updateAvailable, // Güncelleme mevcut (opsiyonel)
  forceUpdate,     // Zorunlu güncelleme
  maintenance,     // Bakım modu
  error,           // Hata
}
