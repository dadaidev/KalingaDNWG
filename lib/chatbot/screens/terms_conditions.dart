import 'package:flutter/material.dart';

import 'chatbot_home.dart';

class TermsConditions extends StatefulWidget {
  const TermsConditions({super.key});

  @override
  State<TermsConditions> createState() =>
      _TermsConditionsState();
}

class _TermsConditionsState
    extends State<TermsConditions> {

  bool isAccepted = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Terms & Conditions"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Before using KALINGA Chatbot, please read and agree to the following:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Expanded(
              child: SingleChildScrollView(
                child: Text(
"""
1. KALINGA AI is designed to provide general health information only.

2. It is NOT a replacement for professional medical advice.

3. Always consult your doctor before taking medications.

4. Never rely solely on AI during medical emergencies.

5. Your conversations may be stored locally to improve your experience.
""",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            CheckboxListTile(

              value: isAccepted,

              onChanged: (value) {
                setState(() {
                  isAccepted = value!;
                });
              },

              title: const Text(
                "I agree to the Terms and Conditions",
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(

              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: () {

                  if (!isAccepted) {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please accept the Terms and Conditions.",
                        ),
                      ),
                    );

                    return;
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ChatbotHome(),
                    ),
                  );
                },

                child: const Text("CONTINUE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}