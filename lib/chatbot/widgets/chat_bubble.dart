import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 6,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),

        constraints: const BoxConstraints(
          maxWidth: 280,
        ),

        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xffA8C5FF)
              : const Color(0xffD9E8FF),

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(
              isUser ? 20 : 5,
            ),
            bottomRight: Radius.circular(
              isUser ? 5 : 20,
            ),
          ),
        ),

        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}