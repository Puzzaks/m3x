import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_ui/m3x_ui.dart';

void main() {
  group('SettingsBentoHeader', () {
    testWidgets('onHeaderTap fires when tapping the top wide card',
        (tester) async {
      int headerTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: SettingsBentoHeader(
              appName: 'M3x Demo',
              subtitle: 'https://puzzak.page',
              versionDisplay: '1.0.0 (Nov 23, 2026)',
              connectedModulesCount: 3,
              onHeaderTap: () => headerTaps++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('M3x Demo'));
      await tester.pumpAndSettle();

      expect(headerTaps, equals(1));
    });

    testWidgets(
        'showDependenciesDialog labels pub.dev m3x_ui as M3x Ecosystem (pub.dev)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SettingsBentoHeader.showDependenciesDialog(
                  context,
                  dependencies: const {
                    'm3x_ui': '^0.1.3',
                    'http': '^1.2.0',
                    'custom_git': 'git: https://github.com/Puzzaks/m3x.git',
                  },
                ),
                child: const Text('Open Deps'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Deps'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.text('M3x Ecosystem (pub.dev)'), findsOneWidget);
      expect(find.text('pub.dev Dependency'), findsOneWidget);
      expect(find.text('Git Dependency'), findsOneWidget);
      expect(find.text('Local Workspace Package'), findsNothing);
    });

    testWidgets(
        'showDependenciesDialog labels path dependency as Local Workspace Package',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SettingsBentoHeader.showDependenciesDialog(
                  context,
                  dependencies: const {
                    'm3x_ui': 'path: ../m3x_ui',
                  },
                ),
                child: const Text('Open Local Deps'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Local Deps'));
      await tester.pumpAndSettle();

      expect(find.text('Local Workspace Package'), findsOneWidget);
      expect(find.text('M3x Ecosystem (pub.dev)'), findsNothing);
    });

    testWidgets(
        'showChangelogDialog renders inside DraggableScrollableSheet (not AlertDialog)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SettingsBentoHeader.showChangelogDialog(
                  context,
                  title: 'Release Notes',
                  subtitle: '0.1.4',
                  changelogContent: '## 0.1.4\n- Added onHeaderTap support.',
                ),
                child: const Text('Open Changelog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Changelog'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Release Notes'), findsOneWidget);
      expect(find.text('0.1.4'), findsWidgets);
      expect(find.text('Added onHeaderTap support.'), findsOneWidget);
    });
  });
}
