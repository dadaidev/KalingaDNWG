import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: const BoxDecoration(
        color: Color(0xffC7F8FF),
      ),

      child: Row(
        children: [

          Expanded(
            child: TextField(
              controller: controller,

              decoration: InputDecoration(
                hintText: "Type message",

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(30),

                  borderSide: BorderSide.none,
                ),

                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          CircleAvatar(
            radius: 24,

            backgroundColor: Colors.white,

            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Color(0xff0A3D75),
              ),

              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}