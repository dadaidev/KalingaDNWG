import 'package:flutter/material.dart';

import '../chatbot/screens/chatbot_splash.dart';
import 'nav_button.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,

      leadingWidth: 70,

      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: NavButton(
          icon: Icons.account_circle,
          iconSize: 34,
          onTap: () {
            // TODO: Navigate to Profile Page
          },
        ),
      ),

      title: const Text(
        "KALINGA",
        style: TextStyle(
          color: Color(0xFF1E6FA8),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      centerTitle: true,

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: NavButton(
            icon: Icons.chat_bubble_outline,
            iconSize: 26,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatbotSplash(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}