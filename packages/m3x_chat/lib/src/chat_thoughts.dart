import 'package:flutter/material.dart';
import 'package:m3x_ui/motion_blur.dart';

/// Collapsible Material 3 sub-card displaying model reasoning / thoughts inside
/// a [ChatMessageBubble].
///
/// Automatically expands while [isStreaming] is `true` and [hasResponseText] is
/// `false`, pulses its leading icon while streaming, and smoothly collapses when
/// response text starts unless the user manually toggled it.
class ChatThoughtsBlock extends StatefulWidget {
  final String thoughts;
  final bool isStreaming;
  final bool hasResponseText;
  final String? thinkingTitle;
  final String? thoughtProcessTitle;
  final Widget? trailing;
  final double maxContentHeight;

  const ChatThoughtsBlock({
    super.key,
    required this.thoughts,
    this.isStreaming = false,
    this.hasResponseText = false,
    this.thinkingTitle,
    this.thoughtProcessTitle,
    this.trailing,
    this.maxContentHeight = 220.0,
  });

  @override
  State<ChatThoughtsBlock> createState() => _ChatThoughtsBlockState();
}

class _ChatThoughtsBlockState extends State<ChatThoughtsBlock>
    with SingleTickerProviderStateMixin {
  static const double _autoFollowThreshold = 24.0;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseOpacity;
  final ScrollController _scrollController = ScrollController();
  bool _expanded = false;
  bool _userToggled = false;
  bool _autoFollowBottom = true;
  bool _scrollScheduled = false;
  bool _isProgrammaticScroll = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isStreaming && !widget.hasResponseText;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isStreaming) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }
    if (_expanded && widget.isStreaming && widget.thoughts.isNotEmpty) {
      _scheduleScrollToBottom();
    }
  }

  @override
  void didUpdateWidget(covariant ChatThoughtsBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isStreaming && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }

    final bool wasExpanded = _expanded;
    if (!_userToggled) {
      if (!oldWidget.isStreaming &&
          widget.isStreaming &&
          !widget.hasResponseText) {
        _expanded = true;
      } else if (!oldWidget.hasResponseText && widget.hasResponseText) {
        _expanded = false;
      } else if (oldWidget.isStreaming &&
          !widget.isStreaming &&
          widget.hasResponseText) {
        _expanded = false;
      }
    }

    if (_expanded != wasExpanded) {
      _autoFollowBottom = true;
    }

    final bool thoughtsChanged = widget.thoughts != oldWidget.thoughts;
    final bool startedStreaming = !oldWidget.isStreaming && widget.isStreaming;
    final bool justExpandedWhileStreaming =
        !wasExpanded && _expanded && widget.isStreaming;

    if (_expanded &&
        _autoFollowBottom &&
        (thoughtsChanged || startedStreaming || justExpandedWhileStreaming)) {
      _scheduleScrollToBottom();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _userToggled = true;
      _expanded = !_expanded;
      _autoFollowBottom = true;
    });
    if (_expanded && widget.isStreaming) {
      _scheduleScrollToBottom();
    }
  }

  void _scheduleScrollToBottom() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_expanded || !_autoFollowBottom) return;
      if (!_scrollController.hasClients) return;
      final ScrollPosition position = _scrollController.position;
      if (!position.hasContentDimensions) return;
      final double target = position.maxScrollExtent;
      if ((target - position.pixels).abs() <= 0.5) return;
      _isProgrammaticScroll = true;
      try {
        _scrollController.jumpTo(target);
      } finally {
        _isProgrammaticScroll = false;
      }
    });
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (_isProgrammaticScroll) return;
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return;
    }

    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification ||
        notification is OverscrollNotification) {
      final double distanceFromBottom =
          notification.metrics.maxScrollExtent - notification.metrics.pixels;
      _autoFollowBottom = distanceFromBottom <= _autoFollowThreshold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final String title = widget.isStreaming
        ? ((widget.thinkingTitle != null &&
                widget.thinkingTitle!.trim().isNotEmpty)
            ? widget.thinkingTitle!.trim()
            : 'Thinking…')
        : ((widget.thoughtProcessTitle != null &&
                widget.thoughtProcessTitle!.trim().isNotEmpty)
            ? widget.thoughtProcessTitle!.trim()
            : 'Thought Process');

    final Widget headerIcon = Icon(
      Icons.psychology_alt_rounded,
      size: 16,
      color: widget.isStreaming ? scheme.primary : scheme.onSurfaceVariant,
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: _expanded
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: _expanded ? MainAxisSize.max : MainAxisSize.min,
                  children: <Widget>[
                    widget.isStreaming
                        ? FadeTransition(
                            opacity: _pulseOpacity,
                            child: headerIcon,
                          )
                        : headerIcon,
                    const SizedBox(width: 6),
                    Flexible(
                      fit: _expanded ? FlexFit.tight : FlexFit.loose,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: widget.isStreaming
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 6),
                      widget.trailing!,
                    ],
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: _expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: widget.maxContentHeight,
                          ),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              _handleScrollNotification(notification);
                              return true;
                            },
                            child: MotionBlurContainer(
                              listenToAncestor: false,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                child: SelectableText(
                                  widget.thoughts,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
