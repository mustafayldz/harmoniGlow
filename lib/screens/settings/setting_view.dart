import 'package:drumly/screens/settings/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drumly/provider/app_provider.dart';

class SettingView extends StatelessWidget {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) {
          final vm = SettingViewModel();
          vm.initialize(Provider.of<AppProvider>(context, listen: false));
          return vm;
        },
        child: const _SettingViewBody(),
      );
}

class _SettingViewBody extends StatelessWidget {
  const _SettingViewBody();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SettingViewModel>(context);
    final appProvider = vm.appProvider;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Dark Mode Toggle
                _SettingCard(
                  child: SwitchListTile(
                    title:
                        const Text('Dark Mode', style: TextStyle(fontSize: 18)),
                    secondary: Icon(
                      appProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: theme.colorScheme.primary,
                    ),
                    value: appProvider.isDarkMode,
                    onChanged: (_) => vm.toggleTheme(),
                  ),
                ),
                const SizedBox(height: 16),

                // Countdown Adjust
                _SettingCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
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
                              onPressed: () => vm.adjustCountdown(false),
                            ),
                            Text(
                              '${appProvider.countdownValue} s',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => vm.adjustCountdown(true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Drum Type Toggle
                _SettingCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Image.asset(
                            'assets/images/edrum.png',
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                        ToggleButtons(
                          isSelected: appProvider.isClassic
                              ? [false, true]
                              : [true, false],
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: theme.colorScheme.primary,
                          color: theme.colorScheme.onSurface,
                          onPressed: (index) => vm.setDrumStyle(index == 1),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Electronic'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Classic'),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Image.asset(
                            'assets/images/cdrum.png',
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // App Info
                _SettingCard(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text(
                      'App Information',
                      style: TextStyle(fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Version: ${vm.version}'),
                        Text('Build #: ${vm.buildNumber}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fixed Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => vm.logout(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: isDark
          ? Colors
              .grey[850] // Daha açık bir dark card (varsayılan 800'den açık)
          : Colors
              .grey[200], // Daha koyu bir light card (varsayılan white yerine)
      child: child,
    );
  }
}
