import 'dart:async';

import 'package:drumly/models/announcement_model.dart';
import 'package:drumly/screens/player/songv2_player_view.dart';
import 'package:drumly/services/announcement_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementCarousel extends StatefulWidget {
  const AnnouncementCarousel({super.key});

  @override
  State<AnnouncementCarousel> createState() => _AnnouncementCarouselState();
}

class _AnnouncementCarouselState extends State<AnnouncementCarousel> {
  final AnnouncementService _service = AnnouncementService();
  late final PageController _pageController;
  Timer? _timer;
  List<AnnouncementModel> _announcements = const [];
  int _currentPage = 0;
  String? _loadedLanguage;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.locale.languageCode;
    if (_loadedLanguage == language) return;
    _loadedLanguage = language;
    unawaited(_loadAnnouncements(language));
  }

  Future<void> _loadAnnouncements(String language) async {
    final generation = ++_loadGeneration;
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    var announcements = await _service.getAnnouncements(language: language);
    if (announcements != null &&
        announcements.isEmpty &&
        language.toLowerCase() != 'en') {
      announcements = await _service.getAnnouncements(language: 'en');
    }
    if (!mounted || generation != _loadGeneration) return;

    setState(() {
      _announcements = announcements ?? const [];
      _currentPage = 0;
      _isLoading = false;
      _hasError = announcements == null;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_announcements.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _announcements.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _AnnouncementLoading();
    }
    if (_hasError) {
      return _AnnouncementError(
        onRetry: () => _loadAnnouncements(
          _loadedLanguage ?? context.locale.languageCode,
        ),
      );
    }
    if (_announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final announcements = _announcements;
    return Column(
      children: [
        SizedBox(
          height: 208,
          child: PageView.builder(
            controller: _pageController,
            itemCount: announcements.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => _AnnouncementCard(
              announcement: announcements[index],
              onTap: _canHandle(announcements[index])
                  ? () => _handleAction(context, announcements[index])
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            announcements.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: index == _currentPage ? 18 : 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              decoration: BoxDecoration(
                color: index == _currentPage
                    ? const Color(0xFF6C5CE7)
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canHandle(AnnouncementModel announcement) {
    final value = announcement.actionValue?.trim() ?? '';
    return value.isNotEmpty &&
        const {'internal_route', 'external_url', 'song'}
            .contains(announcement.actionType);
  }

  Future<void> _handleAction(
    BuildContext context,
    AnnouncementModel announcement,
  ) async {
    final value = announcement.actionValue?.trim();
    if (value == null || value.isEmpty) return;

    switch (announcement.actionType) {
      case 'internal_route':
        await Navigator.pushNamed(context, value);
        return;
      case 'external_url':
        final uri = Uri.tryParse(value);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return;
      case 'song':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongV2PlayerView(songv2Id: value),
          ),
        );
        return;
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
  });

  final AnnouncementModel announcement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = announcement.imageUrl?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171A22) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF080910).withValues(alpha: 0.92),
                          const Color(0xFF080910).withValues(alpha: 0.58),
                          const Color(0xFF080910).withValues(alpha: 0.08),
                        ],
                        stops: const [0, 0.56, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Text(
                              'announcement'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.65,
                        child: Text(
                          announcement.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            height: 1.02,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              announcement.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.74),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (onTap != null) ...[
                            const SizedBox(width: 12),
                            if (announcement.buttonText?.trim().isNotEmpty ??
                                false) ...[
                              Text(
                                announcement.buttonText!.trim(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.arrow_outward_rounded,
                                color: Color(0xFF12131A),
                                size: 17,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementLoading extends StatelessWidget {
  const _AnnouncementLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 208,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.055) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Color(0xFF6C5CE7),
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}

class _AnnouncementError extends StatelessWidget {
  const _AnnouncementError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.055) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 92,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF6C5CE7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'announcement_load_error'.tr(),
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: onSurface.withValues(alpha: 0.28),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
