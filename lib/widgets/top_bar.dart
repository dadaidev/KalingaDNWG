import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Colors.white,

      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: IconButton(
          onPressed: () {
            // TODO: Open Profile Page
          },
          icon: const Icon(
            Icons.account_circle,
            color: Color(0xFF1E6FA8),
            size: 40,
          ),
        ),
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: () {
              // TODO: Open ChatBot
            },
            icon: const Icon(
              Icons.chat_bubble,
              color: Color(0xFF1E6FA8),
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}