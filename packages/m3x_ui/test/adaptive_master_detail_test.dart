import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_ui/m3x_ui.dart';

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.teal,
    ),
    home: child,
  );
}

class _MasterDetailHarness extends StatefulWidget {
  final bool initialHasSelection;
  final bool masterCollapsed;
  final VoidCallback? onDetailClosed;

  const _MasterDetailHarness({
    this.initialHasSelection = false,
    this.masterCollapsed = false,
    this.onDetailClosed,
  });

  @override
  State<_MasterDetailHarness> createState() => _MasterDetailHarnessState();
}

class _MasterDetailHarnessState extends State<_MasterDetailHarness> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    if (widget.initialHasSelection) {
      _selectedId = 'item_1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: M3xAdaptiveMasterDetail(
        hasSelection: _selectedId != null,
        detailKey: _selectedId,
        masterCollapsed: widget.masterCollapsed,
        onDetailClosed: widget.onDetailClosed,
        emptyDetailBuilder: (context) =>
            const Center(child: Text('EMPTY_DETAIL_PLACEHOLDER')),
        masterBuilder: (context, isSplit, openDetail) {
          return ListView(
            children: [
              Text(isSplit ? 'MASTER_SPLIT' : 'MASTER_COMPACT'),
              CardGroup(
                children: [
                  CardContents.tap(
                    title: 'Item Alpha',
                    subtitle: 'Primary item',
                    selected: _selectedId == 'item_1',
                    action: () {
                      setState(() => _selectedId = 'item_1');
                      openDetail();
                    },
                  ),
                  CardContents.tap(
                    title: 'Item Beta',
                    subtitle: 'Secondary item',
                    selected: _selectedId == 'item_2',
                    action: () {
                      setState(() => _selectedId = 'item_2');
                      openDetail();
                    },
                  ),
                ],
              ),
            ],
          );
        },
        detailBuilder: (context, isSplit, closeDetail) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isSplit ? 'DETAIL_SPLIT' : 'DETAIL_COMPACT'),
              Text('SELECTED_${_selectedId ?? 'NONE'}'),
              TextButton(
                onPressed: closeDetail,
                child: const Text('CLOSE_DETAIL'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatefulCounterBody extends StatefulWidget {
  const _StatefulCounterBody();

  @override
  State<_StatefulCounterBody> createState() => _StatefulCounterBodyState();
}

class _StatefulCounterBodyState extends State<_StatefulCounterBody> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => setState(() => _count++),
        child: Text('BODY_COUNT_$_count'),
      ),
    );
  }
}

void main() {
  group('M3xWindowSizeClass', () {
    test('resolves compact, medium, and expanded across breakpoints', () {
      expect(M3xWindowSizeClass.fromWidth(360), M3xWindowSizeClass.compact);
      expect(M3xWindowSizeClass.fromWidth(679.9), M3xWindowSizeClass.compact);
      expect(M3xWindowSizeClass.fromWidth(680.0), M3xWindowSizeClass.medium);
      expect(M3xWindowSizeClass.fromWidth(959.9), M3xWindowSizeClass.medium);
      expect(M3xWindowSizeClass.fromWidth(960.0), M3xWindowSizeClass.expanded);
      expect(M3xWindowSizeClass.fromWidth(1440.0), M3xWindowSizeClass.expanded);

      expect(M3xWindowSizeClass.compact.isCompact, isTrue);
      expect(M3xWindowSizeClass.compact.isSplit, isFalse);
      expect(M3xWindowSizeClass.medium.isSplit, isTrue);
      expect(M3xWindowSizeClass.medium.isExpanded, isFalse);
      expect(M3xWindowSizeClass.expanded.isSplit, isTrue);
      expect(M3xWindowSizeClass.expanded.isExpanded, isTrue);
    });
  });

  group('M3xAdaptiveMasterDetail', () {
    testWidgets(
      'compact mode (400x800) shows master, opens detail on tap, and returns to master on closeDetail',
      (tester) async {
        _setViewport(tester, const Size(400, 800));
        int closedCalls = 0;
        await tester.pumpWidget(
          _buildTestApp(
            child: _MasterDetailHarness(
              onDetailClosed: () => closedCalls++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('MASTER_COMPACT'), findsOneWidget);
        expect(find.text('DETAIL_COMPACT'), findsNothing);

        await tester.tap(find.text('Item Alpha'));
        await tester.pumpAndSettle();

        expect(find.text('DETAIL_COMPACT'), findsOneWidget);
        expect(find.text('SELECTED_item_1'), findsOneWidget);
        expect(find.text('MASTER_COMPACT'), findsNothing);

        await tester.tap(find.text('CLOSE_DETAIL'));
        await tester.pumpAndSettle();

        expect(closedCalls, 1);
        expect(find.text('MASTER_COMPACT'), findsOneWidget);
        expect(find.text('DETAIL_COMPACT'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'live resize 400px (detail open) -> 1200px (both visible) -> 400px (still viewing detail)',
      (tester) async {
        _setViewport(tester, const Size(400, 800));

        await tester.pumpWidget(
          _buildTestApp(child: const _MasterDetailHarness()),
        );
        await tester.pumpAndSettle();

        // 1. Start at 400px -> tap Item Beta to open detail
        expect(find.text('MASTER_COMPACT'), findsOneWidget);
        await tester.tap(find.text('Item Beta'));
        await tester.pumpAndSettle();
        expect(find.text('DETAIL_COMPACT'), findsOneWidget);
        expect(find.text('SELECTED_item_2'), findsOneWidget);

        // 2. Resize live to 1200px -> both master and detail visible simultaneously
        tester.view.physicalSize = const Size(1200, 800);
        await tester.pumpAndSettle();
        expect(find.text('MASTER_SPLIT'), findsOneWidget);
        expect(find.text('DETAIL_SPLIT'), findsOneWidget);
        expect(find.text('SELECTED_item_2'), findsOneWidget);

        // 3. Resize back to 400px -> detail stays open cleanly without duplicate routes
        tester.view.physicalSize = const Size(400, 800);
        await tester.pumpAndSettle();
        expect(find.text('DETAIL_COMPACT'), findsOneWidget);
        expect(find.text('SELECTED_item_2'), findsOneWidget);
        expect(find.text('MASTER_COMPACT'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('masterCollapsed toggles master pane width cleanly to 0 and back',
        (tester) async {
      _setViewport(tester, const Size(1200, 800));
      final ValueNotifier<bool> collapsedNotifier = ValueNotifier<bool>(false);
      addTearDown(collapsedNotifier.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: collapsedNotifier,
          builder: (context, collapsed, _) {
            return _buildTestApp(
              child: _MasterDetailHarness(
                initialHasSelection: true,
                masterCollapsed: collapsed,
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      final Finder masterPaneFinder =
          find.byKey(const ValueKey<String>('m3x_adaptive_master_pane'));
      // Expanded breakpoint (>= 960) defaults to 1/3 proportional width (1200 / 3 = 400)
      expect(tester.getSize(masterPaneFinder).width, closeTo(400.0, 0.01));

      // Collapse master pane
      collapsedNotifier.value = true;
      await tester.pumpAndSettle();
      expect(tester.getSize(masterPaneFinder).width, equals(0.0));
      expect(find.text('DETAIL_SPLIT'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Expand master pane back
      collapsedNotifier.value = false;
      await tester.pumpAndSettle();
      expect(tester.getSize(masterPaneFinder).width, closeTo(400.0, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'computes proportional master widths: 50% at 800px (Foldable) and 1/3 at 1200px (Tablet/Laptop)',
      (tester) async {
        _setViewport(tester, const Size(800, 800));
        await tester.pumpWidget(
          _buildTestApp(
            child: const _MasterDetailHarness(initialHasSelection: true),
          ),
        );
        await tester.pumpAndSettle();

        final Finder masterPaneFinder =
            find.byKey(const ValueKey<String>('m3x_adaptive_master_pane'));

        // Medium / Foldable (800px): 50% of 800 = 400px
        expect(tester.getSize(masterPaneFinder).width, closeTo(400.0, 0.01));

        // Expanded / Tablet-Laptop (1200px): 1/3 of 1200 = 400px
        tester.view.physicalSize = const Size(1200, 800);
        await tester.pumpAndSettle();
        expect(tester.getSize(masterPaneFinder).width, closeTo(400.0, 0.01));

        // Wide Laptop (1500px): 1/3 of 1500 = 500px (within maxMasterWidth 560)
        tester.view.physicalSize = const Size(1500, 800);
        await tester.pumpAndSettle();
        expect(tester.getSize(masterPaneFinder).width, closeTo(500.0, 0.01));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('shows emptyDetailBuilder in split mode when nothing is selected',
        (tester) async {
      _setViewport(tester, const Size(1000, 800));
      await tester.pumpWidget(
        _buildTestApp(
          child: const _MasterDetailHarness(initialHasSelection: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MASTER_SPLIT'), findsOneWidget);
      expect(find.text('EMPTY_DETAIL_PLACEHOLDER'), findsOneWidget);
      expect(find.text('DETAIL_SPLIT'), findsNothing);

      await tester.tap(find.text('Item Alpha'));
      await tester.pumpAndSettle();

      expect(find.text('EMPTY_DETAIL_PLACEHOLDER'), findsNothing);
      expect(find.text('DETAIL_SPLIT'), findsOneWidget);
      expect(find.text('SELECTED_item_1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('M3xAdaptiveSplitHero', () {
    testWidgets('switches cleanly from stacked (500px) to side-by-side (1000px)',
        (tester) async {
      _setViewport(tester, const Size(500, 800));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: M3xAdaptiveSplitHero(
              heroPane: SizedBox(
                key: ValueKey('hero_pane'),
                height: 120,
                child: Text('HERO_PANE'),
              ),
              contentPane: SizedBox(
                key: ValueKey('content_pane'),
                height: 180,
                child: Text('CONTENT_PANE'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('m3x_split_hero_compact')), findsOneWidget);
      final Offset compactHeroPos =
          tester.getTopLeft(find.byKey(const ValueKey('hero_pane')));
      final Offset compactContentPos =
          tester.getTopLeft(find.byKey(const ValueKey('content_pane')));
      // Stacked vertically: content is below hero
      expect(compactContentPos.dy, greaterThan(compactHeroPos.dy));

      // Switch to 1000px wide -> side by side
      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('m3x_split_hero_wide')), findsOneWidget);
      final Offset wideHeroPos =
          tester.getTopLeft(find.byKey(const ValueKey('hero_pane')));
      final Offset wideContentPos =
          tester.getTopLeft(find.byKey(const ValueKey('content_pane')));
      // Side by side horizontally: content is to the right of hero
      expect(wideContentPos.dx, greaterThan(wideHeroPos.dx));
      expect(tester.takeException(), isNull);
    });
  });

  group('CardContents selected highlight', () {
    testWidgets('tap, doubleTap, and tapIcon render selected: true cleanly',
        (tester) async {
      _setViewport(tester, const Size(420, 800));
      await tester.pumpWidget(
        _buildTestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  return CardGroup(
                    children: [
                      CardContents.tap(
                        title: 'Selected Tap',
                        subtitle: 'Highlighted row',
                        selected: true,
                        action: () {},
                      ),
                      CardContents.doubleTap(
                        title: 'Selected DoubleTap',
                        subtitle: 'Split action row',
                        icon: Icons.edit_rounded,
                        selected: true,
                        action: () {},
                        secondAction: () {},
                      ),
                      CardContents.tapIcon(
                        title: 'Selected TapIcon',
                        subtitle: 'Leading badge row',
                        icon: Icons.star_rounded,
                        color: scheme.onPrimaryContainer,
                        colorBG: scheme.primaryContainer,
                        selected: true,
                        action: () {},
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selected Tap'), findsOneWidget);
      expect(find.text('Selected DoubleTap'), findsOneWidget);
      expect(find.text('Selected TapIcon'), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('M3xAdaptiveContentFrame', () {
    testWidgets(
        'constrains width to maxWidth and updates padding across breakpoints',
        (tester) async {
      _setViewport(tester, const Size(400, 600));

      await tester.pumpWidget(
        _buildTestApp(
          child: const Scaffold(
            body: M3xAdaptiveContentFrame(
              maxWidth: 720,
              child: SizedBox(
                key: ValueKey('framed_child'),
                width: double.infinity,
                height: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Compact (400px, zero horizontal padding)
      expect(
        tester.getSize(find.byKey(const ValueKey('framed_child'))).width,
        equals(400.0),
      );

      // Expanded (1200px, clamped to maxWidth: 720)
      tester.view.physicalSize = const Size(1200, 600);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('framed_child'))).width,
        equals(720.0),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SliverPageScaffold adaptive defaults', () {
    testWidgets(
        'clamps default maxContentWidth (880), supports embedded mode and adaptiveSidebar',
        (tester) async {
      _setViewport(tester, const Size(1200, 800));

      await tester.pumpWidget(
        _buildTestApp(
          child: SliverPageScaffold(
            title: 'Adaptive Docs',
            embedded: true,
            adaptiveSidebar: const ColoredBox(
              key: ValueKey('adaptive_sidebar_content'),
              color: Colors.transparent,
              child: Text('SIDEBAR_TOC'),
            ),
            children: const [
              SizedBox(
                key: ValueKey('sliver_body_probe'),
                width: double.infinity,
                height: 60,
                child: Text('MAIN_DOC_CONTENT'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Embedded disables back button by default
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.text('SIDEBAR_TOC'), findsOneWidget);
      expect(find.text('MAIN_DOC_CONTENT'), findsOneWidget);

      // Content probe clamped to <= 880px
      expect(
        tester.getSize(find.byKey(const ValueKey('sliver_body_probe'))).width,
        lessThanOrEqualTo(880.0),
      );

      // Shrink below sidebarBreakpoint (840px) -> sidebar collapses cleanly without overflow
      tester.view.physicalSize = const Size(500, 800);
      await tester.pumpAndSettle();
      expect(find.text('MAIN_DOC_CONTENT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AdaptiveNavScaffold smooth 3-tier breakpoints', () {
    testWidgets(
      'transitions smoothly across compact (400px), medium (760px), and expanded (1100px) while preserving body state',
      (tester) async {
        _setViewport(tester, const Size(400, 800));

        const destinations = [
          AdaptiveNavDestination(icon: Icons.home_outlined, label: 'Home'),
          AdaptiveNavDestination(
            icon: Icons.settings_outlined,
            label: 'Settings',
          ),
        ];

        await tester.pumpWidget(
          _buildTestApp(
            child: AdaptiveNavScaffold(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              destinations: destinations,
              body: const _StatefulCounterBody(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Compact: NavigationBar shown, NavigationRail hidden
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);

        // Mutate body state so we can prove body doesn't unmount across breakpoints
        await tester.tap(find.text('BODY_COUNT_0'));
        await tester.pumpAndSettle();
        expect(find.text('BODY_COUNT_1'), findsOneWidget);

        // Medium (760px): compact NavigationRail shown, NavigationBar hidden
        tester.view.physicalSize = const Size(760, 800);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(
          tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
          isFalse,
        );
        expect(find.text('BODY_COUNT_1'), findsOneWidget);

        // Expanded (1100px): extended NavigationRail shown
        tester.view.physicalSize = const Size(1100, 800);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(
          tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
          isTrue,
        );
        expect(find.text('BODY_COUNT_1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
