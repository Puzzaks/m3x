import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Telemetry card with a background custom-painted smooth area + stroke
/// sparkline wave, status indicator dot or leading icon, title, primary value,
/// optional circular progress gauge, and optional secondary stat slot.
///
/// Matches PTK's server telemetry aesthetic while accepting an explicit [history]
/// list (`0.0..1.0`) so parent rebuilds never push duplicate sample ticks.
class TelemetrySparklineCard extends StatelessWidget {
  final String title;
  final String valueText;
  final String? labelText;
  final String? secondaryLabelText;
  final String? secondaryValueText;
  final String? subValue;
  final double? progress;
  final List<double> history;
  final int maxHistory;
  final IconData? icon;
  final bool? isOnline;
  final bool showAreaFill;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Color? graphColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const TelemetrySparklineCard({
    super.key,
    required this.title,
    required this.valueText,
    required this.history,
    this.labelText,
    this.secondaryLabelText,
    this.secondaryValueText,
    this.subValue,
    this.progress,
    this.maxHistory = 30,
    this.icon,
    this.isOnline,
    this.showAreaFill = true,
    this.height,
    this.width,
    this.onTap,
    this.graphColor,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Color effectiveColor = graphColor ?? scheme.primary;
    final bool isCompact = height != null && height! < 90;
    final double effectiveHeight = height ?? 136.0;

    final Widget cardBody = Stack(
      children: [
        // Background sparkline wave along bottom edge (PTK Thinkpad.dev Image 5 style)
        Positioned.fill(
          top: isCompact ? 10.0 : 30.0,
          child: IgnorePointer(
            child: CustomPaint(
              painter: SparklinePainter(
                history: history,
                maxHistory: maxHistory,
                color: effectiveColor,
                showAreaFill: showAreaFill,
              ),
            ),
          ),
        ),

        // Foreground content
        if (isCompact)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        valueText,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      backgroundColor: effectiveColor.withValues(alpha: 0.12),
                      color: effectiveColor,
                      strokeCap: StrokeCap.round,
                      strokeWidth: 3.5,
                    ),
                  ),
                ] else if (isOnline != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline! ? effectiveColor : scheme.error,
                    ),
                  ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: muted title + optional online indicator dot
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOnline != null && progress == null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline! ? effectiveColor : scheme.error,
                        ),
                      ),
                  ],
                ),

                // Bottom row: large bold value, subValue, and secondary stat / circular gauge slot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (labelText != null && labelText!.isNotEmpty)
                            Text(
                              labelText!,
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            valueText,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subValue != null && subValue!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subValue!,
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: progress!.clamp(0.0, 1.0),
                          backgroundColor:
                              effectiveColor.withValues(alpha: 0.15),
                          color: effectiveColor,
                          strokeCap: StrokeCap.round,
                          strokeWidth: 3.5,
                        ),
                      ),
                    ] else if (secondaryValueText != null &&
                        secondaryValueText!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (secondaryLabelText != null &&
                                secondaryLabelText!.isNotEmpty)
                              Text(
                                secondaryLabelText!,
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              secondaryValueText!,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
      ],
    );

    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: Card(
        margin: margin,
        color: scheme.surfaceContainer,
        surfaceTintColor: scheme.primary,
        clipBehavior: Clip.hardEdge,
        shape: borderRadius != null
            ? RoundedRectangleBorder(borderRadius: borderRadius!)
            : null,
        child: onTap != null
            ? InkWell(onTap: onTap, child: cardBody)
            : cardBody,
      ),
    );
  }
}

/// Smooth cubic-bezier sparkline wave painter for [TelemetrySparklineCard]
/// matching PTK's minimalist server telemetry aesthetic (Image 5).
class SparklinePainter extends CustomPainter {
  final List<double> history;
  final int maxHistory;
  final Color color;
  final bool showAreaFill;

  SparklinePainter({
    required this.history,
    required this.maxHistory,
    required this.color,
    this.showAreaFill = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty || size.width <= 0 || size.height <= 0) return;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final int effectiveMax = maxHistory > 1 ? maxHistory : 2;
    final double step = size.width / (effectiveMax - 1);
    final double startX = size.width - ((history.length - 1) * step);

    // Keep the sparkline wave in the lower 35% of the card
    final List<Offset> points = List<Offset>.generate(history.length, (i) {
      final double val = history[i].clamp(0.0, 1.0);
      final double x = startX + (i * step);
      final double y = size.height - (val * size.height * 0.35) - 6.0;
      return Offset(x, y);
    });

    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    if (points.length == 1) {
      path.lineTo(size.width, points.first.dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        final Offset p0 = points[i];
        final Offset p1 = points[i + 1];
        final double controlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }
    }

    if (showAreaFill) {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      final Path fillPath = Path();
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);
      if (points.length == 1) {
        fillPath.lineTo(size.width, points.first.dy);
      } else {
        for (int i = 0; i < points.length - 1; i++) {
          final Offset p0 = points[i];
          final Offset p1 = points[i + 1];
          final double controlX = (p0.dx + p1.dx) / 2;
          fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        }
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.maxHistory != maxHistory ||
        oldDelegate.color != color ||
        oldDelegate.showAreaFill != showAreaFill;
  }
}

/// Compact telemetry card overlaying a rounded [CircularProgressIndicator]
/// ring around a centered [Icon], paired with bold [title] and [valueText].
///
/// Extracted from `Website`'s `TelemetryCard`.
class CircularGaugeCard extends StatelessWidget {
  final String title;
  final String valueText;
  final double progressValue;
  final IconData icon;
  final double? width;
  final VoidCallback? onTap;

  const CircularGaugeCard({
    super.key,
    required this.title,
    required this.valueText,
    required this.progressValue,
    required this.icon,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget content = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: progressValue.clamp(0.0, 1.0),
                  backgroundColor: scheme.surfaceContainerHighest,
                  strokeCap: StrokeCap.round,
                  strokeWidth: 3.5,
                  color: scheme.primary,
                ),
              ),
              Icon(icon, size: 20),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  valueText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      width: width,
      child: Card(
        color: scheme.surfaceContainer,
        surfaceTintColor: scheme.primary,
        clipBehavior: Clip.hardEdge,
        child: onTap != null ? InkWell(onTap: onTap, child: content) : content,
      ),
    );
  }
}

/// Synchronization / background task status card that cross-fades between an
/// interactive refresh row and a live [LinearProgressIndicator] view.
///
/// Extracted from `binotool/lib/main.dart`.
class SyncStatusCard extends StatelessWidget {
  final String title;
  final String statusText;
  final bool isSyncing;
  final double? progress;
  final VoidCallback onSyncTap;

  const SyncStatusCard({
    super.key,
    required this.title,
    required this.statusText,
    required this.isSyncing,
    this.progress,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainer,
      surfaceTintColor: scheme.primary,
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: AnimatedCrossFade(
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 400),
        firstChild: InkWell(
          onTap: onSyncTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.refresh_rounded, size: 28),
              ],
            ),
          ),
        ),
        secondChild: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (progress == null || progress! < 0)
                    ? null
                    : progress!.clamp(0.0, 1.0),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            ],
          ),
        ),
        crossFadeState: isSyncing
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
      ),
    );
  }
}

/// 3-way Material 3 [ThemeMode] selector card (`Light`, `System`, `Dark`) using
/// a compact [SegmentedButton].
///
/// Extracted from `Website`'s `ThemeSwitchCard`.
class ThemeModeSwitchCard extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  final String title;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const ThemeModeSwitchCard({
    super.key,
    required this.mode,
    required this.onChanged,
    this.title = 'Theme',
    this.borderRadius,
    this.margin,
  });

  String _subtitleForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Adaptive (System)';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showLabels = constraints.maxWidth > 520;
        return Card(
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          elevation: 3,
          color: scheme.surfaceContainer,
          surfaceTintColor: scheme.primary,
          clipBehavior: Clip.hardEdge,
          shape: borderRadius != null
              ? RoundedRectangleBorder(borderRadius: borderRadius!)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.contrast_rounded),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _subtitleForMode(mode),
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_rounded),
                      label: showLabels
                          ? const Text('Light', style: TextStyle(fontSize: 12))
                          : null,
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_rounded),
                      label: showLabels
                          ? const Text('System', style: TextStyle(fontSize: 12))
                          : null,
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_rounded),
                      label: showLabels
                          ? const Text('Dark', style: TextStyle(fontSize: 12))
                          : null,
                    ),
                  ],
                  selected: <ThemeMode>{mode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      onChanged(selection.first);
                    }
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Reusable color-coded event and telemetry log viewer with severity filter
/// chips and tap-to-copy support.
///
/// Extracted and upgraded from `geminilocal/lib/pages/settings/logs.dart` and
/// `ggscanus/lib/main.dart`.
class LogViewerList extends StatefulWidget {
  /// List of log entries, where each map contains:
  /// - `time`: epoch milliseconds (`int`) or formatted string (`String`)
  /// - `thread`: subsystem or thread name (`String`)
  /// - `type`: `'info'`, `'warning'`, or `'error'` (`String`)
  /// - `message`: log message (`String`)
  final List<Map<String, dynamic>> logs;
  final bool showFilterChips;
  final bool reverse;

  const LogViewerList({
    super.key,
    required this.logs,
    this.showFilterChips = true,
    this.reverse = true,
  });

  @override
  State<LogViewerList> createState() => _LogViewerListState();
}

class _LogViewerListState extends State<LogViewerList> {
  String _selectedType = 'all';

  String _formatTimestamp(dynamic timeValue) {
    if (timeValue is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(timeValue);
      return dt.toIso8601String().replaceAll('T', ' ').split('.')[0];
    }
    return timeValue?.toString() ?? '';
  }

  Color _badgeColor(String type, ColorScheme scheme) {
    switch (type.toLowerCase()) {
      case 'error':
        return scheme.error;
      case 'warning':
        return Colors.amber.shade700;
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Iterable<Map<String, dynamic>> ordered =
        widget.reverse ? widget.logs.reversed : widget.logs;
    final List<Map<String, dynamic>> filtered = ordered.where((entry) {
      if (_selectedType == 'all') return true;
      return (entry['type']?.toString().toLowerCase() ?? 'info') ==
          _selectedType;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showFilterChips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final filter in const ['all', 'info', 'warning', 'error'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _selectedType == filter,
                      label: Text(
                        filter.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onSelected: (_) => setState(() => _selectedType = filter),
                    ),
                  ),
              ],
            ),
          ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No matching log entries.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...filtered.map((entry) {
            final String type =
                (entry['type']?.toString() ?? 'info').toLowerCase();
            final String thread = entry['thread']?.toString() ?? 'app';
            final String message = entry['message']?.toString() ?? '';
            final int count = (entry['count'] is int) ? entry['count'] as int : 1;
            final String timeStr = _formatTimestamp(entry['time']);
            final Color color = _badgeColor(type, scheme);
            final String fullLine = '$timeStr - [$thread] $type: $message${count > 1 ? ' (x$count)' : ''}';

            return InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: fullLine));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Log entry copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                thread,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (count > 1) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '×$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              color: type == 'error'
                                  ? scheme.error
                                  : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
