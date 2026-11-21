import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_ui/m3x_ui.dart';

Widget _wrapWithMaterial3(Widget child, {double? width}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: width != null
            ? Center(
                child: SizedBox(
                  width: width,
                  child: LayoutBuilder(
                    builder: (context, constraints) => child,
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) => child,
              ),
      ),
    ),
  );
}

void main() {
  group('Cards & CardGroup segmentation', () {
    testWidgets('borderRadiusForIndex assigns outer and inner radii accurately', (tester) async {
      late Cards cards;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              cards = context.cards;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Single card has all outer radii (20px)
      final singleRadius = cards.borderRadiusForIndex(0, 1);
      expect(singleRadius.topLeft, equals(const Radius.circular(20)));
      expect(singleRadius.bottomRight, equals(const Radius.circular(20)));

      // 3 cards in 1 column: top outer, middle inner, bottom outer
      final firstRadius = cards.borderRadiusForIndex(0, 3);
      expect(firstRadius.topLeft, equals(const Radius.circular(20)));
      expect(firstRadius.bottomLeft, equals(const Radius.circular(5)));

      final middleRadius = cards.borderRadiusForIndex(1, 3);
      expect(middleRadius.topLeft, equals(const Radius.circular(5)));
      expect(middleRadius.bottomRight, equals(const Radius.circular(5)));

      final lastRadius = cards.borderRadiusForIndex(2, 3);
      expect(lastRadius.topLeft, equals(const Radius.circular(5)));
      expect(lastRadius.bottomRight, equals(const Radius.circular(20)));
    });

    testWidgets('CardGroup renders single-column and multi-column layouts without error', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial3(
          Column(
            children: [
              CardGroup(
                children: [
                  CardContents.static(title: 'Node 1', subtitle: 'Online'),
                  CardContents.static(title: 'Node 2', subtitle: 'Standby'),
                ],
              ),
              CardGroup(
                columns: 2,
                leadingCardWide: true,
                children: [
                  CardContents.static(title: 'Bento Top', subtitle: 'Full width'),
                  CardContents.static(title: 'Bento Left', subtitle: 'Col 1'),
                  CardContents.static(title: 'Bento Right', subtitle: 'Col 2'),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Node 1'), findsOneWidget);
      expect(find.text('Node 2'), findsOneWidget);
      expect(find.text('Bento Top'), findsOneWidget);
      expect(find.text('Bento Left'), findsOneWidget);
      expect(find.text('Bento Right'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CardContents, Category, and TextPart interactions', () {
    testWidgets('CardContents.tap and CardContents.turn handle taps and switch toggles', (tester) async {
      int tapCount = 0;
      bool switchValue = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrapWithMaterial3(
              Builder(
                builder: (innerContext) => Column(
                  children: [
                    Category.settings(
                      title: 'General Settings',
                      context: innerContext,
                    ),
                    CardGroup(
                      children: [
                        CardContents.tap(
                          title: 'Server Endpoint',
                          subtitle: 'https://kyiv.puzzak.page/AIO.php',
                          action: () => tapCount++,
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                        CardContents.turn(
                          title: 'Background Alerts',
                          subtitle: 'Notify when server goes offline',
                          value: switchValue,
                          action: () => setState(() => switchValue = !switchValue),
                          switcher: (val) => setState(() => switchValue = val),
                        ),
                      ],
                    ),
                    TextPart.info(
                      title: 'All diagnostic logs remain strictly on-device.',
                      subtitle: 'View Privacy Policy',
                      action: () => tapCount += 10,
                      context: innerContext,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Server Endpoint'), findsOneWidget);
      expect(find.text('Background Alerts'), findsOneWidget);
      expect(find.text('All diagnostic logs remain strictly on-device.'), findsOneWidget);

      await tester.tap(find.text('Server Endpoint'));
      await tester.pumpAndSettle();
      expect(tapCount, equals(1));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(switchValue, isTrue);

      await tester.tap(find.text('View Privacy Policy'));
      await tester.pumpAndSettle();
      expect(tapCount, equals(11));
    });
  });

  group('Responsive wide and narrow LayoutBuilder constraints (no overflow)', () {
    for (final double constraintWidth in <double>[240.0, 320.0, 800.0]) {
      testWidgets(
        'renders CardGroup, CardContents.tap, CardContents.turn, Category.settings, and TextPart.info at ${constraintWidth.toInt()}px width without overflow',
        (tester) async {
          await tester.pumpWidget(
            _wrapWithMaterial3(
              width: constraintWidth,
              Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Category.settings(
                      title: 'Long Section Category Title For Stress Testing Layout',
                      context: context,
                      trailing: const Icon(Icons.tune_rounded, size: 18),
                    ),
                    CardGroup(
                      children: [
                        CardContents.tap(
                          title: 'Primary Endpoint Configuration With Long Title',
                          subtitle: 'https://edge-node-01.puzzak.page/api/v2/telemetry/stream',
                          action: () {},
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                        CardContents.turn(
                          title: 'Enable Real-Time High-Frequency Telemetry Polling',
                          subtitle: 'Polls endpoint every 1000ms and deduplicates logs',
                          value: true,
                          action: () {},
                          switcher: (_) {},
                        ),
                        CardContents.turn(
                          title: 'Single-Line Switch Row Without Subtitle',
                          subtitle: '',
                          value: false,
                          action: () {},
                          switcher: (_) {},
                        ),
                        CardContents.doubleTap(
                          title: 'Select Interface Language',
                          subtitle: 'Ukrainian (Українська)',
                          icon: Icons.restore_rounded,
                          action: () {},
                          secondAction: () {},
                        ),
                        CardContents.addretract(
                          title: 'Polling Interval Stepper',
                          subtitle: 'Adjust interval in seconds',
                          valueLabel: '15s',
                          actionAdd: () {},
                          actionRetract: () {},
                        ),
                        CardContents.progress(
                          title: 'Downloading Model Weights',
                          subtitle: '412.8 MB / 512.0 MB',
                          subsubtitle: '81%',
                          progress: 0.81,
                        ),
                      ],
                    ),
                    TextPart.info(
                      title: 'Telemetry requires AIO.php installed on your target host.',
                      subtitle: 'Download AIO.php on GitHub',
                      action: () {},
                      context: context,
                    ),
                  ],
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
