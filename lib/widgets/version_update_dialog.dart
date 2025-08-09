import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/services/version_control_service.dart';

class VersionUpdateDialog extends StatelessWidget {
  const VersionUpdateDialog({
    required this.result,
    super.key,
    this.onDismiss,
  });

  final VersionCheckResult result;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isForceUpdate = result.isForceUpdate; // VersionCheckResult'tan al

    return PopScope(
      canPop: !isForceUpdate,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isForceUpdate) {
          SystemNavigator.pop();
        }
      },
      child: AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isForceUpdate
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isForceUpdate ? Icons.warning_rounded : Icons.update_rounded,
                color: isForceUpdate ? Colors.red : Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'updateAvailable'.tr(), // Her zaman aynı başlığı kullan
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
            // Her durumda version karşılaştırmasını göster
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
                  _buildVersionColumn(
                    title: 'currentVersion'.tr(),
                    value: result.currentVersion,
                    isDarkMode: isDarkMode,
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                  _buildVersionColumn(
                    title: 'newVersion'.tr(),
                    value: result.latestVersion,
                    isDarkMode: isDarkMode,
                    valueColor: isForceUpdate ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
      ),
    );
  }

  Widget _buildVersionColumn({
    required String title,
    required String value,
    required bool isDarkMode,
    Color? valueColor,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      );

  Future<void> _openStore(BuildContext context) async {
    try {
      final uri = Uri.parse(result.storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError(context, '${'storeCannotOpen'.tr()}: ${result.storeUrl}');
      }
    } catch (e) {
      _showError(context, '${'storeOpenError'.tr()}: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}

class VersionChecker {
  static Future<bool> checkAndShowUpdateDialog(BuildContext context) async {
    try {
      debugPrint(
          '...................................................Checking for updates...');
      final versionService = VersionControlService();
      final result = await versionService.checkVersion();

      debugPrint(
          '...................................................Version check result: ${result.status}');

      if (!context.mounted) return false;

      if (result.status == VersionStatus.updateAvailable) {
        showDialog(
          context: context,
          barrierDismissible:
              !result.isForceUpdate, // Force update ise dismiss edilemez
          builder: (context) => VersionUpdateDialog(
            result: result,
            onDismiss: () {},
          ),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
