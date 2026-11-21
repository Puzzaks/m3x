// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'elements.dart';

/// A segmented 3-card Material 3 Expressive bento header used for application
/// Settings dashboards.
///
/// Extracted from MCPlayer and PAIOS (geminilocal) patterns, rendering:
/// 1. A top wide header card displaying the app [icon], [appName], and [subtitle].
/// 2. A bottom-left card showing the application version in the header title (e.g. `Version 1.2.10`)
///    and formatted build/release date as the primary text (tapping triggers [onVersionTap]).
/// 3. A bottom-right card displaying package count in the header title (e.g. `6 Packages`)
///    and an action hint like `Tap to view` as primary text (tapping triggers [onModulesTap]).
class SettingsBentoHeader extends StatelessWidget {
  /// Optional global fallback icon bytes used when neither [iconBytes], [iconAsset],
  /// nor [iconWidget] are specified. Automatically populated by `M3x.init()` if available.
  static Uint8List? defaultIconBytes;

  /// Global fallback package dependencies map (`name -> version/path spec`)
  /// automatically populated by `M3x.parsePubspec()` / `M3x.init()`.
  static Map<String, String> defaultDependencies = const <String, String>{};

  /// Global fallback Markdown changelog text displayed when
  /// [showChangelogDialog] is called without explicit [changelogContent], or
  /// when the Version bento card is tapped without a custom [onVersionTap].
  static String defaultChangelogContent = '';

  /// Global fallback version/build display string used as the default subtitle
  /// for [showChangelogDialog].
  static String defaultVersionDisplay = '';

  /// Displays a standardized Material 3 modal bottom sheet rendering Markdown
  /// release notes using pure Flutter widgets (zero third-party dependencies).
  ///
  /// Uses [changelogContent] when provided, falling back to
  /// [defaultChangelogContent], and uses [subtitle] falling back to
  /// [defaultVersionDisplay].
  static Future<void> showChangelogDialog(
    BuildContext context, {
    String? title,
    String? subtitle,
    String? changelogContent,
    String? emptyMessage,
    IconData icon = Icons.change_circle_outlined,
  }) {
    final String effectiveTitle =
        (title != null && title.trim().isNotEmpty) ? title.trim() : 'Changelog';
    final String effectiveSubtitle = (subtitle ?? defaultVersionDisplay).trim();
    final String effectiveContent =
        (changelogContent ?? defaultChangelogContent).trim();
    final String effectiveEmpty = emptyMessage ?? 'No changelog available.';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        final scheme = Theme.of(sheetCtx).colorScheme;
        final textTheme = Theme.of(sheetCtx).textTheme;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Icon(icon, color: scheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            effectiveTitle,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (effectiveSubtitle.isNotEmpty)
                            Text(
                              effectiveSubtitle,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              Expanded(
                child: SelectionArea(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: effectiveContent.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                effectiveEmpty,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ]
                        : _buildMarkdownWidgets(
                            effectiveContent,
                            textTheme,
                            scheme,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Displays a Material 3 modal bottom sheet listing all installed packages
  /// parsed from `pubspec.yaml` (using [dependencies] or [defaultDependencies]).
  static void showDependenciesDialog(
    BuildContext context, {
    String? title,
    String? subtitle,
    String? workspaceBadge,
    String? pubBadge,
    Map<String, String>? dependencies,
    void Function(String name, String spec, bool isWorkspace)? onPackageTap,
  }) {
    final Map<String, String> effectiveDeps =
        dependencies ?? defaultDependencies;
    final entries = effectiveDeps.entries.toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (sheetCtx, scrollCtrl) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.extension_rounded,
                        size: 24, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title ?? 'Installed Packages (${entries.length})',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
                const Divider(height: 20),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (itemCtx, index) {
                      final entry = entries[index];
                      final name = entry.key;
                      final spec = entry.value;
                      final isWorkspace = name.startsWith('m3x') ||
                          name.startsWith('puzzak_') ||
                          spec.startsWith('path:');
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: isWorkspace
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          child: Icon(
                            isWorkspace
                                ? Icons.widgets_rounded
                                : Icons.inventory_2_outlined,
                            size: 20,
                            color: isWorkspace
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isWorkspace
                                      ? scheme.secondaryContainer
                                      : scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  spec,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isWorkspace
                                        ? scheme.onSecondaryContainer
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          isWorkspace
                              ? (workspaceBadge ?? 'Local Workspace Package')
                              : (pubBadge ?? 'pub.dev Dependency'),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Icon(
                          isWorkspace
                              ? Icons.verified_rounded
                              : (onPackageTap != null
                                  ? Icons.open_in_new_rounded
                                  : Icons.check_circle_outline_rounded),
                          size: 18,
                          color: isWorkspace
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        onTap: onPackageTap != null
                            ? () => onPackageTap(name, spec, isWorkspace)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The title of the application or module shown in the top header card.
  final String appName;

  /// Explanatory subtitle or description shown below [appName].
  final String subtitle;

  /// Leading icon displayed inside a styled container on the top card.
  final IconData icon;

  /// Custom widget replacing the top card icon container contents.
  final Widget? iconWidget;

  /// Raw byte buffer for the top card launcher icon (e.g. native app icon extracted via M3x).
  final Uint8List? iconBytes;

  /// Asset path for an image displayed in place of the top card icon.
  final String? iconAsset;

  /// Formatted version string (e.g. `1.2.10 (Nov 7, 2026 (rev 01))`).
  ///
  /// When parenthesized build/date info is present, the version number is
  /// automatically parsed into the upper card title (e.g. "Version 1.2.10")
  /// and the inner build/date info becomes the primary card content.
  final String versionDisplay;

  /// Optional custom title for the Version card. Overrides the auto-parsed "Version $version".
  final String? versionTitle;

  /// Optional custom main text for the Version card. Overrides the auto-parsed date/revision string.
  final String? versionSubtitle;

  /// Total count of connected packages or modules.
  /// When omitted, automatically defaults to [defaultDependencies.length].
  final int? connectedModulesCount;

  /// Optional custom title for the Modules card. Overrides "$connectedModulesCount Packages".
  final String? modulesTitle;

  /// Optional custom main text for the Modules card. Overrides "Tap to view".
  final String? modulesSubtitle;

  /// Optional callback invoked when the Version card is tapped.
  final VoidCallback? onVersionTap;

  /// Optional callback invoked when the Modules card is tapped.
  final VoidCallback? onModulesTap;

  const SettingsBentoHeader({
    super.key,
    required this.appName,
    required this.subtitle,
    this.icon = Icons.auto_awesome_mosaic_rounded,
    this.iconWidget,
    this.iconBytes,
    this.iconAsset,
    required this.versionDisplay,
    this.versionTitle,
    this.versionSubtitle,
    this.connectedModulesCount,
    this.modulesTitle,
    this.modulesSubtitle,
    this.onVersionTap,
    this.onModulesTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Widget effectiveIcon;
    final Uint8List? effectiveBytes = iconBytes ?? defaultIconBytes;
    if (iconWidget != null) {
      effectiveIcon = iconWidget!;
    } else if (effectiveBytes != null) {
      effectiveIcon = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          effectiveBytes,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      );
    } else if (iconAsset != null) {
      effectiveIcon = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          iconAsset!,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      );
    } else {
      effectiveIcon = Icon(
        icon,
        size: 30,
        color: scheme.onPrimaryContainer,
      );
    }

    final String effectiveVersionTitle;
    final String effectiveVersionMain;

    if (versionTitle != null) {
      effectiveVersionTitle = versionTitle!;
      effectiveVersionMain = versionSubtitle ?? versionDisplay;
    } else {
      final openParen = versionDisplay.indexOf(' (');
      if (openParen != -1 && versionDisplay.endsWith(')')) {
        final ver = versionDisplay.substring(0, openParen).trim();
        final date = versionDisplay
            .substring(openParen + 2, versionDisplay.length - 1)
            .trim();
        effectiveVersionTitle = 'Version $ver';
        effectiveVersionMain = versionSubtitle ?? date;
      } else {
        effectiveVersionTitle = 'Version';
        effectiveVersionMain = versionSubtitle ?? versionDisplay;
      }
    }

    final int effectiveModulesCount =
        connectedModulesCount ?? defaultDependencies.length;
    final String effectiveModulesTitle =
        modulesTitle ?? '$effectiveModulesCount Packages';
    final String effectiveModulesMain = modulesSubtitle ?? 'Tap to view';
    final String? resolvedDefaultSubtitle =
        defaultVersionDisplay.trim().isNotEmpty
            ? defaultVersionDisplay.trim()
            : (versionDisplay.trim().isNotEmpty ? versionDisplay.trim() : null);
    final VoidCallback? effectiveOnVersionTap = onVersionTap ??
        (defaultChangelogContent.trim().isNotEmpty
            ? () => showChangelogDialog(
                  context,
                  subtitle: resolvedDefaultSubtitle,
                )
            : null);
    final VoidCallback? effectiveOnModulesTap = onModulesTap ??
        (defaultDependencies.isNotEmpty
            ? () => showDependenciesDialog(context)
            : null);

    return CardGroup(
      columns: 2,
      leadingCardWide: true,
      children: [
        // 1. Top Wide Header Card
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: effectiveIcon,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // 2. Bottom-Left Card: Version & Build
        InkWell(
          onTap: effectiveOnVersionTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  effectiveOnVersionTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effectiveVersionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    effectiveVersionMain,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 3. Bottom-Right Card: Connected Modules
        InkWell(
          onTap: effectiveOnModulesTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  effectiveOnModulesTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effectiveModulesTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    effectiveModulesMain,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static final RegExp _headingRegex = RegExp(r'^(#{1,4})\s+(.*)$');
  static final RegExp _bulletRegex = RegExp(r'^(\s*)[-*]\s+(.*)$');
  static final RegExp _numberedRegex = RegExp(r'^(\s*)(\d+)\.\s+(.*)$');
  static final RegExp _hrRegex = RegExp(r'^([-*_])\1{2,}$');
  static final RegExp _inlineRegex = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`');

  /// Renders Markdown text into Material 3 widgets without external packages.
  static List<Widget> _buildMarkdownWidgets(
    String markdown,
    TextTheme textTheme,
    ColorScheme scheme,
  ) {
    final List<Widget> widgets = <Widget>[];
    final List<String> paragraphLines = <String>[];
    final TextStyle baseBodyStyle = textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          height: 1.45,
        ) ??
        TextStyle(fontSize: 14, color: scheme.onSurface, height: 1.45);

    void flushParagraph() {
      if (paragraphLines.isEmpty) return;
      final String joined = paragraphLines.join(' ').trim();
      paragraphLines.clear();
      if (joined.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(
            TextSpan(
              style: baseBodyStyle,
              children: _parseInlineSpans(joined, baseBodyStyle, scheme),
            ),
          ),
        ),
      );
    }

    for (final rawLine in markdown.replaceAll('\r\n', '\n').split('\n')) {
      final String trimmed = rawLine.trim();
      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }

      if (_hrRegex.hasMatch(trimmed)) {
        flushParagraph();
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
        );
        continue;
      }

      final RegExpMatch? headingMatch = _headingRegex.firstMatch(trimmed);
      if (headingMatch != null) {
        flushParagraph();
        final int level = headingMatch.group(1)!.length;
        final String headingText = headingMatch.group(2)!.trim();
        final bool hasPreceding = widgets.isNotEmpty;
        final TextStyle headingStyle = switch (level) {
          1 => (textTheme.titleLarge ?? const TextStyle(fontSize: 22)).copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          2 =>
            (textTheme.titleMedium ?? const TextStyle(fontSize: 16)).copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          _ => (textTheme.titleSmall ?? const TextStyle(fontSize: 14)).copyWith(
              fontWeight: FontWeight.w700,
              color: level == 3 ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
        };
        final double topPad =
            !hasPreceding ? 2 : (level == 2 ? 16 : (level == 1 ? 14 : 10));
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: topPad, bottom: level <= 2 ? 6 : 4),
            child: Text.rich(
              TextSpan(
                style: headingStyle,
                children: _parseInlineSpans(headingText, headingStyle, scheme),
              ),
            ),
          ),
        );
        continue;
      }

      final RegExpMatch? bulletMatch = _bulletRegex.firstMatch(rawLine);
      if (bulletMatch != null) {
        flushParagraph();
        final int indent = (bulletMatch.group(1)!.length ~/ 2).clamp(0, 4);
        final String itemText = bulletMatch.group(2)!.trim();
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: indent * 16.0, bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    indent == 0 ? 'вЂў' : 'в—¦',
                    style: baseBodyStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: baseBodyStyle,
                      children:
                          _parseInlineSpans(itemText, baseBodyStyle, scheme),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      final RegExpMatch? numberedMatch = _numberedRegex.firstMatch(rawLine);
      if (numberedMatch != null) {
        flushParagraph();
        final int indent = (numberedMatch.group(1)!.length ~/ 2).clamp(0, 4);
        final String number = numberedMatch.group(2)!;
        final String itemText = numberedMatch.group(3)!.trim();
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: indent * 16.0, bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 22),
                  child: Text(
                    '$number. ',
                    style: baseBodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: baseBodyStyle,
                      children:
                          _parseInlineSpans(itemText, baseBodyStyle, scheme),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      paragraphLines.add(trimmed);
    }

    flushParagraph();
    return widgets;
  }

  /// Parses `**bold**` and `` `inline code` `` spans into styled [TextSpan]s.
  static List<InlineSpan> _parseInlineSpans(
    String text,
    TextStyle baseStyle,
    ColorScheme scheme,
  ) {
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;

    for (final RegExpMatch match in _inlineRegex.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final String? boldText = match.group(1);
      final String? codeText = match.group(2);
      if (boldText != null) {
        spans.add(
          TextSpan(
            text: boldText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (codeText != null) {
        spans.add(
          TextSpan(
            text: ' $codeText ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: (baseStyle.fontSize ?? 14) * 0.88,
              fontWeight: FontWeight.w600,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.onSurface,
            ),
          ),
        );
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }
}
