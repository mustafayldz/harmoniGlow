import 'package:flutter/material.dart';
import 'package:drumly/services/version_control_service.dart';
import 'package:drumly/widgets/version_update_dialog.dart';

/// 🛡️ Navigation koruma widget'ı
/// Force update durumunda navigation'ı engeller
class NavigationGuard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onNavigationBlocked;

  const NavigationGuard({
    super.key,
    required this.child,
    this.onNavigationBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkForceUpdateStatus(),
      builder: (context, snapshot) {
        // Loading durumunda normal widget'ı göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return child;
        }

        final isForceUpdateRequired = snapshot.data ?? false;

        // Force update gerekiyorsa navigation'ı engelle
        if (isForceUpdateRequired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onNavigationBlocked?.call();
            _showForceUpdateDialog(context);
          });
          
          // Geçici bir loading ekranı göster
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return child;
      },
    );
  }

  /// 🔍 Force update durumunu kontrol et
  Future<bool> _checkForceUpdateStatus() async {
    try {
      final versionService = VersionControlService();
      final result = await versionService.checkVersion();
      
      return result.status == VersionStatus.forceUpdate;
    } catch (e) {
      debugPrint('❌ [NAV_GUARD] Version check hatası: $e');
      return false;
    }
  }

  /// 🚨 Force update dialog'unu göster
  void _showForceUpdateDialog(BuildContext context) async {
    try {
      final versionService = VersionControlService();
      final result = await versionService.checkVersion();
      
      if (result.status == VersionStatus.forceUpdate && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => VersionUpdateDialog(result: result),
        );
      }
    } catch (e) {
      debugPrint('❌ [NAV_GUARD] Dialog gösterme hatası: $e');
    }
  }
}
