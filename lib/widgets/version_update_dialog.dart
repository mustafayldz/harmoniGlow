import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/services/version_control_service.dart';

class VersionUpdateDialog extends StatelessWidget {
  final VersionCheckResult result;
  final VoidCallback? onDismiss;

  const VersionUpdateDialog({
    super.key,
    required this.result,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isForceUpdate = result.status == VersionStatus.forceUpdate;
    final isMaintenance = result.status == VersionStatus.maintenance;

    return PopScope(
      canPop: !isForceUpdate && !isMaintenance, // Force update ve maintenance'te geri tuşu çalışmasın
      onPopInvokedWithResult: (didPop, result) {
        // Force update durumunda uygulamadan çıkış yap
        if (!didPop && isForceUpdate) {
          SystemNavigator.pop();
        }
      },
      child: AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMaintenance
                    ? Colors.orange.withValues(alpha: 0.1)
                    : isForceUpdate 
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isMaintenance 
                    ? Icons.construction_rounded
                    : isForceUpdate 
                        ? Icons.warning_rounded 
                        : Icons.update_rounded,
                color: isMaintenance 
                    ? Colors.orange
                    : isForceUpdate 
                        ? Colors.red 
                        : Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isMaintenance 
                    ? 'maintenanceMode'.tr()
                    : isForceUpdate 
                        ? 'forceUpdate'.tr() 
                        : 'updateAvailable'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.8),
              ),
            ),
            if (!isMaintenance) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'currentVersion'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode 
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          result.currentVersion,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: isDarkMode 
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'newVersion'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode 
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          result.latestVersion,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isMaintenance) ...[
            // Maintenance modunda sadece Tamam butonu
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ok'.tr(),
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            // Normal güncelleme modları
            // İptal butonu (sadece opsiyonel güncellemede)
            if (!isForceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
                child: Text(
                  'later'.tr(),
                  style: TextStyle(
                    color: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
            
            // Güncelle butonu
            ElevatedButton(
              onPressed: () => _openStore(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isForceUpdate ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'update'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🛍️ Store'a yönlendir
  Future<void> _openStore(BuildContext context) async {
    try {
      final uri = Uri.parse(result.storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'storeCannotOpen'.tr()}: ${result.storeUrl}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'storeOpenError'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 🎯 Version kontrolü yapmak ve dialog göstermek için helper
class VersionChecker {
  static Future<bool> checkAndShowUpdateDialog(BuildContext context) async {
    try {
      print('🔍 [VERSION] Version kontrolü başlıyor...');
      
      final versionService = VersionControlService();
      final result = await versionService.checkVersion();
      
      print('📱 [VERSION] Kontrol sonucu: $result');

      if (!context.mounted) {
        print('❌ [VERSION] Context artık mounted değil');
        return false;
      }

      // Sadece güncelleme gerekiyorsa dialog göster
      if (result.status == VersionStatus.updateAvailable || 
          result.status == VersionStatus.forceUpdate ||
          result.status == VersionStatus.maintenance) {
        
        print('🎯 [VERSION] Update dialog gösteriliyor: ${result.status}');
        
        showDialog(
          context: context,
          barrierDismissible: false, // Hiçbir durumda dış alana tıklama ile kapanmasın
          builder: (context) => WillPopScope(
            onWillPop: () async {
              // Force update veya maintenance durumunda geri tuşunu engelle
              if (result.status == VersionStatus.forceUpdate || 
                  result.status == VersionStatus.maintenance) {
                if (result.status == VersionStatus.forceUpdate) {
                  SystemNavigator.pop(); // Uygulamadan çık
                }
                return false;
              }
              return true;
            },
            child: VersionUpdateDialog(
              result: result,
              onDismiss: () {
                print('📱 [VERSION] Kullanıcı güncellemeyi erteledi');
              },
            ),
          ),
        );
        return true; // Dialog gösterildi
      } else if (result.status == VersionStatus.upToDate) {
        print('✅ [VERSION] Uygulama güncel, dialog gösterilmiyor');
        return false; // Dialog gösterilmedi
      } else if (result.status == VersionStatus.error) {
        print('❌ [VERSION] Version check hatası, dialog gösterilmiyor');
        return false; // Hata durumu
      }
      return false;
    } catch (e) {
      print('💥 [VERSION] Version check exception: $e');
      return false;
    }
  }
}
