// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:m3x_ui/m3x_ui.dart';

import 'chat_bubble.dart';
import 'chat_message.dart';

/// Renders a list of [ChatMessage] bubbles along with an optional
/// [pendingUserMessage] and live [streamingAiChunk].
class ChatBubbleList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String pendingUserMessage;
  final String streamingAiChunk;
  final String userIdentifier;
  final String aiIdentifier;
  final bool showAvatar;
  final bool initiallyExpandedMetadata;
  final String? thinkingInProgressLabel;
  final String? thoughtProcessLabel;
  final String Function(DateTime)? formatTimestamp;
  final MarkdownStyleSheet? markdownStyleSheet;
  final double? maxBubbleWidth;
  final Widget? Function(
    BuildContext context,
    ChatMessage message,
    int index,
  )? customContentBuilder;
  final Widget? Function(
    BuildContext context,
    ChatMessage message,
    int index,
  )? thoughtsTrailingBuilder;

  const ChatBubbleList({
    super.key,
    required this.messages,
    this.pendingUserMessage = '',
    this.streamingAiChunk = '',
    this.userIdentifier = 'User',
    this.aiIdentifier = 'Gemini',
    this.showAvatar = false,
    this.initiallyExpandedMetadata = false,
    this.thinkingInProgressLabel,
    this.thoughtProcessLabel,
    this.formatTimestamp,
    this.markdownStyleSheet,
    this.maxBubbleWidth,
    this.customContentBuilder,
    this.thoughtsTrailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final chatHelper = ChatTextPart();
    final widgets = chatHelper.chatlogFromMessages(
      messages: messages,
      pendingUserMessage: pendingUserMessage,
      streamingAiChunk: streamingAiChunk,
      userIdentifier: userIdentifier,
      aiIdentifier: aiIdentifier,
      showAvatar: showAvatar,
      initiallyExpandedMetadata: initiallyExpandedMetadata,
      thinkingInProgressLabel: thinkingInProgressLabel,
      thoughtProcessLabel: thoughtProcessLabel,
      formatTimestamp: formatTimestamp,
      markdownStyleSheet: markdownStyleSheet,
      maxBubbleWidth: maxBubbleWidth,
      customContentBuilder: customContentBuilder != null
          ? (msg, index) => customContentBuilder!(context, msg, index)
          : null,
      thoughtsTrailingBuilder: thoughtsTrailingBuilder != null
          ? (msg, index) => thoughtsTrailingBuilder!(context, msg, index)
          : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

/// Drop-in backwards-compatible replacement for the `text` class in
/// `geminilocal`, `the2k48`, and `Website` that includes Markdown chat-bubble
/// rendering (`chatlog`).
///
/// Fixes the duplicate-filtering bug in `geminilocal` where
/// `!(lastUser == userMessage)` hid ALL historical messages matching `lastUser`.
class ChatTextPart extends TextPart {
  static Widget info({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required BuildContext context,
  }) =>
      TextPart.info(
        title: title,
        subtitle: subtitle,
        action: action,
        context: context,
      );

  static Widget infoShort({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required BuildContext context,
  }) =>
      TextPart.infoShort(
        title: title,
        subtitle: subtitle,
        action: action,
        context: context,
      );

  /// Renders a list of [ChatMessageBubble] widgets from structured [ChatMessage]
  /// objects plus optional [pendingUserMessage] and [streamingAiChunk].
  List<Widget> chatlogFromMessages({
    required List<ChatMessage> messages,
    String pendingUserMessage = '',
    String streamingAiChunk = '',
    String userIdentifier = 'User',
    String aiIdentifier = 'Gemini',
    bool showAvatar = false,
    bool initiallyExpandedMetadata = false,
    String? thinkingInProgressLabel,
    String? thoughtProcessLabel,
    String Function(DateTime)? formatTimestamp,
    MarkdownStyleSheet? markdownStyleSheet,
    double? maxBubbleWidth,
    Widget? Function(ChatMessage message, int index)? customContentBuilder,
    Widget? Function(ChatMessage message, int index)? thoughtsTrailingBuilder,
  }) {
    final List<Widget> bubbles = [];

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg.message.isEmpty &&
          !msg.hasImage &&
          !msg.hasThoughts &&
          !msg.isLoading) {
        continue;
      }

      final bool isLast = i == messages.length - 1;
      // Only skip the final message if it duplicates the active pending user
      // message or streaming AI chunk (preserving all earlier identical messages).
      if (isLast &&
          msg.isUser &&
          !msg.hasImage &&
          !msg.isLoading &&
          msg.message == pendingUserMessage) {
        continue;
      }
      if (isLast &&
          !msg.isUser &&
          !msg.hasThoughts &&
          !msg.isLoading &&
          msg.message == streamingAiChunk) {
        continue;
      }

      bubbles.add(
        ChatMessageBubble(
          message: msg,
          showAvatar: showAvatar,
          initiallyExpandedMetadata: initiallyExpandedMetadata,
          thinkingInProgressLabel: thinkingInProgressLabel,
          thoughtProcessLabel: thoughtProcessLabel,
          formatTimestamp: formatTimestamp,
          markdownStyleSheet: markdownStyleSheet,
          maxBubbleWidth: maxBubbleWidth,
          customContent: customContentBuilder?.call(msg, i),
          thoughtsTrailing: thoughtsTrailingBuilder?.call(msg, i),
        ),
      );
    }

    if (pendingUserMessage.isNotEmpty) {
      bubbles.add(
        ChatMessageBubble(
          message: ChatMessage(
            sender: userIdentifier,
            message: pendingUserMessage,
            isUser: true,
          ),
          showAvatar: showAvatar,
          initiallyExpandedMetadata: initiallyExpandedMetadata,
          thinkingInProgressLabel: thinkingInProgressLabel,
          thoughtProcessLabel: thoughtProcessLabel,
          formatTimestamp: formatTimestamp,
          markdownStyleSheet: markdownStyleSheet,
          maxBubbleWidth: maxBubbleWidth,
        ),
      );
    }

    if (streamingAiChunk.isNotEmpty) {
      bubbles.add(
        ChatMessageBubble(
          message: ChatMessage(
            sender: aiIdentifier,
            message: streamingAiChunk,
            isUser: false,
          ),
          showAvatar: showAvatar,
          initiallyExpandedMetadata: initiallyExpandedMetadata,
          thinkingInProgressLabel: thinkingInProgressLabel,
          thoughtProcessLabel: thoughtProcessLabel,
          formatTimestamp: formatTimestamp,
          markdownStyleSheet: markdownStyleSheet,
          maxBubbleWidth: maxBubbleWidth,
        ),
      );
    }

    return bubbles;
  }

  /// Backwards-compatible `chatlog` method accepting the legacy `conversation`
  /// list of maps (`[{"user": "User", "message": "...", "imagePath": "..."}, ...]`).
  List<Widget> chatlog({
    required String aiChunk,
    required String lastUser,
    required List conversation,
    required BuildContext context,
    String userIdentifier = 'User',
    String aiIdentifier = 'Gemini',
    bool showAvatar = false,
    bool initiallyExpandedMetadata = false,
    String? thinkingInProgressLabel,
    String? thoughtProcessLabel,
    String Function(DateTime)? formatTimestamp,
    MarkdownStyleSheet? markdownStyleSheet,
    double? maxBubbleWidth,
    bool isContinuing = false,
    String? continuingLabel,
  }) {
    final List<ChatMessage> parsed = conversation
        .whereType<Map>()
        .map(
          (m) => ChatMessage.fromLegacyMap(
            m,
            userIdentifier: userIdentifier,
          ),
        )
        .toList();

    if (isContinuing &&
        aiChunk.isEmpty &&
        parsed.isNotEmpty &&
        !parsed.last.isUser) {
      parsed[parsed.length - 1] = parsed.last.copyWith(
        isLoading: true,
        loadingLabel: continuingLabel ?? parsed.last.loadingLabel,
      );
    }

    final bubbles = chatlogFromMessages(
      messages: parsed,
      pendingUserMessage: lastUser,
      streamingAiChunk: isContinuing && aiChunk.isNotEmpty ? '' : aiChunk,
      userIdentifier: userIdentifier,
      aiIdentifier: aiIdentifier,
      showAvatar: showAvatar,
      initiallyExpandedMetadata: initiallyExpandedMetadata,
      thinkingInProgressLabel: thinkingInProgressLabel,
      thoughtProcessLabel: thoughtProcessLabel,
      formatTimestamp: formatTimestamp,
      markdownStyleSheet: markdownStyleSheet,
      maxBubbleWidth: maxBubbleWidth,
    );

    if (isContinuing && aiChunk.isNotEmpty) {
      bubbles.add(
        ChatMessageBubble(
          message: ChatMessage(
            sender: aiIdentifier,
            message: aiChunk,
            isUser: false,
            isLoading: true,
            loadingLabel: continuingLabel,
          ),
          showAvatar: showAvatar,
          initiallyExpandedMetadata: initiallyExpandedMetadata,
          thinkingInProgressLabel: thinkingInProgressLabel,
          thoughtProcessLabel: thoughtProcessLabel,
          formatTimestamp: formatTimestamp,
          markdownStyleSheet: markdownStyleSheet,
          maxBubbleWidth: maxBubbleWidth,
        ),
      );
    }

    return bubbles;
  }
}
