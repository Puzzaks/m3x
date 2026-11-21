import 'dart:typed_data';

import 'package:demo/pages/agentic_mesh_lab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3x/m3x.dart';

void main() {
  group('puzzak_ui Elements & Complications', () {
    testWidgets('Cards.cardGroup renders 1, 2, and 3 cards in 1-col and 2-col modes without duplicating items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                child: context.cards.cardGroup(
                  [
                    CardContents.tap(
                      title: 'Card A',
                      subtitle: 'Subtitle A',
                      action: () {},
                    ),
                    CardContents.tap(
                      title: 'Card B',
                      subtitle: '',
                      action: () {},
                    ),
                    CardContents.addretract(
                      title: 'Card C with very long title that never overflows inside narrow constraints',
                      subtitle: 'Count: 5',
                      actionAdd: () {},
                      actionRetract: () {},
                    ),
                  ],
                  columns: 2,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsOneWidget);
      expect(
        find.text('Card C with very long title that never overflows inside narrow constraints'),
        findsOneWidget,
      );
    });

    testWidgets('CardContents.progress handles indeterminate (<0), 0.0, and 1.0 determinately', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CardContents.progress(
                  title: 'Zero',
                  subtitle: 'Empty',
                  subsubtitle: '0%',
                  progress: 0.0,
                ),
                CardContents.progress(
                  title: 'Full',
                  subtitle: 'Done',
                  subsubtitle: '100%',
                  progress: 1.0,
                ),
              ],
            ),
          ),
        ),
      );

      final indicators = tester
          .widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .toList();
      expect(indicators[0].value, 0.0);
      expect(indicators[1].value, 1.0);
    });

    testWidgets('TelemetrySparklineCard renders PTK-style title, value, subValue and progress gauge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelemetrySparklineCard(
              title: 'RAM Usage',
              valueText: '2.07 GB / 11.34 GB',
              subValue: '18.3%',
              progress: 0.183,
              history: const [0.1, 0.15, 0.18],
            ),
          ),
        ),
      );

      expect(find.text('RAM Usage'), findsOneWidget);
      expect(find.text('2.07 GB / 11.34 GB'), findsOneWidget);
      expect(find.text('18.3%'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Cards.cardGroup renders leadingCardWide layout correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => context.cards.cardGroup(
                [
                  CardContents.tap(
                    title: 'Header Card Wide',
                    subtitle: 'Subtitle Top',
                    action: () {},
                  ),
                  CardContents.tap(
                    title: 'Sub Card 1',
                    subtitle: 'Left',
                    action: () {},
                  ),
                  CardContents.tap(
                    title: 'Sub Card 2',
                    subtitle: 'Right',
                    action: () {},
                  ),
                ],
                columns: 2,
                leadingCardWide: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Header Card Wide'), findsOneWidget);
      expect(find.text('Sub Card 1'), findsOneWidget);
      expect(find.text('Sub Card 2'), findsOneWidget);
    });

    testWidgets('SettingsBentoHeader renders 3-card bento layout and invokes callbacks', (WidgetTester tester) async {
      bool versionTapped = false;
      bool modulesTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SettingsBentoHeader(
                appName: 'Puzzak Playground',
                subtitle: 'Modular M3 Suite',
                versionDisplay: '1.2.9 (Nov 5, 2026 (rev 02))',
                connectedModulesCount: 6,
                onVersionTap: () => versionTapped = true,
                onModulesTap: () => modulesTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Puzzak Playground'), findsOneWidget);
      expect(find.text('Modular M3 Suite'), findsOneWidget);
      expect(find.text('Version 1.2.9'), findsOneWidget);
      expect(find.text('Nov 5, 2026 (rev 02)'), findsOneWidget);
      expect(find.text('6 Packages'), findsOneWidget);
      expect(find.text('Tap to view'), findsOneWidget);

      await tester.tap(find.text('Nov 5, 2026 (rev 02)'));
      await tester.pumpAndSettle();
      expect(versionTapped, isTrue);

      await tester.tap(find.text('Tap to view'));
      await tester.pumpAndSettle();
      expect(modulesTapped, isTrue);
    });

    testWidgets('SettingsBentoHeader renders custom iconWidget, iconBytes, or falls back to defaultIconBytes', (WidgetTester tester) async {
      final Uint8List dummyBytes = Uint8List.fromList(<int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
        0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
        0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
        0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
        0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
        0x60, 0x82,
      ]);

      // 1. Test with explicit iconWidget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsBentoHeader(
              appName: 'Test App',
              subtitle: 'Sub',
              versionDisplay: '1.0.0',
              connectedModulesCount: 1,
              iconWidget: KeyedSubtree(
                key: ValueKey('custom_icon_widget'),
                child: SizedBox(width: 32, height: 32),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('custom_icon_widget')), findsOneWidget);

      // 2. Test with explicit iconBytes
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsBentoHeader(
              appName: 'Test App',
              subtitle: 'Sub',
              versionDisplay: '1.0.0',
              connectedModulesCount: 1,
              iconBytes: dummyBytes,
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);

      // 3. Test with defaultIconBytes (simulating M3x.init)
      SettingsBentoHeader.defaultIconBytes = dummyBytes;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsBentoHeader(
              appName: 'Test App',
              subtitle: 'Sub',
              versionDisplay: '1.0.0',
              connectedModulesCount: 1,
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      SettingsBentoHeader.defaultIconBytes = null;
    });

    testWidgets('AgenticMeshLabSection renders tools and toggles provider mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AgenticMeshLabSection(),
            ),
          ),
        ),
      );

      expect(find.text('Inter-App Agentic Mesh Lab'), findsOneWidget);
      expect(find.text('Simulated AI Provider Mode'), findsOneWidget);
      expect(find.text('PAIOS Gemini Nano'), findsOneWidget);
      expect(find.text('Cloud AI Studio'), findsOneWidget);
      expect(find.text('Execute Headless Tool Call'), findsOneWidget);

      // Tap Cloud AI Studio segment
      await tester.tap(find.text('Cloud AI Studio'));
      await tester.pumpAndSettle();
      expect(find.text('Online • Gemini 2.0 Flash (~320ms)'), findsOneWidget);

      // Execute tool call
      await tester.ensureVisible(find.text('Execute Headless Tool Call'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Execute Headless Tool Call'));
      await tester.pumpAndSettle();
      expect(find.text('Live JSON-RPC 2.0 Payloads'), findsOneWidget);
      expect(find.text('Request Payload:'), findsOneWidget);
      expect(find.text('Response Result:'), findsOneWidget);
    });

    testWidgets('MotionBlurContainer binds as plug-and-play container inside scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const SliverAppBar(title: Text('Static Title')),
                SliverToBoxAdapter(
                  child: MotionBlurContainer(
                    child: const Text('Blur Content'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Static Title'), findsOneWidget);
      expect(find.text('Blur Content'), findsOneWidget);
      expect(find.byType(MotionBlurContainer), findsOneWidget);
    });

    testWidgets('CardContents.slider renders title, subtitle, and updates value', (WidgetTester tester) async {
      double sliderVal = 8.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardContents.slider(
              title: 'Motion Blur Max Intensity',
              subtitle: '8.0 px',
              value: sliderVal,
              min: 2.0,
              max: 14.0,
              onChanged: (val) => sliderVal = val,
            ),
          ),
        ),
      );

      expect(find.text('Motion Blur Max Intensity'), findsOneWidget);
      expect(find.text('8.0 px'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('FloatingNavPill renders title, back button and trailing action', (WidgetTester tester) async {
      bool backPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => FloatingNavPill(
                title: 'Thinkpad.dev',
                onBack: () => backPressed = true,
                trailing: FloatingNavPill.actionButton(
                  context: ctx,
                  icon: Icons.help_outline_rounded,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Thinkpad.dev'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(backPressed, isTrue);
    });

    testWidgets('SubscriptionTierCard and AdPlaceholderCard render properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                SubscriptionTierCard(
                  title: 'Pro Supporter',
                  price: '\$2.99',
                  period: 'lifetime',
                  badgeText: 'LIFETIME',
                  features: const ['Fast updates', 'Cloud sync'],
                ),
                const AdPlaceholderCard(),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pro Supporter'), findsOneWidget);
      expect(find.text('\$2.99'), findsOneWidget);
      expect(find.text('Fast updates'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
      expect(find.text('Advertisement'), findsOneWidget);
    });

    testWidgets('CardContents.ad inserts seamlessly in-between other cards in cardGroup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Cards(context: context).cardGroup([
                  CardContents.tap(
                    title: 'Top Setting',
                    subtitle: 'First row',
                    action: () {},
                  ),
                  CardContents.ad(),
                  CardContents.turn(
                    title: 'Bottom Toggle',
                    subtitle: 'Third row',
                    value: true,
                    action: () {},
                    switcher: (v) {},
                  ),
                ]);
              },
            ),
          ),
        ),
      );

      expect(find.text('Top Setting'), findsOneWidget);
      expect(find.text('First row'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
      expect(find.text('AdMob Test Banner (320×50)'), findsOneWidget);
      expect(find.text('Bottom Toggle'), findsOneWidget);
    });

    testWidgets('CardContents.ad renders pure fitted child banner when loaded', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Cards(context: context).cardGroup([
                  CardContents.ad(
                    isLoaded: true,
                    child: const SizedBox(
                      width: 320,
                      height: 50,
                      child: Text('BANNER_WIDGET_CONTENT'),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      );

      expect(find.text('BANNER_WIDGET_CONTENT'), findsOneWidget);
    });
  });

  group('puzzak_ui_chat Duplicate History Preservation', () {
    testWidgets('ChatTextPart.chatlog preserves earlier identical messages like "ok"', (WidgetTester tester) async {
      final List<Map<String, String>> history = [
        {'user': 'User', 'message': 'ok'},
        {'user': 'Gemini', 'message': 'First reply'},
        {'user': 'User', 'message': 'ok'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ListView(
                children: ChatTextPart().chatlog(
                  aiChunk: '',
                  lastUser: 'ok',
                  conversation: history,
                  context: context,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('ok'), findsNWidgets(2));
    });
  });

  group('puzzak_dict & puzzak_core', () {
    test('Dictionary setSystemLanguage deletes override and falls back to en', () async {
      final storage = InMemoryDictionaryStorage({'language': 'uk'});
      final dict = Dictionary(
        path: 'assets/translations',
        storage: storage,
        systemLocaleProvider: () => 'fr', // unsupported locale -> should fallback to en
      );
      dict.languages = [
        {'id': 'en', 'name': 'English', 'origin': 'English'},
        {'id': 'uk', 'name': 'Ukrainian', 'origin': 'Українська'},
      ];

      await dict.setSystemLanguage();
      expect(storage.containsKey('language'), isFalse);
      expect(dict.locale, 'en');
    });

    test('AnalyticsService deduplicates consecutive identical logs and increments count', () {
      int notifyCount = 0;
      final logger = AnalyticsService(notifyEngine: () => notifyCount++);

      logger.log('Worker', 'info', 'Heartbeat');
      logger.log('Worker', 'info', 'Heartbeat');
      logger.log('Worker', 'info', 'Heartbeat');

      expect(logger.logs.length, 1);
      expect(logger.logs.first['count'], 3);
      expect(notifyCount, 3);
    });
  });

  group('m3x Master Umbrella & Versioning', () {
    test('M3x derives clean version display X.Y.Z (Month DD, YYYY (rev NN))', () {
      const yaml = '''
name: demo
description: "UI and library testing and updating playground for apps by Puzzak"
version: 1.2.9+26110502
repository: https://github.com/Puzzaks/demo
''';
      M3x.parsePubspec(yaml);
      expect(M3x.appName, 'demo');
      expect(M3x.appDescription, 'UI and library testing and updating playground for apps by Puzzak');
      expect(M3x.config.appDescription, 'UI and library testing and updating playground for apps by Puzzak');
      expect(M3x.versionDisplay, '1.2.9 (Nov 5, 2026 (rev 02))');
      expect(M3x.storageBoxName, 'demo_storage');
      expect(M3x.githubOwner, 'Puzzaks');
      expect(M3x.githubRepo, 'demo');
    });

    test('M3x.appIconBytes synchronizes with SettingsBentoHeader.defaultIconBytes', () {
      final Uint8List testBytes = Uint8List.fromList([1, 2, 3, 4]);
      M3x.appIconBytes = testBytes;
      expect(M3x.appIconBytes, equals(testBytes));
      expect(M3x.config.appIconBytes, equals(testBytes));
      expect(SettingsBentoHeader.defaultIconBytes, equals(testBytes));

      M3x.reset();
      expect(M3x.appIconBytes, isNull);
      expect(SettingsBentoHeader.defaultIconBytes, isNull);
    });
  });
}
