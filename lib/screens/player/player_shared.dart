import 'package:flutter/material.dart';

Widget controlButton({
  IconData? icon,
  VoidCallback? onPressed,
  double iconSize = 32,
  String? imagePath,
  Color? backgroundColor,
}) =>
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: imagePath != null
            ? Image.asset(
                imagePath,
                width: 24,
                height: 24,
                color: backgroundColor != null ? Colors.white : Colors.black,
              )
            : Icon(icon, size: iconSize, color: Colors.black),
        onPressed: onPressed,
      ),
    );
