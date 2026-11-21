import 'package:flutter/material.dart';
import 'package:m3x_ui/m3x_ui.dart';

class _DemoItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final String summary;

  const _DemoItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.summary,
  });
}

const List<_DemoItem> _sampleItems = [
  _DemoItem(
    id: 'paios_chat',
    title: 'PAIOS Local AI Session',
    subtitle: 'Gemini Nano • On-device streaming',
    category: 'Master-Detail',
    icon: Icons.psychology_alt_rounded,
    summary:
        'Demonstrates zero-Navigator-duplication resizing: select this item at 380px Phone width, drag the width slider past 680px, and watch Master + Detail expand side-by-side without losing state.',
  ),
  _DemoItem(
    id: 'ptk_node',
    title: 'Kyiv Edge Telemetry Node',
    subtitle: '99.98% uptime • 14 ms ping',
    category: 'Monitoring',
    icon: Icons.dns_rounded,
    summary:
        'Detail panes automatically use a rounded Material 3 surfaceContainerLowest container (24px radius) with smooth fade + horizontal slide AnimatedSwitcher transitions keyed by detailKey.',
  ),
  _DemoItem(
    id: 'm3x_docs',
    title: 'M3x Adaptive Guidelines',
    subtitle: 'Compact <680 • Medium 680–960 • Expanded ≥960',
    category: 'Architecture',
    icon: Icons.auto_awesome_mosaic_rounded,
    summary:
        'All M3x scaffolds use LayoutBuilder, Expanded, and AnimatedContainer — never platformDispatcher.views.first.physicalSize — ensuring crisp adaptation on foldables, split-screen, and desktop windows.',
  ),
];

/// Interactive Playground section demonstrating [M3xAdaptiveMasterDetail],
/// [M3xAdaptiveSplitHero], [M3xAdaptiveContentFrame], [SliverPageScaffold]
/// (`embedded` + `adaptiveSidebar`), and `CardContents(..., selected: true)`.
class AdaptiveLayoutsLabSection extends StatefulWidget {
  const AdaptiveLayoutsLabSection({super.key});

  @override
  State<AdaptiveLayoutsLabSection> createState() =>
      _AdaptiveLayoutsLabSectionState();
}

class _AdaptiveLayoutsLabSectionState extends State<AdaptiveLayoutsLabSection> {
  double _simulatedWidth = 760.0;
  bool _useFullContainerWidth = true;
  bool _masterCollapsed = false;
  String? _selectedId = _sampleItems.first.id;
  bool _showHeroPreview = false;

  void _openFullScreenMasterDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'DemoAdaptiveMasterDetailPage'),
        builder: (_) => const _FullScreenMasterDetailDemo(),
      ),
    );
  }

  void _openFullScreenSplitHero(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'DemoAdaptiveSplitHeroPage'),
        builder: (_) => const _FullScreenSplitHeroDemo(),
      ),
    );
  }

  void _openFullScreenSidebarScaffold(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'DemoAdaptiveSidebarScaffoldPage'),
        builder: (_) => const _FullScreenSidebarScaffoldDemo(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Category.settings(
          title: 'Adaptive Layouts Lab (Phone ↔ Foldable ↔ Desktop)',
          context: context,
        ),
        context.cards.cardGroup([
          CardContents.tapIcon(
            title: 'Launch Full-Screen M3xAdaptiveMasterDetail',
            subtitle:
                'Resize the live app window to test 400px ↔ 680px ↔ 1200px + draggable splitter',
            icon: Icons.view_sidebar_rounded,
            color: scheme.onPrimaryContainer,
            colorBG: scheme.primaryContainer,
            action: () => _openFullScreenMasterDetail(context),
          ),
          CardContents.tapIcon(
            title: 'Launch Full-Screen M3xAdaptiveSplitHero',
            subtitle:
                'Adapts onboarding/welcome screens between stacked column (<760px) and 42%/58% split',
            icon: Icons.splitscreen_rounded,
            color: scheme.onSecondaryContainer,
            colorBG: scheme.secondaryContainer,
            action: () => _openFullScreenSplitHero(context),
          ),
          CardContents.tapIcon(
            title: 'Launch SliverPageScaffold + Adaptive Sidebar',
            subtitle:
                'Auto-centered 880px content frame with animated left TOC sidebar at ≥840px',
            icon: Icons.menu_book_rounded,
            color: scheme.onTertiaryContainer,
            colorBG: scheme.tertiaryContainer,
            action: () => _openFullScreenSidebarScaffold(context),
          ),
        ]),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Card(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxAvailable = constraints.maxWidth;
                  final double effectiveWidth = _useFullContainerWidth
                      ? maxAvailable
                      : _simulatedWidth.clamp(320.0, maxAvailable);
                  final M3xWindowSizeClass sizeClass =
                      M3xWindowSizeClass.fromWidth(effectiveWidth);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            avatar: Icon(
                              sizeClass.isExpanded
                                  ? Icons.desktop_windows_rounded
                                  : (sizeClass.isSplit
                                      ? Icons.tablet_android_rounded
                                      : Icons.smartphone_rounded),
                              size: 16,
                            ),
                            label: Text(
                              '${sizeClass.name.toUpperCase()} • ${effectiveWidth.round()}dp',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Master-Detail'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Split Hero'),
                              ),
                            ],
                            selected: {_showHeroPreview},
                            onSelectionChanged: (s) =>
                                setState(() => _showHeroPreview = s.first),
                          ),
                          if (!_showHeroPreview) ...[
                            FilterChip(
                              label: Text(
                                _masterCollapsed
                                    ? 'Expand Sidebar'
                                    : 'Collapse Sidebar',
                              ),
                              selected: _masterCollapsed,
                              visualDensity: VisualDensity.compact,
                              onSelected: (v) =>
                                  setState(() => _masterCollapsed = v),
                            ),
                            ActionChip(
                              label: const Text('Clear Selection'),
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  setState(() => _selectedId = null),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Auto Fit'),
                            selected: _useFullContainerWidth,
                            visualDensity: VisualDensity.compact,
                            onSelected: (_) =>
                                setState(() => _useFullContainerWidth = true),
                          ),
                          for (final double preset in const [380, 720, 1020])
                            if (preset <= maxAvailable)
                              ChoiceChip(
                                label: Text('${preset.toInt()}dp'),
                                selected: !_useFullContainerWidth &&
                                    (_simulatedWidth - preset).abs() < 10,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => setState(() {
                                  _useFullContainerWidth = false;
                                  _simulatedWidth = preset;
                                }),
                              ),
                        ],
                      ),
                      if (maxAvailable > 360) ...[
                        Slider(
                          value: effectiveWidth.clamp(320.0, maxAvailable),
                          min: 320.0,
                          max: maxAvailable,
                          label: '${effectiveWidth.round()}dp',
                          onChanged: (val) {
                            setState(() {
                              _useFullContainerWidth = false;
                              _simulatedWidth = val;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 6),
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: effectiveWidth,
                          height: 430,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _showHeroPreview
                              ? _buildInlineHeroPreview(context)
                              : _buildInlineMasterDetail(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineMasterDetail(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final _DemoItem? activeItem = _selectedId == null
        ? null
        : _sampleItems.firstWhere(
            (e) => e.id == _selectedId,
            orElse: () => _sampleItems.first,
          );

    return M3xAdaptiveMasterDetail(
      hasSelection: activeItem != null,
      detailKey: activeItem?.id,
      masterCollapsed: _masterCollapsed,
      mediumMasterWidth: 260,
      expandedMasterWidth: 320,
      minMasterWidth: 220,
      maxMasterWidth: 420,
      emptyDetailBuilder: (context) => EmptyStateView(
        icon: Icons.touch_app_rounded,
        title: 'Select an Item',
        description:
            'Tap any card in the master pane to inspect its detail view, or drag the vertical handle to resize panes.',
      ),
      masterBuilder: (context, isSplit, openDetail) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Category.settings(
              title: isSplit ? 'Master Pane (Split)' : 'Master Pane (Compact)',
              context: context,
            ),
            CardGroup(
              children: [
                for (final item in _sampleItems)
                  CardContents.tapIcon(
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    color: scheme.onPrimaryContainer,
                    colorBG: scheme.primaryContainer,
                    selected: _selectedId == item.id,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    action: () {
                      setState(() => _selectedId = item.id);
                      openDetail();
                    },
                  ),
              ],
            ),
          ],
        );
      },
      detailBuilder: (context, isSplit, closeDetail) {
        final _DemoItem item = activeItem ?? _sampleItems.first;
        return SliverPageScaffold(
          title: item.title,
          embedded: true,
          showBackButton: !isSplit,
          onBack: closeDetail,
          bottomSpacing: 24,
          actions: [
            if (isSplit)
              IconButton(
                tooltip: _masterCollapsed ? 'Show sidebar' : 'Hide sidebar',
                icon: Icon(
                  _masterCollapsed
                      ? Icons.dock_rounded
                      : Icons.fullscreen_rounded,
                ),
                onPressed: () =>
                    setState(() => _masterCollapsed = !_masterCollapsed),
              ),
          ],
          children: [
            Category.settings(title: item.category, context: context),
            CardGroup(
              children: [
                CardContents.static(
                  title: item.subtitle,
                  subtitle: item.summary,
                ),
                CardContents.doubleTap(
                  title: 'CardContents.doubleTap (Selected Demo)',
                  subtitle: 'Selected state tints container with secondaryContainer',
                  icon: Icons.check_circle_outline_rounded,
                  selected: true,
                  action: () {},
                  secondAction: () {},
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInlineHeroPreview(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return M3xAdaptiveSplitHero(
      heroPane: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 36,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'M3xAdaptiveSplitHero',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stacks vertically below 760dp and transitions smoothly into a 42% / 58% two-column layout on wider viewports.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      contentPane: CardGroup(
        marginH: 0,
        children: [
          CardContents.tap(
            title: 'Zero Physical-Pixel Math',
            subtitle: 'Powered strictly by LayoutBuilder + AnimatedSwitcher',
            selected: true,
            action: () {},
          ),
          CardContents.tap(
            title: 'Ideal for Onboarding & Auth',
            subtitle: 'Keeps brand artwork & interactive controls balanced',
            action: () {},
          ),
        ],
      ),
    );
  }
}

class _FullScreenMasterDetailDemo extends StatefulWidget {
  const _FullScreenMasterDetailDemo();

  @override
  State<_FullScreenMasterDetailDemo> createState() =>
      _FullScreenMasterDetailDemoState();
}

class _FullScreenMasterDetailDemoState
    extends State<_FullScreenMasterDetailDemo> {
  String? _selectedId = _sampleItems.first.id;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final _DemoItem? activeItem = _selectedId == null
        ? null
        : _sampleItems.firstWhere(
            (e) => e.id == _selectedId,
            orElse: () => _sampleItems.first,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('M3xAdaptiveMasterDetail'),
        actions: [
          IconButton(
            tooltip: _collapsed ? 'Expand sidebar' : 'Collapse sidebar',
            icon: Icon(
              _collapsed
                  ? Icons.view_sidebar_outlined
                  : Icons.view_sidebar_rounded,
            ),
            onPressed: () => setState(() => _collapsed = !_collapsed),
          ),
        ],
      ),
      body: M3xAdaptiveMasterDetail(
        hasSelection: activeItem != null,
        detailKey: activeItem?.id,
        masterCollapsed: _collapsed,
        emptyDetailBuilder: (_) => const EmptyStateView(
          icon: Icons.auto_awesome_mosaic_rounded,
          title: 'Nothing Selected',
          description: 'Choose an item from the master pane.',
        ),
        masterBuilder: (context, isSplit, openDetail) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Category.settings(
                title: isSplit ? 'Items (Split Mode)' : 'Items (Compact Mode)',
                context: context,
              ),
              CardGroup(
                children: [
                  for (final item in _sampleItems)
                    CardContents.tapIcon(
                      title: item.title,
                      subtitle: item.subtitle,
                      icon: item.icon,
                      color: scheme.onPrimaryContainer,
                      colorBG: scheme.primaryContainer,
                      selected: _selectedId == item.id,
                      action: () {
                        setState(() => _selectedId = item.id);
                        openDetail();
                      },
                    ),
                ],
              ),
            ],
          );
        },
        detailBuilder: (context, isSplit, closeDetail) {
          final _DemoItem item = activeItem ?? _sampleItems.first;
          return SliverPageScaffold(
            title: item.title,
            embedded: true,
            showBackButton: !isSplit,
            onBack: closeDetail,
            children: [
              Category.settings(title: item.category, context: context),
              CardGroup(
                children: [
                  CardContents.static(
                    title: item.subtitle,
                    subtitle: item.summary,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FullScreenSplitHeroDemo extends StatelessWidget {
  const _FullScreenSplitHeroDemo();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('M3xAdaptiveSplitHero')),
      body: M3xAdaptiveSplitHero(
        heroPane: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.devices_rounded,
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Adaptive Welcome Hero',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Resize the window across 760dp to transition smoothly between single-column mobile and side-by-side desktop.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        contentPane: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardGroup(
              marginH: 0,
              children: [
                CardContents.tap(
                  title: 'Phone (< 760dp)',
                  subtitle: 'Single centered scrollable column (maxWidth: 580)',
                  selected: true,
                  action: () {},
                ),
                CardContents.tap(
                  title: 'Foldable & Desktop (≥ 760dp)',
                  subtitle: '42% Hero Pane + 58% Content Pane (maxWidth: 1080)',
                  action: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenSidebarScaffoldDemo extends StatefulWidget {
  const _FullScreenSidebarScaffoldDemo();

  @override
  State<_FullScreenSidebarScaffoldDemo> createState() =>
      _FullScreenSidebarScaffoldDemoState();
}

class _FullScreenSidebarScaffoldDemoState
    extends State<_FullScreenSidebarScaffoldDemo> {
  int _section = 0;

  static const List<({String title, String body})> _sections = [
    (
      title: 'Overview & Breakpoints',
      body:
          'SliverPageScaffold now defaults to maxContentWidth: 880.0 and adaptivePadding: true so every settings or documentation page automatically looks polished on tablets and desktops.',
    ),
    (
      title: 'Adaptive Sidebar',
      body:
          'Pass adaptiveSidebar to SliverPageScaffold and it smoothly animates in at sidebarBreakpoint (840dp) and collapses cleanly out on compact screens without RenderFlex overflow.',
    ),
    (
      title: 'Embedded Split Mode',
      body:
          'Passing embedded: true disables automatic back buttons, switches to a sleeker pinned SliverAppBar, and makes the scaffold background transparent to blend seamlessly inside M3xAdaptiveMasterDetail.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final active = _sections[_section];
    return SliverPageScaffold(
      title: 'SliverPageScaffold Adaptive',
      adaptiveSidebar: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Category.settings(title: 'Table of Contents', context: context),
          CardGroup(
            children: [
              for (int i = 0; i < _sections.length; i++)
                CardContents.tap(
                  title: _sections[i].title,
                  subtitle: '',
                  selected: _section == i,
                  action: () => setState(() => _section = i),
                ),
            ],
          ),
        ],
      ),
      children: [
        Category.settings(title: active.title, context: context),
        CardGroup(
          children: [
            CardContents.static(
              title: active.title,
              subtitle: active.body,
            ),
          ],
        ),
      ],
    );
  }
}
