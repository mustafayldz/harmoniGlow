import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RequestSongCard extends StatelessWidget {
  const RequestSongCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/song-request'),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.065)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.black.withValues(alpha: 0.055),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.16 : 0.055,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.library_add_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'request_song'.tr(),
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'request_song_card_desc'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDarkMode
                              ? onSurface.withValues(alpha: 0.48)
                              : onSurface.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF6C5CE7),
                    size: 17,
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
