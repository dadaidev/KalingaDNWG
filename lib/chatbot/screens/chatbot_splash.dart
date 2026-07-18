import 'package:flutter/material.dart';
import 'terms_conditions.dart';

class ChatbotSplash extends StatelessWidget {
  const ChatbotSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("lib/Assets/chatbot_kalinga.png", width: 220),

                const SizedBox(height: 25),

                const Text(
                  "Hello!\nHow can I help you?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0A3D75),
                  ),
                ),

                const SizedBox(height: 80),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0A3D75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsConditions(),
                        ),
                      );
                    },

                    child: const Text(
                      "START CHAT",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
