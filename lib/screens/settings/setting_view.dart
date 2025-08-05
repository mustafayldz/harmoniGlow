import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/home/home_view.dart';
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

class _SettingViewBody extends StatefulWidget {
  const _SettingViewBody();

  @override
  State<_SettingViewBody> createState() => _SettingViewBodyState();
}

class _SettingViewBodyState extends State<_SettingViewBody> {
  bool _isProfileExpanded = false;

  @override
  void initState() {
    super.initState();
    // User bilgilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<SettingViewModel>(context, listen: false);
      vm.refreshUserInfo(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SettingViewModel>(context);
    final appProvider = vm.appProvider;
    final bluetoothState = context.watch<BluetoothBloc>().state;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    const Color(0xFF0F172A), // Dark slate
                    const Color(0xFF1E293B), // Lighter slate
                    const Color(0xFF334155), // Even lighter
                  ]
                : [
                    const Color(0xFFF8FAFC), // Light gray
                    const Color(0xFFE2E8F0), // Slightly darker
                    const Color(0xFFCBD5E1), // Even darker
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Modern App Bar
              _buildModernAppBar(context, isDarkMode),

              // Content
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Profile Section
                          _buildProfileSection(vm, isDarkMode),
                          const SizedBox(height: 24),

                          // Dark Mode Toggle
                          _buildSimpleSettingCard(
                            isDarkMode: isDarkMode,
                            icon: Icons.brightness_6_outlined,
                            title: 'darkMode'.tr(),
                            child: Switch(
                              value: appProvider.isDarkMode,
                              onChanged: (_) => vm.toggleTheme(),
                              activeColor: const Color(0xFF6366F1),
                              activeTrackColor: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor:
                                  Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Countdown Adjust
                          _buildSimpleSettingCard(
                            isDarkMode: isDarkMode,
                            icon: Icons.timer_outlined,
                            title: 'adjustCountdown'.tr(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_rounded),
                                  onPressed: () => vm.adjustCountdown(false),
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${appProvider.countdownValue} s',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_rounded),
                                  onPressed: () => vm.adjustCountdown(true),
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Drum Type Toggle (only if connected)
                          if (bluetoothState.isConnected) ...[
                            _buildSimpleSettingCard(
                              isDarkMode: isDarkMode,
                              icon: Icons.music_note_outlined,
                              title: 'drumType'.tr(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: !appProvider.isClassic
                                          ? const Color(0xFF6366F1)
                                          : isDarkMode
                                              ? Colors.white
                                                  .withValues(alpha: 0.1)
                                              : Colors.black
                                                  .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextButton(
                                      onPressed: () => vm.setDrumStyle(false),
                                      child: Text(
                                        'electronic'.tr(),
                                        style: TextStyle(
                                          color: !appProvider.isClassic
                                              ? Colors.white
                                              : isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: appProvider.isClassic
                                          ? const Color(0xFF6366F1)
                                          : isDarkMode
                                              ? Colors.white
                                                  .withValues(alpha: 0.1)
                                              : Colors.black
                                                  .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextButton(
                                      onPressed: () => vm.setDrumStyle(true),
                                      child: Text(
                                        'classic'.tr(),
                                        style: TextStyle(
                                          color: appProvider.isClassic
                                              ? Colors.white
                                              : isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Language Selector
                          _buildSimpleSettingCard(
                            isDarkMode: isDarkMode,
                            icon: Icons.language_outlined,
                            title: 'language'.tr(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<Locale>(
                                value: context.locale,
                                dropdownColor: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.white,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                underline: const SizedBox(),
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
                                items: [
                                  DropdownMenuItem(
                                    value: const Locale('en'),
                                    child: Text(
                                      'English',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: const Locale('tr'),
                                    child: Text(
                                      'Türkçe',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: const Locale('es'),
                                    child: Text(
                                      'Español',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: const Locale('fr'),
                                    child: Text(
                                      'Français',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: const Locale('ru'),
                                    child: Text(
                                      'Русский',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // App Info
                          _buildSimpleSettingCard(
                            isDarkMode: isDarkMode,
                            icon: Icons.info_outlined,
                            title: 'appInformation'.tr(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Version: ${vm.version}',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Build #: ${vm.buildNumber}',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.black.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Logout Button
                          _buildSimpleSettingCard(
                            isDarkMode: isDarkMode,
                            icon: Icons.logout_rounded,
                            title: 'logout'.tr(),
                            isButton: true,
                            onTap: () => vm.logout(context),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, bool isDarkMode) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'settings'.tr(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      );

  /// 🎨 Profile Section - Modern Design with Expandable
  Widget _buildProfileSection(SettingViewModel vm, bool isDarkMode) =>
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    const Color(0xFF1E293B).withValues(alpha: 0.9),
                    const Color(0xFF334155).withValues(alpha: 0.7),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFC),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _isProfileExpanded = !_isProfileExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'profile'.tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            if (!_isProfileExpanded)
                              Text(
                                vm.userModel?.email ?? 'tap_to_view'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (vm.isLoadingUser)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          _isProfileExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                    ],
                  ),

                  // Expandable Content
                  if (_isProfileExpanded) ...[
                    const SizedBox(height: 20),
                    if (vm.userModel != null) ...[
                      _buildUserInfoCard(
                        icon: Icons.email_rounded,
                        title: 'email'.tr(),
                        value: vm.userModel!.email,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _buildUserInfoCard(
                        icon: Icons.badge_rounded,
                        title: 'name'.tr(),
                        value: vm.userModel!.name,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _buildUserInfoCard(
                        icon: Icons.library_music_rounded,
                        title: 'assigned_songs'.tr(),
                        value:
                            '${vm.userModel!.assignedSongIds.length} ${'song_count'.tr()}',
                        isDarkMode: isDarkMode,
                      ),
                      if (vm.userModel!.devices.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildUserInfoCard(
                          icon: Icons.devices_rounded,
                          title: 'connected_devices'.tr(),
                          value:
                              '${vm.userModel!.devices.length} ${'device_count'.tr()}',
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ] else if (!vm.isLoadingUser) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red[400],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'failed_to_load_profile'.tr(),
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Loading state
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      );

  /// 🔖 User Info Card Widget
  Widget _buildUserInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// 🎨 Simple Setting Card Widget
  Widget _buildSimpleSettingCard({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required Widget child,
    bool isButton = false,
    VoidCallback? onTap,
  }) =>
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    const Color(0xFF1E293B).withValues(alpha: 0.8),
                    const Color(0xFF334155).withValues(alpha: 0.6),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFC),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isButton && title == 'logout'.tr()
                          ? Colors.red.withValues(alpha: 0.1)
                          : const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isButton && title == 'logout'.tr()
                          ? Colors.red
                          : const Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isButton && title == 'logout'.tr()
                            ? Colors.red
                            : isDarkMode
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
}
