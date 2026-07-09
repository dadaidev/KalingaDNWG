import 'package:flutter/material.dart';

class NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final double buttonSize;

  const NavButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconSize = 24,
    this.backgroundColor = Colors.white,
    this.iconColor = const Color(0xFF1E6FA8),
    this.buttonSize = 50,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}