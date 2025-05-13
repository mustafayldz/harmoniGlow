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
            const SizedBox(height: 24),

            // Logout Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.token,
                  color: Colors.white,
                ),
                label: const Text(
                  'token',
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
                  await userService.getUser(context).then((user) {
                    if (user != null) {
                      print('User found');
                    } else {
                      print('User not found');
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 24),
            // Logout Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.token,
                  color: Colors.white,
                ),
                label: const Text(
                  'set old token',
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
                  var oldtoken =
                      'eyJhbGciOiJSUzI1NiIsImtpZCI6IjU5MWYxNWRlZTg0OTUzNjZjOTgyZTA1MTMzYmNhOGYyNDg5ZWFjNzIiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vZHJ1bWx5LW1vYmlsZSIsImF1ZCI6ImRydW1seS1tb2JpbGUiLCJhdXRoX3RpbWUiOjE3NDY5ODEyNDIsInVzZXJfaWQiOiJ4T2tLVWxmMlhEUkNDQmh4TE9NWWpKUmRaamoxIiwic3ViIjoieE9rS1VsZjJYRFJDQ0JoeExPTVlqSlJkWmpqMSIsImlhdCI6MTc0Njk4MTI0MiwiZXhwIjoxNzQ2OTg0ODQyLCJlbWFpbCI6Im1zdGYueWlsZGl6OTJAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7ImVtYWlsIjpbIm1zdGYueWlsZGl6OTJAZ21haWwuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifX0.t7a1JcYXx67xt8fMeVVycQ8xuZGZRVU8HrtaflUnUTN2OH1BuD9YSvdvs-KLB6Rr6aHT_3mr4r_ce-3OXl0S-P0NCLrvig9aFyeF4bG-FM8yFF-jCWgBfC7BQ6tGhaesduDFICN8TUD0-fJCC5qQCwl_FLMOoIj8MkETcebX76mbEiVSwEREsfYLZweG_6P3xRY03UtoMIv4ueVGMGD--CW2DN_2oAjSrgvjQED_OdZ4IdSHFX0N6fqE_eR-aDEiFWnWa5MSXEbLz_LyMan1RIv6zKCY_62VSJ-W474v4vZfDepwF09NYET3xXq6c54I_NkbUA2SFDVqo3gU2JFPdg';

                  await StorageService.saveFirebaseToken(oldtoken);

                  print("old token set");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
