import 'package:flutter/material.dart';

/// Shared color palette for the Doctor / "My Doctors" flow.
/// Kept separate (like CabinetColors) so all doctor-related screens
/// and widgets stay visually consistent.
class DoctorColors {
  DoctorColors._();

  static const Color pageBackground = Colors.white;
  static const Color cardBackground = Color(0xFFBFD9E0); // light teal card
  static const Color avatarBackground = Color(0xFF6FA8B4);
  static const Color titleText = Color(0xFF1B1B1B);
  static const Color subtitleText = Color(0xFF5A6B70);

  static const Color activeGreen = Color(0xFF3FB86D);
  static const Color inactiveOrange = Color(0xFFE99A4B);

  static const Color addGreen = Color(0xFF3FB86D);
  static const Color deleteRed = Color(0xFFE64545);
  static const Color cancelGrey = Color(0xFF8A9A9E);

  static const Color dialogTeal = Color(0xFF2E7C8A);

  static const Color inputFill = Colors.white;
  static const Color inputBorder = Color(0xFF8FB8C2);
}