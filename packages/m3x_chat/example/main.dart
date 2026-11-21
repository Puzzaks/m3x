// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:m3x_chat/m3x_chat.dart';

void main() {
  runApp(const M3xChatExampleApp());
}

class M3xChatExampleApp extends StatelessWidget {
  const M3xChatExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('m3x_chat Example')),
        body: const ChatBubbleList(
          messages: [
            ChatMessage(
              sender: 'User',
              isUser: true,
              message: 'Hello! Show me a Material 3 eXtended chat bubble.',
            ),
            ChatMessage(
              sender: 'Assistant',
              isUser: false,
              author: 'Assistant',
              thoughts:
                  'Preparing a concise Markdown reply with reasoning block.',
              message:
                  'Here is a **Markdown** response rendered by `m3x_chat`.',
            ),
          ],
        ),
      ),
    );
  }
}
