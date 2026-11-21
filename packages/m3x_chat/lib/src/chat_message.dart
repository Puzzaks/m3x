import 'dart:typed_data';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// Immutable chat message model for [ChatBubbleList] and [ChatMessageBubble].
class ChatMessage {
  final String sender;
  final String message;
  final bool isUser;
  final String? author;
  final DateTime? timestamp;
  final String? thoughts;
  final bool isLoading;
  final String? loadingLabel;
  final bool isThinkingStreaming;
  final Uint8List? avatarBytes;
  final String? avatarText;
  final IconData? avatarIcon;
  final Color? avatarBackgroundColor;
  final String? imagePath;
  final Uint8List? imageBytes;

  const ChatMessage({
    required this.sender,
    required this.message,
    this.isUser = false,
    this.author,
    this.timestamp,
    this.thoughts,
    this.isLoading = false,
    this.loadingLabel,
    this.isThinkingStreaming = false,
    this.avatarBytes,
    this.avatarText,
    this.avatarIcon,
    this.avatarBackgroundColor,
    this.imagePath,
    this.imageBytes,
  });

  /// Display name resolved from [author] when non-empty, falling back to [sender].
  String get displayAuthor =>
      (author != null && author!.trim().isNotEmpty) ? author!.trim() : sender;

  bool get hasImage =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (imagePath != null && imagePath!.isNotEmpty);

  bool get hasThoughts => thoughts != null && thoughts!.trim().isNotEmpty;

  bool get hasAvatar =>
      (avatarBytes != null && avatarBytes!.isNotEmpty) ||
      (avatarText != null && avatarText!.trim().isNotEmpty) ||
      avatarIcon != null;

  /// Returns a copy of this [ChatMessage] with the specified fields updated.
  ChatMessage copyWith({
    String? sender,
    String? message,
    bool? isUser,
    String? author,
    DateTime? timestamp,
    String? thoughts,
    bool? isLoading,
    String? loadingLabel,
    bool? isThinkingStreaming,
    Uint8List? avatarBytes,
    String? avatarText,
    IconData? avatarIcon,
    Color? avatarBackgroundColor,
    String? imagePath,
    Uint8List? imageBytes,
    bool clearLoadingLabel = false,
    bool clearThoughts = false,
  }) {
    return ChatMessage(
      sender: sender ?? this.sender,
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      thoughts: clearThoughts ? null : (thoughts ?? this.thoughts),
      isLoading: isLoading ?? this.isLoading,
      loadingLabel:
          clearLoadingLabel ? null : (loadingLabel ?? this.loadingLabel),
      isThinkingStreaming: isThinkingStreaming ?? this.isThinkingStreaming,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      avatarText: avatarText ?? this.avatarText,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      avatarBackgroundColor:
          avatarBackgroundColor ?? this.avatarBackgroundColor,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final asInt = int.tryParse(trimmed);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      final asDouble = double.tryParse(trimmed);
      if (asDouble != null && asDouble.isFinite) {
        return DateTime.fromMillisecondsSinceEpoch(asDouble.toInt());
      }
      return DateTime.tryParse(trimmed);
    }
    return null;
  }

  /// Converts a legacy `geminilocal` / `the2k48` conversation map
  /// (`{"user": "User" | "Gemini", "message": "...", ...}`) into a [ChatMessage].
  factory ChatMessage.fromLegacyMap(
    Map<dynamic, dynamic> map, {
    String userIdentifier = 'User',
  }) {
    final String sender = (map['user'] ?? map['sender'])?.toString() ?? '';
    final String msg = map['message']?.toString() ?? '';
    final String? rawAuthor = map['author']?.toString();
    final String? author = (rawAuthor != null && rawAuthor.trim().isNotEmpty)
        ? rawAuthor.trim()
        : null;
    final DateTime? timestamp =
        _parseTimestamp(map['time'] ?? map['timestamp']);
    final String? rawThoughts =
        (map['thoughts'] ?? map['thoughtProcess'])?.toString();
    final String? thoughts =
        (rawThoughts != null && rawThoughts.trim().isNotEmpty)
            ? rawThoughts
            : null;
    final bool isLoading =
        map['isLoading'] == true || map['isLoading']?.toString() == 'true';
    final String? rawLoadingLabel = map['loadingLabel']?.toString();
    final String? loadingLabel =
        (rawLoadingLabel != null && rawLoadingLabel.trim().isNotEmpty)
            ? rawLoadingLabel
            : null;
    final bool isThinkingStreaming = map['isThinkingStreaming'] == true ||
        map['isThinkingStreaming']?.toString() == 'true';
    final String? rawAvatarText = map['avatarText']?.toString();
    final String? avatarText =
        (rawAvatarText != null && rawAvatarText.trim().isNotEmpty)
            ? rawAvatarText.trim()
            : null;
    final Uint8List? avatarBytes = map['avatarBytes'] is Uint8List
        ? map['avatarBytes'] as Uint8List
        : null;
    final IconData? avatarIcon =
        map['avatarIcon'] is IconData ? map['avatarIcon'] as IconData : null;
    final Color? avatarBg = map['avatarBackgroundColor'] is Color
        ? map['avatarBackgroundColor'] as Color
        : null;
    final String? imgPath = map['imagePath']?.toString();
    final Uint8List? imgBytes =
        map['imageBytes'] is Uint8List ? map['imageBytes'] as Uint8List : null;

    return ChatMessage(
      sender: sender,
      message: msg,
      isUser: map['isUser'] is bool
          ? map['isUser'] as bool
          : sender == userIdentifier,
      author: author,
      timestamp: timestamp,
      thoughts: thoughts,
      isLoading: isLoading,
      loadingLabel: loadingLabel,
      isThinkingStreaming: isThinkingStreaming,
      avatarBytes: avatarBytes,
      avatarText: avatarText,
      avatarIcon: avatarIcon,
      avatarBackgroundColor: avatarBg,
      imagePath: (imgPath != null && imgPath.isNotEmpty) ? imgPath : null,
      imageBytes: imgBytes,
    );
  }

  /// Converts this [ChatMessage] back into a legacy string conversation map.
  Map<String, String> toLegacyMap() => {
        'user': sender,
        'message': message,
        if (author != null && author!.isNotEmpty) 'author': author!,
        if (timestamp != null)
          'time': timestamp!.millisecondsSinceEpoch.toString(),
        if (thoughts != null && thoughts!.isNotEmpty) 'thoughts': thoughts!,
        if (isLoading) 'isLoading': 'true',
        if (loadingLabel != null && loadingLabel!.isNotEmpty)
          'loadingLabel': loadingLabel!,
        if (imagePath != null && imagePath!.isNotEmpty) 'imagePath': imagePath!,
      };

  /// Converts this [ChatMessage] into a structured JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'sender': sender,
        'message': message,
        'isUser': isUser,
        if (author != null && author!.isNotEmpty) 'author': author,
        if (timestamp != null) 'time': timestamp!.millisecondsSinceEpoch,
        if (thoughts != null && thoughts!.isNotEmpty) 'thoughts': thoughts,
        'isLoading': isLoading,
        if (loadingLabel != null && loadingLabel!.isNotEmpty)
          'loadingLabel': loadingLabel,
        'isThinkingStreaming': isThinkingStreaming,
        if (avatarText != null && avatarText!.isNotEmpty)
          'avatarText': avatarText,
        if (imagePath != null && imagePath!.isNotEmpty) 'imagePath': imagePath,
      };
}
