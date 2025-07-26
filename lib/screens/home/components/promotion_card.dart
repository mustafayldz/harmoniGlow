// lib/screens/home/components/static_promotion_card.dart
import 'package:flutter/material.dart';

class StaticPromotionCard extends StatelessWidget {
  const StaticPromotionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 600;

    // Responsive sizing
    final cardHeight = isSmallScreen ? 140.0 : (isMediumScreen ? 150.0 : 160.0);
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final contentPadding = isSmallScreen ? 16.0 : 20.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/song-request'),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          child: Container(
            height: cardHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6366F1), // Indigo
                  Color(0xFF8B5CF6), // Violet
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  blurRadius: isSmallScreen ? 8 : 15,
                  offset: Offset(0, isSmallScreen ? 4 : 8),
                  spreadRadius: isSmallScreen ? 1 : 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Pattern/Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 16 : 20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Content
                Positioned(
                  left: contentPadding,
                  top: contentPadding,
                  bottom: contentPadding,
                  right: contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Title and 24h indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Expanded(
                            child: Text(
                              isSmallScreen
                                  ? 'İstediğin Şarkı\nYok mu?'
                                  : 'İstediğin Şarkı\nListede Yok mu?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen
                                    ? 14
                                    : (isMediumScreen ? 16 : 18),
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Clock animation indicator
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(isSmallScreen ? 8 : 10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white,
                                  size: isSmallScreen ? 12 : 14,
                                ),
                                SizedBox(width: isSmallScreen ? 2 : 4),
                                Text(
                                  '24h',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 8 : 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // Full width description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSmallScreen
                                  ? 'İstek gönder, 24 saat içinde ekleyelim!'
                                  : 'Şarkı isteği gönder, 24 saat içinde listene ekleyelim!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isSmallScreen ? 9 : 10,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const Spacer(),

                            // Action Button at bottom
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 16 : 20,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: isSmallScreen ? 4 : 6,
                                    offset: Offset(0, isSmallScreen ? 2 : 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: const Color(0xFF6366F1),
                                    size: isSmallScreen ? 12 : 14,
                                  ),
                                  SizedBox(width: isSmallScreen ? 3 : 4),
                                  Text(
                                    isSmallScreen
                                        ? 'İstek Gönder'
                                        : 'Şarkı İsteği Gönder',
                                    style: TextStyle(
                                      color: const Color(0xFF6366F1),
                                      fontSize: isSmallScreen ? 9 : 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Shimmer effect overlay
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(isSmallScreen ? 16 : 20),
                    child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, '/song-request'),
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 16 : 20),
                      splashColor: Colors.white.withValues(alpha: 0.1),
                      highlightColor: Colors.white.withValues(alpha: 0.05),
                    ),
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
