import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../service/openrouter_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chatbot_appbar.dart';
import '../widgets/message_input.dart';

class ChatbotHome extends StatefulWidget {
  const ChatbotHome({super.key});

  @override
  State<ChatbotHome> createState() => _ChatbotHomeState();
}

class _ChatbotHomeState extends State<ChatbotHome> {
  final TextEditingController controller = TextEditingController();

  /// OpenRouter Service
  final OpenRouterService aiService = OpenRouterService();

  /// Chat Messages
  final List<ChatMessage> messages = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    messages.add(
      const ChatMessage(
        text: "Hello! 👋\nI'm KALINGA AI.\nHow can I help you today?",
        isUser: false,
      ),
    );
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || isLoading) return;

    setState(() {
      messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );

      isLoading = true;
    });

    controller.clear();

    /// Ask OpenRouter AI
    final aiResponse = await aiService.sendMessage(text);

    setState(() {
      messages.add(
        ChatMessage(
          text: aiResponse,
          isUser: false,
        ),
      );

      isLoading = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChatbotAppBar(),

      body: SafeArea(
        child: Column(
          children: [
            /// Chat Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isLoading && index == messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final message = messages[index];

                  return ChatBubble(
                    message: message.text,
                    isUser: message.isUser,
                  );
                },
              ),
            ),

            /// Input Field
            MessageInput(
              controller: controller,
              onSend: sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}