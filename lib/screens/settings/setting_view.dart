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

    return Scaffold(
      backgroundColor:
          _isDarkMode ? const Color(0xFF070A10) : const Color(0xFFF5F6F8),
      body: ColoredBox(
        color: _isDarkMode ? const Color(0xFF070A10) : const Color(0xFFF5F6F8),
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
                          const SizedBox(height: 20),

                          // Dark Mode Toggle
                          _SettingCard(
                            isDarkMode: _isDarkMode,
                            icon: Icons.brightness_6_outlined,
                            title: 'darkMode'.tr(),
                            child: Switch(
                              value: appProvider.isDarkMode,
                              onChanged: (_) => vm.toggleTheme(),
                              activeThumbColor: const Color(0xFF6C5CE7),
                              activeTrackColor: const Color(0xFF6C5CE7)
                                  .withValues(alpha: 0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor:
                                  Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 12),

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
                          const SizedBox(height: 12),

                          // Language Selector
                          _SettingCard(
                            isDarkMode: _isDarkMode,
                            icon: Icons.language_outlined,
                            title: 'language'.tr(),
                            child: _LanguageSelector(isDarkMode: _isDarkMode),
                          ),
                          const SizedBox(height: 12),

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
                          const SizedBox(height: 20),

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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.88)
                      : const Color(0xFF252733),
                  size: 21,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'settings'.tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _isDarkMode ? Colors.white : const Color(0xFF171820),
                  letterSpacing: -0.7,
                ),
              ),
            ),
          ],
        ),
      );

  /// 🎨 Profile Section - Modern Design with Expandable
  Widget _buildProfileSection(SettingViewModel vm) => DecoratedBox(
        decoration: BoxDecoration(
          color:
              _isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isDarkMode ? 0.14 : 0.045,
              ),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () =>
                setState(() => _isProfileExpanded = !_isProfileExpanded),
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                        value:
                            '${vm.userModel!.assignedSongIds.length} ${'song_count'.tr()}',
                        isDarkMode: _isDarkMode,
                      ),
                      if (vm.userModel!.devices.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _UserInfoCard(
                          icon: Icons.devices_rounded,
                          title: 'connected_devices'.tr(),
                          value:
                              '${vm.userModel!.devices.length} ${'device_count'.tr()}',
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 22,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textColor(isDarkMode),
                    letterSpacing: -0.3,
                  ),
                ),
                if (!isExpanded)
                  Text(
                    email ?? 'tap_to_view'.tr(),
                    style: TextStyle(
                      fontSize: 12,
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
              isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.045)
              : const Color(0xFFF6F5FA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.065)
                : Colors.black.withValues(alpha: 0.035),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.78),
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
          color:
              isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDarkMode ? 0.12 : 0.04,
              ),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (isButton && title == 'logout'.tr()
                              ? Colors.red
                              : const Color(0xFF6C5CE7))
                          .withValues(alpha: isDarkMode ? 0.17 : 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isButton && title == 'logout'.tr()
                          ? Colors.red
                          : isDarkMode
                              ? const Color(0xFFB8B0FF)
                              : const Color(0xFF6C5CE7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isButton && title == 'logout'.tr()
                            ? Colors.red
                            : AppColors.textColor(isDarkMode),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
          IconButton.filledTonal(
            icon: const Icon(Icons.remove_rounded, size: 16),
            onPressed: onDecrease,
            color: AppColors.textColor(isDarkMode),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              maximumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
              backgroundColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFF2F1F8),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(
                alpha: isDarkMode ? 0.18 : 0.10,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$value s',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDarkMode
                    ? const Color(0xFFCAC5FF)
                    : const Color(0xFF6C5CE7),
              ),
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.add_rounded, size: 16),
            onPressed: onIncrease,
            color: AppColors.textColor(isDarkMode),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              maximumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
              backgroundColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFF2F1F8),
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
        constraints: const BoxConstraints(maxWidth: 112),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFF2F1F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<Locale>(
          isExpanded: true,
          value: context.locale,
          dropdownColor: isDarkMode ? const Color(0xFF1B1E27) : Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppColors.textColor(isDarkMode),
          ),
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(14),
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
          items: _locales
              .map(
                (locale) => DropdownMenuItem(
                  value: locale.$1,
                  child: Text(
                    locale.$2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textColor(isDarkMode),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
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
              color: AppColors.textColor(isDarkMode, alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Build #: $buildNumber',
            style: TextStyle(
              color: AppColors.textColor(isDarkMode, alpha: 0.46),
              fontSize: 10,
            ),
          ),
        ],
      );
}
