import 'package:drumly/models/version_config_model.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class VersionControlService {
  factory VersionControlService() => _instance;
  VersionControlService._internal();
  static final VersionControlService _instance =
      VersionControlService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;
  VersionConfigModel? _config;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(seconds: 5),
        ),
      );

      await _remoteConfig.fetchAndActivate();

      // Remote Config verilerini model'e parse et
      _config = VersionConfigModel.fromRemoteConfig(_remoteConfig);

      _isInitialized = true;
      debugPrint('✅ [VERSION] Remote Config başlatıldı');
    } catch (e) {
      debugPrint('⚠️ [VERSION] Remote Config alınamadı: $e');
      // Firebase’den çekilemezse null bırakıyoruz, kontrol kısmında skip edilecek
    }
  }

  Future<VersionCheckResult> checkVersion() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Eğer config yüklenmemişse skip
    if (_config == null) {
      debugPrint('⚠️ [VERSION] Config boş, sürüm kontrolü atlandı.');
      return VersionCheckResult(
        status: VersionStatus.upToDate,
        currentVersion: '',
        latestVersion: '',
        message: '',
        storeUrl: '',
        isForceUpdate: false,
      );
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    debugPrint('📱 [VERSION] Mevcut versiyon: $currentVersion');
    debugPrint(
        '📱 [VERSION] Platform: ${defaultTargetPlatform == TargetPlatform.iOS ? "iOS" : "Android"}');

    // Platform'a göre config al
    final platformConfig = _config!.getPlatformConfig();
    final latestVersion = platformConfig.latest;
    final forceUpdate = platformConfig.force;
    final storeUrl = platformConfig.storeUrl;

    debugPrint('📱 [VERSION] Latest: $latestVersion, Force: $forceUpdate');
    debugPrint('🛍️ [VERSION] Store URL: $storeUrl');

    final isLatestVersion =
        _compareVersions(currentVersion, latestVersion) >= 0;

    debugPrint('🔍 [VERSION] Is latest version: $isLatestVersion');
    debugPrint('🔍 [VERSION] Force update: $forceUpdate');

    if (forceUpdate || !isLatestVersion) {
      final isForceUpdate = forceUpdate;
      final message =
          _config!.messages.getLocalizedMessage(isForceUpdate: isForceUpdate);

      debugPrint(isForceUpdate
          ? '🚨 [VERSION] Force update gerekli'
          : '📢 [VERSION] Güncelleme mevcut');

      // Her durumda updateAvailable döndür, ama result içinde force bilgisini tut
      return VersionCheckResult(
        status: VersionStatus.updateAvailable,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        message: message,
        storeUrl: storeUrl,
        isForceUpdate: isForceUpdate, // Force update bilgisini ekle
      );
    } else {
      debugPrint('✅ [VERSION] Güncel versiyon');
      return VersionCheckResult(
        status: VersionStatus.upToDate,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        message: '',
        storeUrl: storeUrl,
        isForceUpdate: false,
      );
    }
  }

  int _compareVersions(String v1, String v2) {
    final p1 = v1.split('.').map(int.parse).toList();
    final p2 = v2.split('.').map(int.parse).toList();

    while (p1.length < p2.length) {
      p1.add(0);
    }
    while (p2.length < p1.length) {
      p2.add(0);
    }

    for (var i = 0; i < p1.length; i++) {
      if (p1[i] > p2[i]) return 1;
      if (p1[i] < p2[i]) return -1;
    }
    return 0;
  }
}

class VersionCheckResult {
  VersionCheckResult({
    required this.status,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
    required this.storeUrl,
    this.isForceUpdate = false,
  });

  final VersionStatus status;
  final String currentVersion;
  final String latestVersion;
  final String message;
  final String storeUrl;
  final bool isForceUpdate;
}

enum VersionStatus {
  upToDate,
  updateAvailable,
  error,
}
