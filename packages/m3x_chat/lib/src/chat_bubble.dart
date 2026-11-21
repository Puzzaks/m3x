import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_message.dart';
import 'chat_skeleton.dart';
import 'chat_thoughts.dart';

/// Renders a single chat message bubble:
/// - User messages are right-aligned inside a high-contrast rounded Material 3
///   card (`colorScheme.onSecondaryContainer` with `colorScheme.onSecondary` text).
/// - AI/assistant messages are left-aligned inside a surface card with
///   selectable [MarkdownBody] and safe external link launching.
/// - Supports optional [imagePath] or [imageBytes] rendered as a rounded
///   thumbnail (`BorderRadius.circular(12)`, max height `200`, `BoxFit.cover`)
///   above the message text with a tap-to-zoom full-screen [InteractiveViewer] dialog.
/// - Supports optional [ChatThoughtsBlock], animated [ChatAnimatedSkeleton] loading
///   indicator, optional [CircleAvatar] (`showAvatar`), custom body slot
///   ([customContent]), and tap-to-reveal author & timestamp metadata.
class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final double? maxBubbleWidth;
  final String? imagePath;
  final Uint8List? imageBytes;
  final bool showAvatar;
  final Widget? customContent;
  final Widget? thoughtsTrailing;
  final String? thinkingInProgressLabel;
  final String? thoughtProcessLabel;
  final String Function(DateTime)? formatTimestamp;
  final MarkdownStyleSheet? markdownStyleSheet;
  final bool initiallyExpandedMetadata;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.maxBubbleWidth,
    this.imagePath,
    this.imageBytes,
    this.showAvatar = false,
    this.customContent,
    this.thoughtsTrailing,
    this.thinkingInProgressLabel,
    this.thoughtProcessLabel,
    this.formatTimestamp,
    this.markdownStyleSheet,
    this.initiallyExpandedMetadata = false,
  });

  /// Formats a [DateTime] into local `HH:mm:ss` if today, or `MMM d, HH:mm:ss`
  /// (with year if from a different year) otherwise.
  static String formatDefaultTimestamp(DateTime timestamp, {DateTime? now}) {
    final local = timestamp.toLocal();
    final ref = (now ?? DateTime.now()).toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    final timeStr = '$hh:$mm:$ss';

    final bool isToday = local.year == ref.year &&
        local.month == ref.month &&
        local.day == ref.day;
    if (isToday) {
      return timeStr;
    }

    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String monthStr = months[(local.month - 1).clamp(0, 11)];
    if (local.year != ref.year) {
      return '$monthStr ${local.day}, ${local.year}, $timeStr';
    }
    return '$monthStr ${local.day}, $timeStr';
  }

  /// Opens a full-screen interactive zoomable image dialog.
  static void showFullScreenImage(
    BuildContext context, {
    String? imagePath,
    Uint8List? imageBytes,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        Widget imageWidget;
        if (imageBytes != null && imageBytes.isNotEmpty) {
          imageWidget = Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          );
        } else if (imagePath != null && imagePath.isNotEmpty) {
          imageWidget = Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          );
        } else {
          imageWidget = const SizedBox.shrink();
        }

        return Dialog.fullscreen(
          backgroundColor: Colors.black87,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(child: imageWidget),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  late bool _showMetadata;

  @override
  void initState() {
    super.initState();
    _showMetadata = widget.initiallyExpandedMetadata;
  }

  @override
  void didUpdateWidget(covariant ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpandedMetadata !=
        widget.initiallyExpandedMetadata) {
      _showMetadata = widget.initiallyExpandedMetadata;
    }
  }

  String? get _effectiveImagePath =>
      widget.imagePath ?? widget.message.imagePath;
  Uint8List? get _effectiveImageBytes =>
      widget.imageBytes ?? widget.message.imageBytes;

  bool get _hasRenderableImage {
    final bytes = _effectiveImageBytes;
    if (bytes != null && bytes.isNotEmpty) return true;
    final path = _effectiveImagePath;
    if (path != null && path.isNotEmpty) {
      try {
        return File(path).existsSync();
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  void _toggleMetadata() {
    if (_buildMetadataText().isEmpty) return;
    setState(() {
      _showMetadata = !_showMetadata;
    });
  }

  String _buildMetadataText() {
    final author = widget.message.displayAuthor;
    final ts = widget.message.timestamp;
    final String? formattedTime = ts == null
        ? null
        : (widget.formatTimestamp?.call(ts) ??
            ChatMessageBubble.formatDefaultTimestamp(ts));
    if (author.isNotEmpty &&
        formattedTime != null &&
        formattedTime.isNotEmpty) {
      return '$author  вЂў  $formattedTime';
    }
    if (author.isNotEmpty) return author;
    return formattedTime ?? '';
  }

  static String _extractInitials(String raw, {required String fallback}) {
    final parts =
        raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return fallback;
    if (parts.length == 1) {
      final runes = parts.first.runes.take(2).toList();
      return String.fromCharCodes(runes).toUpperCase();
    }
    final first = String.fromCharCode(parts.first.runes.first);
    final second = String.fromCharCode(parts[1].runes.first);
    return '$first$second'.toUpperCase();
  }

  Widget _buildAvatar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final msg = widget.message;
    final Color bgColor = msg.avatarBackgroundColor ??
        (msg.isUser ? scheme.secondaryContainer : scheme.primaryContainer);
    final Color fgColor =
        msg.isUser ? scheme.onSecondaryContainer : scheme.onPrimaryContainer;

    if (msg.avatarBytes != null && msg.avatarBytes!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: bgColor,
        backgroundImage: MemoryImage(msg.avatarBytes!),
      );
    }
    if (msg.avatarIcon != null) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        child: Icon(msg.avatarIcon, size: 18),
      );
    }

    final rawLabel =
        (msg.avatarText != null && msg.avatarText!.trim().isNotEmpty)
            ? msg.avatarText!.trim()
            : msg.displayAuthor;
    final initials =
        _extractInitials(rawLabel, fallback: msg.isUser ? 'U' : 'AI');

    return CircleAvatar(
      radius: 16,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final bytes = _effectiveImageBytes;
    final path = _effectiveImagePath;
    Widget rawImage;
    if (bytes != null && bytes.isNotEmpty) {
      rawImage = Image.memory(
        bytes,
        fit: BoxFit.cover,
        height: 200,
      );
    } else if (path != null && path.isNotEmpty) {
      rawImage = Image.file(
        File(path),
        fit: BoxFit.cover,
        height: 200,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
          bottom: widget.message.message.isNotEmpty ? 2.0 : 0.0),
      child: GestureDetector(
        onTap: () => ChatMessageBubble.showFullScreenImage(
          context,
          imagePath: path,
          imageBytes: bytes,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: rawImage,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonSlot({
    required bool hasPreviousContent,
  }) {
    final msg = widget.message;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            fixedCrossAxisSizeFactor: 1.0,
            alignment: Alignment.topLeft,
            child: child,
          ),
        ),
        child: msg.isLoading
            ? Padding(
                key: const ValueKey<bool>(true),
                padding: EdgeInsets.only(
                  top: hasPreviousContent ? 8.0 : 0.0,
                ),
                child: ChatAnimatedSkeleton(
                  loadingLabel: msg.loadingLabel,
                  lineCount: msg.message.isEmpty ? 3 : 2,
                  isUser: msg.isUser,
                ),
              )
            : const SizedBox.shrink(key: ValueKey<bool>(false)),
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final String metadataText = _buildMetadataText();
    final bool visible = _showMetadata && metadataText.isNotEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment:
          widget.message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        child: visible
            ? Padding(
                padding: const EdgeInsets.only(
                  top: 2,
                  bottom: 4,
                  left: 6,
                  right: 6,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    metadataText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final msg = widget.message;
    final hasImage = _hasRenderableImage;
    final hasThoughts = msg.hasThoughts;
    final hasMessage = msg.message.isNotEmpty;
    final hasCustom = widget.customContent != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (MediaQuery.maybeSizeOf(context)?.width ?? 400.0);
        final double bubbleAreaWidth = widget.showAvatar
            ? math.max(0.0, availableWidth - 40.0)
            : availableWidth;

        final double userMaxWidth = widget.maxBubbleWidth != null
            ? math.min(widget.maxBubbleWidth!, bubbleAreaWidth)
            : math.min(
                bubbleAreaWidth,
                (bubbleAreaWidth * 0.78).clamp(
                  math.min(160.0, bubbleAreaWidth),
                  560.0,
                ),
              );
        final double aiMaxWidth = widget.maxBubbleWidth != null
            ? math.min(widget.maxBubbleWidth!, bubbleAreaWidth)
            : math.min(
                bubbleAreaWidth,
                (bubbleAreaWidth * 0.85).clamp(
                  math.min(180.0, bubbleAreaWidth),
                  640.0,
                ),
              );

        final double effectiveMaxWidth = msg.isUser ? userMaxWidth : aiMaxWidth;

        final Widget card = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleMetadata,
          child: Card(
            elevation: 0,
            color: msg.isUser
                ? scheme.onSecondaryContainer
                : scheme.surfaceContainerHigh,
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 15,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: effectiveMaxWidth,
                  minWidth: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasThoughts)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              (hasImage || hasMessage || hasCustom) ? 8.0 : 0.0,
                        ),
                        child: ChatThoughtsBlock(
                          thoughts: msg.thoughts!,
                          isStreaming: msg.isThinkingStreaming,
                          hasResponseText: hasMessage,
                          thinkingTitle: widget.thinkingInProgressLabel,
                          thoughtProcessTitle: widget.thoughtProcessLabel,
                          trailing: widget.thoughtsTrailing,
                        ),
                      ),
                    if (hasImage) _buildThumbnail(context),
                    if (hasMessage)
                      msg.isUser
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: 6.0,
                                left: 4.0,
                                right: 4.0,
                                bottom: 2.0,
                              ),
                              child: Text(
                                msg.message,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: scheme.onSecondary,
                                ),
                              ),
                            )
                          : MarkdownBody(
                              data: msg.message,
                              selectable: true,
                              fitContent: true,
                              shrinkWrap: true,
                              styleSheet: widget.markdownStyleSheet,
                              onTapText: _toggleMetadata,
                              onTapLink: (
                                String text,
                                String? href,
                                String title,
                              ) async {
                                if (href != null && href.isNotEmpty) {
                                  final Uri? uri = Uri.tryParse(href);
                                  if (uri != null) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                }
                              },
                            ),
                    if (hasCustom)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (hasThoughts || hasImage || hasMessage)
                              ? 8.0
                              : 0.0,
                        ),
                        child: widget.customContent!,
                      ),
                    _buildSkeletonSlot(
                      hasPreviousContent:
                          hasThoughts || hasImage || hasMessage || hasCustom,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final Widget bubbleWithMetadata = Flexible(
          child: Column(
            crossAxisAlignment:
                msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              card,
              _buildMetadataRow(context),
            ],
          ),
        );

        if (msg.isUser) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bubbleWithMetadata,
              if (widget.showAvatar) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildAvatar(context),
                ),
              ],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showAvatar) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildAvatar(context),
              ),
              const SizedBox(width: 8),
            ],
            bubbleWithMetadata,
          ],
        );
      },
    );
  }
}
