// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'bento.dart';

/// Core grouped card builder for Puzzak's Material 3 Expressive UI.
///
/// Groups a list of widgets into segmented Material 3 [Card] containers where
/// outer corners use [cardROuter] (20px default) and adjacent inner edges use
/// [cardRInner] (5px default).
class Cards {
  double cardMarginV = 2;
  double cardMarginH = 15;
  Radius cardROuter = const Radius.circular(20);
  Radius cardRInner = const Radius.circular(5);
  Map<String, double> cardMargins = {"h": 15, "v": 2};
  late BuildContext context;

  double cardElevation = 3;

  Cards._internal(this.context);

  factory Cards({required BuildContext context}) => Cards._internal(context);

  Color tintColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color cardColor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainer;
  }

  /// Calculates the segmented [BorderRadius] for a card at [index] in a grid
  /// of [totalCount] items with [columns] columns.
  BorderRadius borderRadiusForIndex(int index, int totalCount,
      {int columns = 1}) {
    if (totalCount <= 1) {
      return BorderRadius.all(cardROuter);
    }

    final int cols = columns <= 1 ? 1 : columns;
    if (cols == 1) {
      if (index == 0) {
        return BorderRadius.only(
          topLeft: cardROuter,
          topRight: cardROuter,
          bottomLeft: cardRInner,
          bottomRight: cardRInner,
        );
      } else if (index == totalCount - 1) {
        return BorderRadius.only(
          topLeft: cardRInner,
          topRight: cardRInner,
          bottomLeft: cardROuter,
          bottomRight: cardROuter,
        );
      } else {
        return BorderRadius.all(cardRInner);
      }
    }

    final int totalRows = (totalCount + cols - 1) ~/ cols;
    final int row = index ~/ cols;
    final int col = index % cols;
    final int itemsInFirstRow = totalCount < cols ? totalCount : cols;
    final int itemsInLastRow = totalCount - (totalRows - 1) * cols;
    final int lastColInFirstRow = itemsInFirstRow - 1;
    final int lastColInLastRow = itemsInLastRow - 1;
    final int lastRow = totalRows - 1;

    return BorderRadius.only(
      topLeft: (row == 0 && col == 0) ? cardROuter : cardRInner,
      topRight:
          (row == 0 && col == lastColInFirstRow) ? cardROuter : cardRInner,
      bottomLeft: (row == lastRow && col == 0) ? cardROuter : cardRInner,
      bottomRight:
          (row == lastRow && col == lastColInLastRow) ? cardROuter : cardRInner,
    );
  }

  /// Renders [cards] inside segmented Material 3 [Card] containers.
  ///
  /// When [columns] <= 1, renders a single-column vertical stack.
  /// When [columns] > 1, renders a multi-column segmented grid where outer
  /// corners of the grid use [cardROuter] and inner edges use [cardRInner].
  ///
  /// When [leadingCardWide] is `true` (e.g. 3 cards in 2 columns), the first card
  /// spans the entire width across all columns while remaining cards fill the rows
  /// below, forming a unified segmented bento card group.
  Widget cardGroup(
    List<Widget> cards, {
    int columns = 1,
    bool leadingCardWide = false,
    double? maxWidth,
  }) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color surfaceColor = cardColor(context);
    final Color surfaceTint = tintColor(context);

    // Leading-card-wide bento layout (e.g. 3 cards in 2 columns)
    if (leadingCardWide && columns >= 2 && cards.length >= 2) {
      final BorderRadius topRadius = BorderRadius.only(
        topLeft: cardROuter,
        topRight: cardROuter,
        bottomLeft: cardRInner,
        bottomRight: cardRInner,
      );
      final Widget topCardWidget = Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: topRadius),
        surfaceTintColor: surfaceTint,
        color: surfaceColor,
        elevation: cardElevation,
        margin: EdgeInsets.symmetric(
          horizontal: cardMarginH,
          vertical: cardMarginV,
        ),
        child: SizedBox(
          width: double.infinity,
          child: cards.first,
        ),
      );

      final List<Widget> remainingCards = cards.sublist(1);
      final int cols = columns.clamp(1, remainingCards.length);
      final int totalRows = (remainingCards.length + cols - 1) ~/ cols;

      final List<Widget> bentoRows = [topCardWidget];

      for (int r = 0; r < totalRows; r++) {
        final int startIdx = r * cols;
        final int endIdx = (startIdx + cols) > remainingCards.length
            ? remainingCards.length
            : (startIdx + cols);
        final int itemsInRow = endIdx - startIdx;
        final bool isLastRow = (r == totalRows - 1);

        final List<Widget> rowChildren = [];
        for (int c = 0; c < itemsInRow; c++) {
          final int cardIdx = startIdx + c;
          final bool isFirstCol = (c == 0);
          final bool isLastCol = (c == itemsInRow - 1);

          final BorderRadius radius = BorderRadius.only(
            topLeft: cardRInner,
            topRight: cardRInner,
            bottomLeft: (isLastRow && isFirstCol) ? cardROuter : cardRInner,
            bottomRight: (isLastRow && isLastCol) ? cardROuter : cardRInner,
          );

          final EdgeInsets margin = EdgeInsets.only(
            left: isFirstCol ? cardMarginH : cardMarginV,
            right: isLastCol ? cardMarginH : cardMarginV,
            top: cardMarginV,
            bottom: cardMarginV,
          );

          rowChildren.add(
            Expanded(
              child: Card(
                clipBehavior: Clip.hardEdge,
                shape: RoundedRectangleBorder(borderRadius: radius),
                surfaceTintColor: surfaceTint,
                color: surfaceColor,
                elevation: cardElevation,
                margin: margin,
                child: remainingCards[cardIdx],
              ),
            ),
          );
        }

        bentoRows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        );
      }

      final Widget content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: bentoRows,
      );

      if (maxWidth != null) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        );
      }
      return content;
    }

    if (columns <= 1) {
      final List<Widget> children = List<Widget>.generate(cards.length, (i) {
        final BorderRadius radius = borderRadiusForIndex(
          i,
          cards.length,
          columns: 1,
        );
        return Card(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(borderRadius: radius),
          surfaceTintColor: surfaceTint,
          color: surfaceColor,
          elevation: cardElevation,
          margin: EdgeInsets.symmetric(
            horizontal: cardMarginH,
            vertical: cardMarginV,
          ),
          child: SizedBox(
            width: double.infinity,
            child: cards[i],
          ),
        );
      });

      final Widget column = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );

      if (maxWidth != null) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: column,
        );
      }
      return column;
    }

    // Multi-column segmented grid
    return LayoutBuilder(
      builder: (context, constraints) {
        final double effectiveMaxWidth = maxWidth ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 720.0);
        final int cols = columns.clamp(1, cards.length);
        final int totalRows = (cards.length + cols - 1) ~/ cols;
        const double multiColMarginH = 2.0;

        final List<Widget> rows = [];
        for (int r = 0; r < totalRows; r++) {
          final int startIdx = r * cols;
          final int endIdx = (startIdx + cols) > cards.length
              ? cards.length
              : (startIdx + cols);
          final int itemsInRow = endIdx - startIdx;

          final List<Widget> rowChildren = [];
          for (int c = 0; c < itemsInRow; c++) {
            final int index = startIdx + c;
            final BorderRadius radius = borderRadiusForIndex(
              index,
              cards.length,
              columns: cols,
            );
            rowChildren.add(
              Expanded(
                child: Card(
                  clipBehavior: Clip.hardEdge,
                  shape: RoundedRectangleBorder(borderRadius: radius),
                  surfaceTintColor: surfaceTint,
                  color: surfaceColor,
                  elevation: cardElevation,
                  margin: EdgeInsets.symmetric(
                    horizontal: multiColMarginH,
                    vertical: cardMarginV,
                  ),
                  child: cards[index],
                ),
              ),
            );
          }

          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal:
                    (cardMarginH - multiColMarginH).clamp(0.0, double.infinity),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Convenience wrapper for `Website` two-column card groups.
  ///
  /// When [columns] is `true`, [width] represents the per-column width (so the
  /// 2-column grid has `maxWidth: width * 2`). When `false`, renders a 1-column
  /// group constrained to [width].
  Widget cardGroupColumns(bool columns, double width, List<Widget> cards) {
    return cardGroup(
      cards,
      columns: columns ? 2 : 1,
      maxWidth: columns ? width * 2 : width,
    );
  }
}

/// Extension on [BuildContext] providing ergonomic access to [Cards].
extension PuzzakCardsContext on BuildContext {
  Cards get cards => Cards(context: this);
}

/// Declarative widget equivalent of [Cards.cardGroup].
class CardGroup extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final bool leadingCardWide;
  final double? maxWidth;
  final double marginH;
  final double marginV;
  final Radius outerRadius;
  final Radius innerRadius;
  final double elevation;

  const CardGroup({
    super.key,
    required this.children,
    this.columns = 1,
    this.leadingCardWide = false,
    this.maxWidth,
    this.marginH = 15,
    this.marginV = 2,
    this.outerRadius = const Radius.circular(20),
    this.innerRadius = const Radius.circular(5),
    this.elevation = 3,
  });

  @override
  Widget build(BuildContext context) {
    final cardsHelper = Cards(context: context)
      ..cardMarginH = marginH
      ..cardMarginV = marginV
      ..cardMargins = {"h": marginH, "v": marginV}
      ..cardROuter = outerRadius
      ..cardRInner = innerRadius
      ..cardElevation = elevation;

    return cardsHelper.cardGroup(
      children,
      columns: columns,
      leadingCardWide: leadingCardWide,
      maxWidth: maxWidth,
    );
  }
}

/// A segmented Material 3 reorderable card list with dynamic outer/inner border
/// radii and a built-in [ReorderableDragStartListener] at each item's index.
///
/// Extracted from `PTK`'s server and status page managers, fixing the hardcoded
/// `index: 0` drag listener bug.
class ReorderableCardGroup extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Key Function(int index)? keyBuilder;
  final ReorderCallback onReorder;
  final double marginH;
  final double marginV;
  final Radius outerRadius;
  final Radius innerRadius;
  final double elevation;
  final bool showDragHandle;

  const ReorderableCardGroup({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.keyBuilder,
    this.marginH = 15,
    this.marginV = 2,
    this.outerRadius = const Radius.circular(20),
    this.innerRadius = const Radius.circular(5),
    this.elevation = 3,
    this.showDragHandle = true,
  });

  BorderRadius _radiusFor(int index) {
    if (itemCount <= 1) {
      return BorderRadius.all(outerRadius);
    } else if (index == 0) {
      return BorderRadius.only(
        topLeft: outerRadius,
        topRight: outerRadius,
        bottomLeft: innerRadius,
        bottomRight: innerRadius,
      );
    } else if (index == itemCount - 1) {
      return BorderRadius.only(
        topLeft: innerRadius,
        topRight: innerRadius,
        bottomLeft: outerRadius,
        bottomRight: outerRadius,
      );
    } else {
      return BorderRadius.all(innerRadius);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;

    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      // ignore: deprecated_member_use
      onReorder: onReorder,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 6,
        color: Colors.transparent,
        borderRadius: BorderRadius.all(outerRadius),
        child: child,
      ),
      itemBuilder: (context, index) {
        final Widget content = itemBuilder(context, index);
        final Key itemKey = keyBuilder != null
            ? keyBuilder!(index)
            : (content.key ?? ValueKey(index));

        return Padding(
          key: itemKey,
          padding: EdgeInsets.symmetric(horizontal: marginH, vertical: marginV),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: elevation,
            color: scheme.surfaceContainer,
            surfaceTintColor: scheme.primary,
            shape: RoundedRectangleBorder(borderRadius: _radiusFor(index)),
            clipBehavior: Clip.hardEdge,
            child: showDragHandle
                ? Row(
                    children: [
                      Expanded(child: content),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                : content,
          ),
        );
      },
    );
  }
}

/// Interactive and static card inner content layouts used inside [Cards.cardGroup].
///
/// Uses responsive [Row] and [Expanded] layouts instead of raw window physicalSize
/// math so cards never overflow in split-screen, desktop sidebars, or dialogs.
class CardContents {
  /// Standard tappable card row with bold title, optional subtitle, optional
  /// trailing widget, and optional animated [selected] highlight.
  static Widget tap({
    required String title,
    required String subtitle,
    required VoidCallback action,
    double? width,
    bool? mobile,
    Widget? trailing,
    bool selected = false,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    return Builder(
      builder: (context) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final Color? emphasisColor =
            selected ? scheme.onSecondaryContainer : null;
        final Color? subtitleColor = selected
            ? scheme.onSecondaryContainer.withValues(alpha: 0.85)
            : null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                action();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: IconTheme.merge(
                  data: IconThemeData(color: emphasisColor),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!hasSubtitle) const SizedBox(height: 10),
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: emphasisColor,
                              ),
                            ),
                            if (hasSubtitle) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: subtitleColor != null
                                    ? TextStyle(color: subtitleColor)
                                    : null,
                              ),
                            ] else
                              const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 12),
                        trailing,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Slider card row with title, optional subtitle, value readout, and Material 3 slider.
  static Widget slider({
    required String title,
    required double value,
    required double min,
    required double max,
    int? divisions,
    String? subtitle,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
    Widget? trailing,
  }) {
    final bool hasSubtitle = subtitle != null && subtitle.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 2),
                      Text(subtitle),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 6,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact tappable card row used inside dialogs (such as language pickers).
  static Widget halfTap({
    required String title,
    required String subtitle,
    required VoidCallback action,
    bool selected = false,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            action();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!hasSubtitle) const SizedBox(height: 5),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (hasSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(subtitle),
                      ] else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.check_circle_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tappable card row with a 35x35 circular leading icon badge and optional
  /// animated [selected] highlight.
  static Widget tapIcon({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required IconData icon,
    required Color color,
    required Color colorBG,
    double? width,
    Widget? trailing,
    bool selected = false,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    return Builder(
      builder: (context) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final Color? emphasisColor =
            selected ? scheme.onSecondaryContainer : null;
        final Color? subtitleColor = selected
            ? scheme.onSecondaryContainer.withValues(alpha: 0.85)
            : null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                action();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      clipBehavior: Clip.hardEdge,
                      borderRadius: const BorderRadius.all(Radius.circular(35)),
                      child: Container(
                        height: 35,
                        width: 35,
                        color: colorBG,
                        child: Icon(
                          icon,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!hasSubtitle) const SizedBox(height: 10),
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: emphasisColor,
                            ),
                          ),
                          if (hasSubtitle) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: subtitleColor != null
                                  ? TextStyle(color: subtitleColor)
                                  : null,
                            ),
                          ] else
                            const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      IconTheme.merge(
                        data: IconThemeData(color: emphasisColor),
                        child: trailing,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Non-interactive display card content with title, subtitle, and optional
  /// trailing widget.
  static Widget static({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!hasSubtitle) const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else
                  const SizedBox(height: 10),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }

  /// Alias for [CardContents.static] to avoid keyword collisions if desired.
  static Widget staticCard({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) =>
      static(title: title, subtitle: subtitle, trailing: trailing);

  /// Progress card content with a rounded [LinearProgressIndicator].
  ///
  /// Pass [progress] < 0 for an indeterminate progress bar, or `0.0..1.0` for
  /// a determinate progress bar (`0.0` = empty, `1.0` = full).
  static Widget progress({
    required String title,
    required String subtitle,
    required String subsubtitle,
    required double progress,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    final bool hasSubsubtitle = subsubtitle.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
          if (hasSubtitle || hasSubsubtitle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasSubtitle)
                  Flexible(
                    child: Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (hasSubsubtitle)
                  Flexible(
                    child: Text(
                      subsubtitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: !hasSubtitle ? 9 : 5),
            child: LinearProgressIndicator(
              value: progress < 0 ? null : progress.clamp(0.0, 1.0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  /// Split-action card row: tapping the main body triggers [action], while
  /// tapping the trailing icon button after the vertical divider triggers
  /// [secondAction]. Supports optional animated [selected] highlight.
  static Widget doubleTap({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required VoidCallback secondAction,
    required IconData icon,
    double? width,
    bool? mobile,
    String? secondTooltip,
    bool selected = false,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    return Builder(
      builder: (context) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final Color? emphasisColor =
            selected ? scheme.onSecondaryContainer : null;
        final Color? subtitleColor = selected
            ? scheme.onSecondaryContainer.withValues(alpha: 0.85)
            : null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                action();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!hasSubtitle) const SizedBox(height: 10),
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: emphasisColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasSubtitle) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: subtitleColor != null
                                    ? TextStyle(color: subtitleColor)
                                    : null,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ] else
                              const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VerticalDivider(
                            thickness: 3,
                            color: selected
                                ? scheme.onSecondaryContainer
                                    .withValues(alpha: 0.28)
                                : null,
                          ),
                          IconButton(
                            tooltip: secondTooltip,
                            icon: Icon(
                              icon,
                              size: 32,
                              color: emphasisColor,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              secondAction();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Backwards-compatible alias for `ggscanus`'s width-constrained [doubleTap].
  static Widget doubleTapWidth({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required VoidCallback secondAction,
    required double width,
    required IconData icon,
    bool selected = false,
  }) {
    return doubleTap(
      title: title,
      subtitle: subtitle,
      action: action,
      secondAction: secondAction,
      width: width,
      icon: icon,
      selected: selected,
    );
  }

  /// Card row supporting both tap ([action]) and long-press ([longAction]).
  static Widget longTap({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required VoidCallback longAction,
    bool? mobile,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        action();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        longAction();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hasSubtitle) const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(subtitle),
                  ] else
                    const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle switch card row.
  ///
  /// Fixes the empty-subtitle vertical alignment bug: when [subtitle] is empty,
  /// no empty [Text] widget is rendered so single-line switch rows stay centered.
  static Widget turn({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required ValueChanged<bool> switcher,
    required bool value,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        action();
      },
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 10,
          right: 15,
          left: 20,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(subtitle),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                switcher(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Stepper card row with decrement (`-`) and increment (`+`) icon buttons.
  ///
  /// Wraps the title/subtitle column in [Expanded] so long text never overflows.
  static Widget addretract({
    required String title,
    required String subtitle,
    required VoidCallback actionAdd,
    required VoidCallback actionRetract,
    String? valueLabel,
  }) {
    final bool hasSubtitle = subtitle.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
        right: 15,
        left: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(subtitle),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  actionRetract();
                },
              ),
              if (valueLabel != null && valueLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    valueLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  actionAdd();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card row displaying an inline banner ad fitted to the card as best as possible.
  ///
  /// Contains strictly the banner element without extra titles, headers, or icons.
  /// Automatically takes on the surrounding [CardGroup]'s segmented radii (20px/5px)
  /// and surface container styling.
  static Widget ad({
    Widget? child,
    bool isLoaded = true,
    double bannerWidth = 320.0,
    double bannerHeight = 50.0,
    BoxFit fit = BoxFit.contain,
    VoidCallback? action,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    // Optional backwards compatibility parameters (ignored as ad displays strictly the banner)
    String? title,
    String? subtitle,
    String? badgeLabel,
    IconData? icon,
    double? minHeight,
  }) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        final Widget bannerContent = (isLoaded && child != null)
            ? child
            : Container(
                width: bannerWidth,
                height: bannerHeight,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'AdMob Test Banner (320Г—50)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

        final Widget fittedBanner = Padding(
          padding: padding,
          child: Center(
            child: FittedBox(
              fit: fit,
              alignment: Alignment.center,
              child: SizedBox(
                width: bannerWidth,
                height: bannerHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: bannerContent,
                ),
              ),
            ),
          ),
        );

        if (action != null) {
          return InkWell(onTap: action, child: fittedBanner);
        }
        return fittedBanner;
      },
    );
  }

  /// Convenience alias for [CardContents.ad].
  static Widget bannerAd({
    Widget? child,
    bool isLoaded = true,
    double bannerWidth = 320.0,
    double bannerHeight = 50.0,
    BoxFit fit = BoxFit.contain,
    VoidCallback? action,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    String? title,
    String? subtitle,
    String? badgeLabel,
    IconData? icon,
    double? minHeight,
  }) =>
      ad(
        child: child,
        isLoaded: isLoaded,
        bannerWidth: bannerWidth,
        bannerHeight: bannerHeight,
        fit: fit,
        action: action,
        padding: padding,
        title: title,
        subtitle: subtitle,
        badgeLabel: badgeLabel,
        icon: icon,
        minHeight: minHeight,
      );
}

/// Lowercase alias preserving 100% compatibility with `ggscanus` call sites.
// ignore: camel_case_types
typedef cardContents = CardContents;

/// Section headers and dividers used above card groups.
class Category {
  /// Standard Material 3 primary-tinted section label above a [Cards.cardGroup].
  static Widget settings({
    required String title,
    required BuildContext context,
    Widget? trailing,
  }) {
    final textWidget = Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
      child: trailing == null
          ? textWidget
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: textWidget),
                trailing,
              ],
            ),
    );
  }

  /// Large thin display section header with right-aligned item count from `Website`.
  static Widget headerLine(
    String title,
    int count, [
    double? width,
    Color? color,
  ]) {
    final row = Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 32,
              color: color,
              fontWeight: FontWeight.w100,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 32,
            color: color,
            fontWeight: FontWeight.w100,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
      child: width != null
          ? SizedBox(
              width: (width - 30).clamp(0.0, double.infinity), child: row)
          : row,
    );
  }

  /// Thin 24px section divider label from `ggscanus`.
  static Widget divider(String name, {double leftPadding = 20}) {
    return Padding(
      padding: EdgeInsets.only(
        top: 10,
        left: leftPadding,
        right: 15,
        bottom: 5,
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w100,
        ),
      ),
    );
  }
}

/// Informational footer blocks with an outline info icon, description text,
/// and an optional underlined link/action.
class TextPart {
  /// Standard informational block with `bottom: 50` padding.
  static Widget info({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required BuildContext context,
  }) {
    return _buildInfo(
      title: title,
      subtitle: subtitle,
      action: action,
      context: context,
      bottomPadding: 50,
    );
  }

  /// Compact informational block with `bottom: 0` padding.
  static Widget infoShort({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required BuildContext context,
  }) {
    return _buildInfo(
      title: title,
      subtitle: subtitle,
      action: action,
      context: context,
      bottomPadding: 0,
    );
  }

  static Widget _buildInfo({
    required String title,
    required String subtitle,
    required VoidCallback action,
    required BuildContext context,
    required double bottomPadding,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 20,
        right: 20,
        top: 10,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: scheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 5),
              InkWell(
                onTap: action,
                child: Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Instance method for backwards-compatibility with `text().userMessage(...)`
  /// in `geminilocal` and `the2k48`.
  Widget userMessage(String textStr, BuildContext context, [double? width]) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 50,
        left: 20,
        right: 20,
        top: 10,
      ),
      child: SizedBox(
        width: width != null
            ? (width - 40).clamp(0.0, double.infinity)
            : double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: scheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 20),
            Text(
              textStr,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lowercase alias preserving 100% compatibility with `text.info(...)` call sites
/// in `geminilocal`, `the2k48`, and `Website`.
// ignore: camel_case_types
typedef text = TextPart;
