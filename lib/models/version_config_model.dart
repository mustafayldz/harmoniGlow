import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/main.dart';
import 'package:flutter/foundation.dart';

class VersionConfigModel {
  VersionConfigModel({
    required this.messages,
    required this.androidConfig,
    required this.iosConfig,
  });

  factory VersionConfigModel.fromRemoteConfig(FirebaseRemoteConfig rc) {
    try {
      final configJson = rc.getString('version_config');
      if (configJson.isEmpty) {
        throw Exception('version_config key bulunamadı');
      }

      debugPrint('🔍 [VERSION] Raw config JSON: $configJson');

      final rawConfig = json.decode(configJson) as Map<String, dynamic>;
      debugPrint('🔍 [VERSION] Parsed config: $rawConfig');

      // version_config anahtarının altındaki veriyi al
      final config = rawConfig['version_config'] as Map<String, dynamic>?;

      if (config == null) {
        throw Exception('version_config anahtarının altında veri bulunamadı');
      }

      debugPrint('🔍 [VERSION] Inner config: $config');

      final model = VersionConfigModel(
        messages: VersionMessages.fromJson(config['messages'] ?? {}),
        androidConfig: PlatformConfig.fromJson(config['android'] ?? {}),
        iosConfig: PlatformConfig.fromJson(config['ios'] ?? {}),
      );

      debugPrint('✅ [VERSION] Config başarıyla parse edildi');
      debugPrint(
          '📱 [VERSION] Android latest: ${model.androidConfig.latest}, force: ${model.androidConfig.force}');
      debugPrint(
          '📱 [VERSION] iOS latest: ${model.iosConfig.latest}, force: ${model.iosConfig.force}');

      return model;
    } catch (e) {
      debugPrint('❌ [VERSION] Config parse hatası: $e');
      // Hata durumunda varsayılan değerler
      return VersionConfigModel(
        messages: VersionMessages(normal: {}, force: {}),
        androidConfig:
            PlatformConfig(latest: '1.0.0', force: false, storeUrl: ''),
        iosConfig: PlatformConfig(latest: '1.0.0', force: false, storeUrl: ''),
      );
    }
  }

  final VersionMessages messages;
  final PlatformConfig androidConfig;
  final PlatformConfig iosConfig;

  // Platform'a göre config al
  PlatformConfig getPlatformConfig() {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? iosConfig
        : androidConfig;
  }
}

class VersionMessages {
  VersionMessages({
    required this.normal,
    required this.force,
  });

  factory VersionMessages.fromJson(Map<String, dynamic> json) {
    return VersionMessages(
      normal: Map<String, String>.from(json['normal'] ?? {}),
      force: Map<String, String>.from(json['force'] ?? {}),
    );
  }

  final Map<String, String> normal;
  final Map<String, String> force;

  String getLocalizedMessage({required bool isForceUpdate}) {
    final messages = isForceUpdate ? force : normal;
    final currentLocale =
        EasyLocalization.of(navigatorKey.currentContext!)?.locale;
    final code = currentLocale?.languageCode ?? 'tr';
    return messages[code] ?? messages['tr'] ?? messages['en'] ?? '';
  }
}

class PlatformConfig {
  PlatformConfig({
    required this.latest,
    required this.force,
    required this.storeUrl,
  });

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      latest: json['latest']?.toString() ?? '1.0.0',
      force: json['force'] ?? false,
      storeUrl: json['storeUrl']?.toString() ?? '',
    );
  }

  final String latest;
  final bool force;
  final String storeUrl;
}
