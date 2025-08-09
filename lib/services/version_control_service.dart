import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/main.dart';

class VersionControlService {
  factory VersionControlService() => _instance;
  VersionControlService._internal();
  static final VersionControlService _instance =
      VersionControlService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;

  Future<void> initialize() async {
    debugPrint('🔄 [VERSION] Remote Config başlatılıyor...');

    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // ✅ Daha kısa fetch interval ve timeout
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: const Duration(seconds: 5), // Debug için kısa
        ),
      );

      // ✅ Default values ekle
      await _remoteConfig.setDefaults({
        'android_min_version': '{"value": "1.0.0"}',
        'android_latest_version': '{"value": "1.0.8"}',
        'ios_min_version': '{"value": "1.0.0"}',
        'ios_latest_version': '{"value": "1.0.8"}',
        'force_update': '{"value": false}',
        'store_urls':
            '{"value": "{\\"android\\":\\"https://play.google.com/store/apps/details?id=com.drumly.mobile\\",\\"ios\\":\\"https://apps.apple.com/ca/app/drumly/id6745571007\\"}"}',
        'update_message':
            '{"value": "{\\"tr\\":\\"Yeni sürüm mevcut!\\",\\"en\\":\\"New version available!\\"}"}',
        'force_update_message':
            '{"value": "{\\"tr\\":\\"Güncelleme gerekli!\\",\\"en\\":\\"Update required!\\"}"}',
      });

      // ✅ Fetch ve activate
      await _remoteConfig.fetch();
      debugPrint('🔄 [VERSION] Fetch completed');

      final activateResult = await _remoteConfig.activate();
      debugPrint('🔄 [VERSION] Activate result: $activateResult');

      _isInitialized = true;
      debugPrint('✅ [VERSION] Remote Config başarıyla başlatıldı');

      // ✅ Debug: Tüm config değerlerini yazdır
      _debugPrintAllConfigs();
    } catch (e) {
      debugPrint('❌ [VERSION] Remote Config hatası: $e');
      _isInitialized = false;
    }
  }

  // ✅ Debug için tüm config'leri yazdır
  void _debugPrintAllConfigs() {
    final keys = [
      'android_min_version',
      'android_latest_version',
      'ios_min_version',
      'ios_latest_version',
      'force_update',
      'store_urls',
      'update_message',
      'force_update_message',
    ];

    for (String key in keys) {
      final rawValue = _remoteConfig.getString(key);
      debugPrint('🔍 [VERSION] $key: $rawValue');
    }
  }

  Future<VersionCheckResult> checkVersion() async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('🔄 [VERSION] Sürüm kontrolü başlatılıyor...');

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      String minVersion, latestVersion;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        minVersion = _getConfigValue('ios_min_version');
        latestVersion = _getConfigValue('ios_latest_version');
      } else {
        minVersion = _getConfigValue('android_min_version');
        latestVersion = _getConfigValue('android_latest_version');
      }

      debugPrint('📱 [VERSION] Platform: $defaultTargetPlatform');
      debugPrint('📱 [VERSION] Mevcut sürüm: $currentVersion');
      debugPrint('📱 [VERSION] Minimum sürüm: $minVersion');
      debugPrint('📱 [VERSION] En son sürüm: $latestVersion');

      final storeUrl = _getStoreUrl(
        defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
      );
      final forceUpdate = _getConfigBoolValue('force_update');

      debugPrint('🔗 [VERSION] Store URL: $storeUrl');
      debugPrint('⚠️ [VERSION] Force update: $forceUpdate');

      final isMinVersionMet = _compareVersions(currentVersion, minVersion) >= 0;
      final isLatestVersion =
          _compareVersions(currentVersion, latestVersion) >= 0;

      debugPrint('✅ [VERSION] Min version karşılanıyor: $isMinVersionMet');
      debugPrint('✅ [VERSION] Latest version: $isLatestVersion');

      if (!isMinVersionMet || forceUpdate) {
        return VersionCheckResult(
          status: VersionStatus.forceUpdate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: _getUpdateMessage('force_update_message'),
          storeUrl: storeUrl,
        );
      } else if (!isLatestVersion) {
        return VersionCheckResult(
          status: VersionStatus.updateAvailable,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: _getUpdateMessage('update_message'),
          storeUrl: storeUrl,
        );
      } else {
        return VersionCheckResult(
          status: VersionStatus.upToDate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: '',
          storeUrl: storeUrl,
        );
      }
    } catch (e) {
      debugPrint('❌ [VERSION] Sürüm kontrolü hatası: $e');
      return VersionCheckResult(
        status: VersionStatus.error,
        currentVersion: '0.0.0',
        latestVersion: '0.0.0',
        message: 'Version kontrolü yapılamadı: $e',
        storeUrl: '',
      );
    }
  }

  // ✅ Düzeltilmiş config value getter
  String _getConfigValue(String key) {
    try {
      final configValue = _remoteConfig.getString(key);
      debugPrint('🔍 [VERSION] Raw config[$key]: $configValue');

      if (configValue.isEmpty) {
        debugPrint('⚠️ [VERSION] Config[$key] boş');
        return '';
      }

      // Firebase Console'dan gelen JSON'ı parse et
      final Map<String, dynamic> parsed = json.decode(configValue);
      final value = parsed['value']?.toString() ?? '';

      debugPrint('✅ [VERSION] Parsed config[$key]: $value');
      return value;
    } catch (e) {
      debugPrint('❌ [VERSION] Config[$key] parse hatası: $e');
      // Fallback: Ham veriyi döndür
      final rawValue = _remoteConfig.getString(key);
      debugPrint('🔄 [VERSION] Fallback config[$key]: $rawValue');
      return rawValue;
    }
  }

  // ✅ Düzeltilmiş bool value getter
  bool _getConfigBoolValue(String key) {
    try {
      final configValue = _remoteConfig.getString(key);
      debugPrint('🔍 [VERSION] Raw bool config[$key]: $configValue');

      if (configValue.isEmpty) return false;

      final Map<String, dynamic> parsed = json.decode(configValue);
      final value = parsed['value'];

      debugPrint('✅ [VERSION] Parsed bool config[$key]: $value');

      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    } catch (e) {
      debugPrint('❌ [VERSION] Bool config[$key] parse hatası: $e');
      return _remoteConfig.getBool(key);
    }
  }

  // ✅ Düzeltilmiş store URL getter
  String _getStoreUrl(String platform) {
    try {
      final storeUrls = _getConfigValue('store_urls');
      debugPrint('🔍 [VERSION] Store URLs raw: $storeUrls');

      if (storeUrls.isEmpty) return '';

      final Map<String, dynamic> urls = json.decode(storeUrls);
      final url = urls[platform] ?? '';

      debugPrint('✅ [VERSION] Store URL[$platform]: $url');
      return url;
    } catch (e) {
      debugPrint('❌ [VERSION] Store URL parse hatası: $e');
      return '';
    }
  }

  // ✅ Düzeltilmiş message getter
  String _getUpdateMessage(String messageKey) {
    try {
      final messageValue = _getConfigValue(messageKey);
      debugPrint('🔍 [VERSION] Message raw[$messageKey]: $messageValue');

      if (messageValue.isEmpty) return '';

      final Map<String, dynamic> messages = json.decode(messageValue);
      final currentLocale =
          EasyLocalization.of(navigatorKey.currentContext!)?.locale;
      final languageCode = currentLocale?.languageCode ?? 'tr';

      final message =
          messages[languageCode] ?? messages['tr'] ?? messages['en'] ?? '';

      debugPrint('✅ [VERSION] Message[$messageKey][$languageCode]: $message');
      return message;
    } catch (e) {
      debugPrint('❌ [VERSION] Message parse hatası[$messageKey]: $e');
      return 'Güncelleme mesajı alınamadı';
    }
  }

  int _compareVersions(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      while (v1Parts.length < v2Parts.length) {
        v1Parts.add(0);
      }
      while (v2Parts.length < v1Parts.length) {
        v2Parts.add(0);
      }

      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] > v2Parts[i]) return 1;
        if (v1Parts[i] < v2Parts[i]) return -1;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ [VERSION] Sürüm karşılaştırma hatası: $e');
      return 0;
    }
  }

  // ✅ Manual refresh için
  Future<void> forceRefresh() async {
    try {
      debugPrint('🔄 [VERSION] Manuel refresh başlatılıyor...');
      await _remoteConfig.fetch();
      await _remoteConfig.activate();
      _debugPrintAllConfigs();
      debugPrint('✅ [VERSION] Manuel refresh tamamlandı');
    } catch (e) {
      debugPrint('❌ [VERSION] Manuel refresh hatası: $e');
    }
  }
}

class VersionCheckResult {
  VersionCheckResult({
    required this.status,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
    required this.storeUrl,
  });

  final VersionStatus status;
  final String currentVersion;
  final String latestVersion;
  final String message;
  final String storeUrl;

  @override
  String toString() =>
      'VersionCheckResult(status: $status, current: $currentVersion, latest: $latestVersion, message: $message, url: $storeUrl)';
}

enum VersionStatus {
  upToDate,
  updateAvailable,
  forceUpdate,
  error,
}
