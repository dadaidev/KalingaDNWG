import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_keys.dart';
import '../../config/app_constants.dart';

class OpenRouterService {
  Future<String> sendMessage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.openRouterUrl),
        headers: {
          "Authorization": "Bearer ${ApiKeys.openRouterApiKey}",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://kalinga.app",
          "X-Title": AppConstants.appName,
        },
        body: jsonEncode({
          "model": AppConstants.aiModel,
          "messages": [
            {
              "role": "system",
              "content": """
You are ${AppConstants.chatbotName}.

You are a healthcare assistant for a Medication Reminder application.

Rules:
- Answer medication-related questions politely.
- Encourage users to follow their doctor's advice.
- Never diagnose diseases.
- Never prescribe medicine.
- Never recommend changing medication dosage.
- If the question is unrelated to health or medication, politely answer briefly.
- Keep answers easy to understand.
- If you don't know the answer, tell the user to consult a healthcare professional.
"""
            },
            {
             
            }
          ],
          
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data["choices"][0]["message"]["content"];
      }

      if (response.statusCode == 401) {
        return "Invalid API Key.";
      }

      if (response.statusCode == 429) {
        return "Too many requests. Please try again later.";
      }

      return "Error ${response.statusCode}\n${response.body}";
    } catch (e) {
      return "Connection Error:\n$e";
    }
  }
}