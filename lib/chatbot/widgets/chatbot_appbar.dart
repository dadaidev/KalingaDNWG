import 'package:flutter/material.dart';

class ChatbotAppBar extends StatelessWidget
    implements PreferredSizeWidget {

  const ChatbotAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {

    return AppBar(

      automaticallyImplyLeading: false,

      backgroundColor: const Color(0xffC7F8FF),

      elevation: 0,

      leading: IconButton(

        icon: const Icon(
          Icons.arrow_back,
          color: Colors.black,
          size: 30,
        ),

        onPressed: () {
          Navigator.pop(context);
        },
      ),

      title: const Text(
        "KALINGA",

        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),

      centerTitle: true,
    );
  }
}