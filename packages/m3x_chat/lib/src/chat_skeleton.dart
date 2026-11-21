import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure-Flutter animated Material 3 skeleton shimmer block for loading or
/// continuing chat responses inside [ChatMessageBubble].
class ChatAnimatedSkeleton extends StatefulWidget {
  final String? loadingLabel;
  final int lineCount;
  final bool isUser;
  final double barHeight;
  final double barSpacing;

  const ChatAnimatedSkeleton({
    super.key,
    this.loadingLabel,
    this.lineCount = 3,
    this.isUser = false,
    this.barHeight = 10.0,
    this.barSpacing = 7.0,
  });

  @override
  State<ChatAnimatedSkeleton> createState() => _ChatAnimatedSkeletonState();
}

class _ChatAnimatedSkeletonState extends State<ChatAnimatedSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<double> _widthRatios = <double>[
    0.92,
    0.76,
    0.54,
    0.84,
    0.62,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final int count = widget.lineCount.clamp(1, 5);

    final Color baseColor = widget.isUser
        ? scheme.onSecondary.withValues(alpha: 0.16)
        : scheme.surfaceContainerHighest;
    final Color highlightColor = widget.isUser
        ? scheme.onSecondary.withValues(alpha: 0.34)
        : Color.alphaBlend(
            scheme.onSurfaceVariant.withValues(alpha: 0.12),
            scheme.surface,
          );
    final Color labelColor = widget.isUser
        ? scheme.onSecondary.withValues(alpha: 0.78)
        : scheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 220.0;
        if (availableWidth <= 0) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double slide = -1.5 + 3.0 * _controller.value;
            final gradient = LinearGradient(
              begin: Alignment(slide, -0.2),
              end: Alignment(slide + 1.0, 0.2),
              colors: <Color>[baseColor, highlightColor, baseColor],
              stops: const <double>[0.0, 0.5, 1.0],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < count; i++) ...[
                  if (i > 0) SizedBox(height: widget.barSpacing),
                  Container(
                    width: math.max(
                      0.0,
                      availableWidth * _widthRatios[i % _widthRatios.length],
                    ),
                    height: widget.barHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: gradient,
                    ),
                  ),
                ],
                if (widget.loadingLabel != null &&
                    widget.loadingLabel!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          widget.loadingLabel!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: labelColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
