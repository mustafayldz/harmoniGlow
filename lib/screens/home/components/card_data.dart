import 'package:flutter/material.dart';

class CardData {
  CardData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.gradient,
  });
  final String key;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final LinearGradient gradient;
}
