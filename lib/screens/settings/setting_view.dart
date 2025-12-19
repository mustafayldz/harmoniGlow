import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/home/home_view.dart';
import 'package:drumly/screens/settings/settings_viewmodel.dart';
import 'package:drumly/shared/app_gradients.dart';
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
  
  // 🚀 OPTIMIZATION: Cache frequently used values
  late bool _isDarkMode;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SettingViewModel>(context);
    final appProvider = vm.appProvider;
    final bluetoothState = context.watch<BluetoothBloc>().state;

    return Scaffold(
      body: DecoratedBox(
        decoration: AppDecorations.backgroundDecoration(_isDarkMode),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Modern App Bar
              _buildModernAppBar(context),

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
                          _buildProfileSection(vm),
                          const SizedBox(height: 24),

                          // Dark Mode Toggle
                          _SettingCard(
                            isDarkMode: _isDarkMode,
                            icon: Icons.brightness_6_outlined,
                            title: 'darkMode'.tr(),
                            child: Switch(
                              value: appProvider.isDarkMode,
                              onChanged: (_) => vm.toggleTheme(),
                              activeThumbColor: AppGradients.primaryAccent,
                              activeTrackColor: AppGradients.primaryAccent
                                  .withValues(alpha: 0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor:
                                  Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Countdown Adjust
                          _SettingCard(
                            isDarkMode: _isDarkMode,
                            icon: Icons.timer_outlined,
                            title: 'adjustCountdown'.tr(),
                            child: _CountdownControl(
                              isDarkMode: _isDarkMode,
                              value: appProvider.countdownValue,
                              onDecrease: () => vm.adjustCountdown(false),
                              onIncrease: () => vm.adjustCountdown(true),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Drum Type Toggle (only if connected)
                          if (bluetoothState.isConnected) ...[
                            _SettingCard(
                              isDarkMode: _isDarkMode,
                              icon: Icons.music_note_outlined,
                              title: 'drumType'.tr(),
                              child: _DrumTypeSelector(
                                isDarkMode: _isDarkMode,
                                isClassic: appProvider.isClassic,
                                onElectronic: () => vm.setDrumStyle(false),
                                onClassic: () => vm.setDrumStyle(true),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Language Selector
                          _SettingCard(
                            isDarkMode: _isDarkMode,
                            icon: Icons.language_outlined,
                            title: 'language'.tr(),
                            child: _LanguageSelector(isDarkMode: _isDarkMode),
                          ),
                          const SizedBox(height: 16),

                          // App Info
                          _SettingCard(
                            isDarkMode: _isDarkMode,
                            icon: Icons.info_outlined,
                            title: 'appInformation'.tr(),
                            child: _AppInfo(
                              isDarkMode: _isDarkMode,
                              version: vm.version,
                              buildNumber: vm.buildNumber,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Logout Button
                          _SettingCard(
                            isDarkMode: _isDarkMode,
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
                          const SizedBox(height: 16),

                          // Delete Account Button
                          _SettingCard(
                            isDarkMode: _isDarkMode,
                            icon: Icons.delete_forever_rounded,
                            title: 'deleteAccount'.tr(),
                            isButton: true,
                            onTap: () => vm.deleteAccount(context),
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

  Widget _buildModernAppBar(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          children: [
            DecoratedBox(
              decoration: AppDecorations.iconContainerDecoration(_isDarkMode),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textColor(_isDarkMode),
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
                  color: AppColors.textColor(_isDarkMode),
                ),
              ),
            ),
          ],
        ),
      );

  /// 🎨 Profile Section - Modern Design with Expandable
  Widget _buildProfileSection(SettingViewModel vm) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.cardGradient(_isDarkMode, alphaStart: 0.9, alphaEnd: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor(_isDarkMode)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isProfileExpanded = !_isProfileExpanded),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  _ProfileHeader(
                    isDarkMode: _isDarkMode,
                    isExpanded: _isProfileExpanded,
                    isLoading: vm.isLoadingUser,
                    email: vm.userModel?.email,
                  ),

                  // Expandable Content
                  if (_isProfileExpanded) ...[
                    const SizedBox(height: 20),
                    if (vm.userModel != null) ...[
                      _UserInfoCard(
                        icon: Icons.email_rounded,
                        title: 'email'.tr(),
                        value: vm.userModel!.email,
                        isDarkMode: _isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _UserInfoCard(
                        icon: Icons.badge_rounded,
                        title: 'name'.tr(),
                        value: vm.userModel!.name,
                        isDarkMode: _isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _UserInfoCard(
                        icon: Icons.library_music_rounded,
                        title: 'assigned_songs'.tr(),
                        value: '${vm.userModel!.assignedSongIds.length} ${'song_count'.tr()}',
                        isDarkMode: _isDarkMode,
                      ),
                      if (vm.userModel!.devices.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _UserInfoCard(
                          icon: Icons.devices_rounded,
                          title: 'connected_devices'.tr(),
                          value: '${vm.userModel!.devices.length} ${'device_count'.tr()}',
                          isDarkMode: _isDarkMode,
                        ),
                      ],
                    ] else if (!vm.isLoadingUser) ...[
                      _ErrorCard(isDarkMode: _isDarkMode),
                    ] else ...[
                      const _LoadingCard(),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

// ===== EXTRACTED WIDGETS FOR BETTER PERFORMANCE =====

/// 🎨 Profile Header Widget
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.isDarkMode,
    required this.isExpanded,
    required this.isLoading,
    this.email,
  });
  
  final bool isDarkMode;
  final bool isExpanded;
  final bool isLoading;
  final String? email;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppGradients.primaryAccent,
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
                color: AppColors.textColor(isDarkMode),
              ),
            ),
            if (!isExpanded)
              Text(
                email ?? 'tap_to_view'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      if (isLoading)
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      else
        Icon(
          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
    ],
  );
}

/// 🔖 User Info Card Widget
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDarkMode,
  });
  
  final IconData icon;
  final String title;
  final String value;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.overlayColor(isDarkMode, alpha: isDarkMode ? 0.05 : 0.02),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor(isDarkMode)),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.secondaryTextColor(isDarkMode),
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
                  color: AppColors.textColor(isDarkMode, alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// ❌ Error Card Widget
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.isDarkMode});
  
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: isDarkMode ? 0.1 : 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'failed_to_load_profile'.tr(),
            style: TextStyle(color: Colors.red[400], fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

/// ⏳ Loading Card Widget
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    child: const Center(child: CircularProgressIndicator()),
  );
}

/// 🎨 Setting Card Widget
class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.isDarkMode,
    required this.icon,
    required this.title,
    required this.child,
    this.isButton = false,
    this.onTap,
  });
  
  final bool isDarkMode;
  final IconData icon;
  final String title;
  final Widget child;
  final bool isButton;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: AppGradients.cardGradient(isDarkMode),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderColor(isDarkMode)),
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
                decoration: AppDecorations.accentIconContainerDecoration(
                  color: isButton && title == 'logout'.tr() ? Colors.red : null,
                ),
                child: Icon(
                  icon,
                  color: isButton && title == 'logout'.tr()
                      ? Colors.red
                      : AppGradients.primaryAccent,
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
                        : AppColors.textColor(isDarkMode),
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

/// ⏱️ Countdown Control Widget
class _CountdownControl extends StatelessWidget {
  const _CountdownControl({
    required this.isDarkMode,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });
  
  final bool isDarkMode;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.remove_rounded),
        onPressed: onDecrease,
        color: AppColors.textColor(isDarkMode),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppDecorations.chipDecoration(isDarkMode),
        child: Text(
          '$value s',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor(isDarkMode),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add_rounded),
        onPressed: onIncrease,
        color: AppColors.textColor(isDarkMode),
      ),
    ],
  );
}

/// 🎵 Drum Type Selector Widget
class _DrumTypeSelector extends StatelessWidget {
  const _DrumTypeSelector({
    required this.isDarkMode,
    required this.isClassic,
    required this.onElectronic,
    required this.onClassic,
  });
  
  final bool isDarkMode;
  final bool isClassic;
  final VoidCallback onElectronic;
  final VoidCallback onClassic;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: !isClassic
              ? AppGradients.primaryAccent
              : AppColors.overlayColor(isDarkMode),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: onElectronic,
          child: Text(
            'electronic'.tr(),
            style: TextStyle(
              color: !isClassic ? Colors.white : AppColors.textColor(isDarkMode),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      DecoratedBox(
        decoration: BoxDecoration(
          color: isClassic
              ? AppGradients.primaryAccent
              : AppColors.overlayColor(isDarkMode),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: onClassic,
          child: Text(
            'classic'.tr(),
            style: TextStyle(
              color: isClassic ? Colors.white : AppColors.textColor(isDarkMode),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}

/// 🌐 Language Selector Widget
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.isDarkMode});
  
  final bool isDarkMode;

  static const _locales = [
    (Locale('en'), 'English'),
    (Locale('tr'), 'Türkçe'),
    (Locale('es'), 'Español'),
    (Locale('fr'), 'Français'),
    (Locale('ru'), 'Русский'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: AppDecorations.chipDecoration(isDarkMode),
    child: DropdownButton<Locale>(
      value: context.locale,
      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
      icon: Icon(
        Icons.arrow_drop_down,
        color: AppColors.textColor(isDarkMode),
      ),
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(8),
      onChanged: (Locale? newLocale) async {
        if (newLocale != null) {
          await context.setLocale(newLocale);
          if (context.mounted) {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeView()),
            );
          }
        }
      },
      items: _locales.map((locale) => DropdownMenuItem(
        value: locale.$1,
        child: Text(
          locale.$2,
          style: TextStyle(color: AppColors.textColor(isDarkMode)),
        ),
      ),).toList(),
    ),
  );
}

/// ℹ️ App Info Widget
class _AppInfo extends StatelessWidget {
  const _AppInfo({
    required this.isDarkMode,
    required this.version,
    required this.buildNumber,
  });
  
  final bool isDarkMode;
  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        'Version: $version',
        style: TextStyle(
          color: AppColors.textColor(isDarkMode, alpha: 0.8),
          fontSize: 14,
        ),
      ),
      Text(
        'Build #: $buildNumber',
        style: TextStyle(
          color: AppColors.textColor(isDarkMode, alpha: 0.8),
          fontSize: 14,
        ),
      ),
    ],
  );
}
