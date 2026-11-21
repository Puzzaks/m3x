import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:m3x_ui/m3x_ui.dart';
import '../engine.dart';

class ElementsTab extends StatelessWidget {
  const ElementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<PlaygroundEngine>(
      builder: (context, engine, _) {
        final bool longText = engine.stressTestLongStrings;
        final String suffix = longText
            ? ' — Stress-testing very long localized text that previously caused RenderFlex overflow in fixed width-subtraction layouts'
            : '';

        final List<Widget> dynamicGroupItems = List<Widget>.generate(
          engine.cardGroupItemCount,
          (i) => CardContents.tapIcon(
            title: 'Card #${i + 1} in ${engine.cardGroupColumns}-col group$suffix',
            subtitle:
                'Index $i of ${engine.cardGroupItemCount} (outer=20px, inner=5px)$suffix',
            icon: Icons.widgets_rounded,
            color: scheme.onPrimaryContainer,
            colorBG: scheme.primaryContainer,
            action: () => engine.logger.log(
              'CardGroup',
              'info',
              'Tapped Card #${i + 1} (cols=${engine.cardGroupColumns}, total=${engine.cardGroupItemCount})',
            ),
          ),
        );

        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              surfaceTintColor: Colors.transparent,
              pinned: true,
              title: Text(engine.dict.value('tab_elements')),
              actions: [
                FilterChip(
                  label: const Text('Long Text Stress-Test'),
                  selected: engine.stressTestLongStrings,
                  onSelected: (v) {
                    engine.stressTestLongStrings = v;
                    engine.logger.log(
                      'ElementsTab',
                      'info',
                      'Long-string overflow stress test: $v',
                    );
                    engine.genericRefresh();
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            SliverToBoxAdapter(
              child: MotionBlurContainer(
                enabled: engine.motionBlurEnabled,
                maxBlur: engine.motionBlurIntensity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Section 1: Segmented CardGroup & Multi-Column Bento Grid Tester
                  Category.settings(
                    title: engine.dict.value('card_groups'),
                    context: context,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Columns:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SegmentedButton<int>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1 Col')),
                            ButtonSegment(value: 2, label: Text('2 Cols (Web)')),
                            ButtonSegment(value: 3, label: Text('3 Cols')),
                          ],
                          selected: {engine.cardGroupColumns},
                          onSelectionChanged: (s) {
                            engine.cardGroupColumns = s.first;
                            engine.genericRefresh();
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cards:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SegmentedButton<int>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1')),
                            ButtonSegment(value: 2, label: Text('2')),
                            ButtonSegment(value: 3, label: Text('3')),
                            ButtonSegment(value: 4, label: Text('4')),
                            ButtonSegment(value: 5, label: Text('5')),
                          ],
                          selected: {engine.cardGroupItemCount},
                          onSelectionChanged: (s) {
                            engine.cardGroupItemCount = s.first;
                            engine.genericRefresh();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  context.cards.cardGroup(
                    dynamicGroupItems,
                    columns: engine.cardGroupColumns,
                  ),
                  TextPart.infoShort(
                    title:
                        'Try setting "2 Cols (Web)" + "3" or "5" cards above: each card renders once with accurate outer 20px and inner 5px radii (fixing the Website 3-card duplicate bug).',
                    subtitle: '',
                    action: () {},
                    context: context,
                  ),

                  // Section 2: All CardContents Archetypes
                  Category.settings(
                    title: engine.dict.value('card_contents'),
                    context: context,
                  ),
                  context.cards.cardGroup([
                    CardContents.tap(
                      title: 'CardContents.tap (With Subtitle)$suffix',
                      subtitle: 'Standard interactive row with bold 18px title$suffix',
                      action: () => engine.logger.log(
                        'CardContents',
                        'info',
                        'Tapped CardContents.tap (with subtitle)',
                      ),
                    ),
                    CardContents.tap(
                      title: 'CardContents.tap (Empty Subtitle — Auto-Centered)$suffix',
                      subtitle: '',
                      action: () => engine.logger.log(
                        'CardContents',
                        'info',
                        'Tapped CardContents.tap (empty subtitle)',
                      ),
                    ),
                    CardContents.tapIcon(
                      title: 'CardContents.tapIcon$suffix',
                      subtitle: '35×35 circular badge + Expanded title/subtitle column$suffix',
                      icon: Icons.bolt_rounded,
                      color: scheme.onTertiaryContainer,
                      colorBG: scheme.tertiaryContainer,
                      action: () => engine.logger.log(
                        'CardContents',
                        'info',
                        'Tapped CardContents.tapIcon',
                      ),
                    ),
                    CardContents.doubleTap(
                      title: '${engine.dict.value('select_language')}$suffix',
                      subtitle:
                          '${engine.dict.currentLanguageName} (${engine.dict.locale.toUpperCase()}) — ${engine.dict.value('select_language_subtitle')}$suffix',
                      icon: Icons.language_rounded,
                      secondTooltip: 'Reset to system language',
                      action: () {
                        OptionPickerDialog.show<String>(
                          context: context,
                          title: engine.dict.value('select_language'),
                          currentValue: engine.dict.locale,
                          options: engine.dict.languages
                              .map(
                                (lang) => OptionPickerItem<String>(
                                  value: lang['id'].toString(),
                                  title: lang['name'].toString(),
                                  subtitle: lang['origin'].toString(),
                                ),
                              )
                              .toList(),
                          onSelected: (code) => engine.selectLanguage(code),
                        );
                      },
                      secondAction: () => engine.resetToSystemLanguage(),
                    ),
                    CardContents.longTap(
                      title: 'CardContents.longTap$suffix',
                      subtitle:
                          'Tap for hint, long-press to reset counter (currently ${engine.counterValue})$suffix',
                      action: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hold (long-press) this card to reset the counter!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      longAction: () {
                        engine.counterValue = 0;
                        engine.logger.log(
                          'CardContents',
                          'warning',
                          'Counter reset to 0 via CardContents.longTap',
                        );
                        engine.genericRefresh();
                      },
                    ),
                    CardContents.turn(
                      title: 'CardContents.turn (With Subtitle)$suffix',
                      subtitle: 'Tapping row or dragging Switch both toggle state$suffix',
                      value: engine.switchWithSubtitle,
                      action: () {
                        engine.switchWithSubtitle = !engine.switchWithSubtitle;
                        engine.genericRefresh();
                      },
                      switcher: (v) {
                        engine.switchWithSubtitle = v;
                        engine.genericRefresh();
                      },
                    ),
                    CardContents.turn(
                      title:
                          'CardContents.turn (Empty Subtitle — Vertically Centered Fix)$suffix',
                      subtitle: '',
                      value: engine.switchWithoutSubtitle,
                      action: () {
                        engine.switchWithoutSubtitle = !engine.switchWithoutSubtitle;
                        engine.genericRefresh();
                      },
                      switcher: (v) {
                        engine.switchWithoutSubtitle = v;
                        engine.genericRefresh();
                      },
                    ),
                    CardContents.ad(
                      action: () => engine.logger.log(
                        'CardContents',
                        'info',
                        'Tapped in-between CardContents.ad banner',
                      ),
                    ),
                    CardContents.addretract(
                      title: 'CardContents.addretract (Overflow-Safe)$suffix',
                      subtitle: 'Active worker threads: ${engine.counterValue}$suffix',
                      valueLabel: '${engine.counterValue}',
                      actionRetract: () {
                        if (engine.counterValue > 0) engine.counterValue--;
                        engine.genericRefresh();
                      },
                      actionAdd: () {
                        engine.counterValue++;
                        engine.genericRefresh();
                      },
                    ),
                    CardContents.static(
                      title: 'CardContents.static$suffix',
                      subtitle: 'Read-only key-value display row inside cardGroup$suffix',
                    ),
                    CardContents.progress(
                      title: 'CardContents.progress$suffix',
                      subtitle: engine.progressDemoValue < 0
                          ? 'Indeterminate mode (progress < 0)'
                          : 'Determinate mode',
                      subsubtitle: engine.progressDemoValue < 0
                          ? '∞'
                          : '${(engine.progressDemoValue * 100).round()}%',
                      progress: engine.progressDemoValue,
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Progress state:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ActionChip(
                          label: const Text('Indeterminate (-1.0)'),
                          onPressed: () {
                            engine.progressDemoValue = -1.0;
                            engine.genericRefresh();
                          },
                        ),
                        ActionChip(
                          label: const Text('0% (Determinate Empty)'),
                          onPressed: () {
                            engine.progressDemoValue = 0.0;
                            engine.genericRefresh();
                          },
                        ),
                        ActionChip(
                          label: const Text('65%'),
                          onPressed: () {
                            engine.progressDemoValue = 0.65;
                            engine.genericRefresh();
                          },
                        ),
                        ActionChip(
                          label: const Text('100% (Determinate Full)'),
                          onPressed: () {
                            engine.progressDemoValue = 1.0;
                            engine.genericRefresh();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Section 3: ReorderableCardGroup
                  Category.settings(
                    title: engine.dict.value('reorderable_cards'),
                    context: context,
                  ),
                  ReorderableCardGroup(
                    itemCount: engine.reorderableServers.length,
                    keyBuilder: (i) => ValueKey(engine.reorderableServers[i].id),
                    onReorder: engine.reorderServers,
                    itemBuilder: (context, index) {
                      final srv = engine.reorderableServers[index];
                      return CardContents.tapIcon(
                        title: '${index + 1}. ${srv.name}$suffix',
                        subtitle: '${srv.status} • ${srv.url}$suffix',
                        icon: Icons.dns_rounded,
                        color: scheme.onSecondaryContainer,
                        colorBG: scheme.secondaryContainer,
                        action: () => engine.logger.log(
                          'ReorderableCardGroup',
                          'info',
                          'Tapped server ${srv.name} at index $index',
                        ),
                      );
                    },
                  ),

                  // Section 4: Category & TextPart Headers / Footnotes
                  Category.headerLine(
                    'Category.headerLine (Website Style)',
                    engine.reorderableServers.length,
                  ),
                  Category.divider('Category.divider (ggscanus Style)'),
                  TextPart.info(
                    title:
                        'TextPart.info / text.info renders an info_outline_rounded icon, body text, and an optional underlined action link below.',
                    subtitle: 'Write test entry to AnalyticsService log',
                    action: () => engine.logger.log(
                      'TextPart.info',
                      'info',
                      'Clicked interactive footer link!',
                    ),
                    context: context,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      );
      },
    );
  }
}
