import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/home_view.dart';
import 'package:drumly/screens/settings/settings_viewmodel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final bluetoothState = context.watch<BluetoothBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
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
                    title: Text(
                      'darkMode'.tr(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    secondary: Icon(
                      appProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: AppColors.settingsRed,
                    ),
                    activeColor: AppColors.settingsRed,
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
                        Text(
                          'adjustCountdown'.tr(),
                          style: const TextStyle(fontSize: 18),
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

                bluetoothState.isConnected
                    ?
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
                                fillColor: AppColors.settingsRed,
                                color: AppColors.settingsRed.withAlpha(100),
                                onPressed: (index) =>
                                    vm.setDrumStyle(index == 1),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('electronic'.tr()),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('classic'.tr()),
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
                      )
                    : const SizedBox(),
                bluetoothState.isConnected
                    ? const SizedBox(height: 16)
                    : const SizedBox(),

                // App Info
                _SettingCard(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(
                      'appInformation'.tr(),
                      style: const TextStyle(fontSize: 18),
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
                const SizedBox(height: 16),

                // Language Selector
                _SettingCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'language'.tr(),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<Locale>(
                          value: context.locale,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.language,
                            color: AppColors.settingsRed,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          onChanged: (Locale? newLocale) async {
                            if (newLocale != null) {
                              await context.setLocale(newLocale);
                              await Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeView(),
                                ),
                              );
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: Locale('en'),
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: Locale('tr'),
                              child: Text('Türkçe'),
                            ),
                            DropdownMenuItem(
                              value: Locale('es'),
                              child: Text('Español'),
                            ),
                            DropdownMenuItem(
                              value: Locale('fr'),
                              child: Text('Français'),
                            ),
                            DropdownMenuItem(
                              value: Locale('ru'),
                              child: Text('Русский'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fixed Logout Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'logout'.tr(),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.settingsRed,
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
      color: isDark ? Colors.grey[850] : Colors.grey[200],
      child: child,
    );
  }
}
