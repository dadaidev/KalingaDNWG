import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,

      backgroundColor: const Color(0xFFD5F6FB),

      selectedItemColor: const Color(0xFF1E6FA8),
      unselectedItemColor: Colors.black54,

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: "Appointment",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.medication),
          label: "Cabinet",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Doctor",
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
      ],
    );
  }
}