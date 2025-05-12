import 'package:drumly/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  SettingViewState createState() => SettingViewState();
}

class SettingViewState extends State<SettingView> {
  late AppProvider appProvider;
  final StorageService storageService = StorageService();
  final UserService userService = UserService();

  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    appProvider = Provider.of<AppProvider>(context, listen: false);

    PackageInfo.fromPlatform().then((info) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Dark Mode Toggle
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: SwitchListTile(
                title: const Text('Dark Mode', style: TextStyle(fontSize: 18)),
                secondary: Icon(
                  appProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                value: appProvider.isDarkMode,
                onChanged: (value) async {
                  await appProvider.toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Countdown Adjustment
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adjust Countdown',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            appProvider.setCountdownValue(false);
                          },
                        ),
                        Text(
                          '${context.watch<AppProvider>().countdownValue} s',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            appProvider.setCountdownValue(true);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Version Info
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text(
                  'App Information',
                  style: TextStyle(fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Version: $_version'),
                    Text('Build #: $_buildNumber'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  await storageService.clearSavedDeviceId();
                  await storageService.clearFirebaseToken();
                  await Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
