import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3x/m3x.dart';

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final content = _assets[key];
    if (content == null) {
      throw Exception('Asset not found: $key');
    }
    final bytes = utf8.encode(content);
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  group('M3x Umbrella Package & Metadata Parser', () {
    setUp(() {
      M3x.reset();
    });

    test('parsePubspec correctly derives all metadata with rev NN', () {
      const yaml = '''
name: demo
description: "UI and library testing and updating playground for apps by Puzzak"
version: 1.2.9+26110502
repository: https://github.com/Puzzaks/demo
''';

      M3x.parsePubspec(yaml);

      expect(M3x.appName, 'demo');
      expect(M3x.appDescription, 'UI and library testing and updating playground for apps by Puzzak');
      expect(M3x.appVersion, '1.2.9');
      expect(M3x.appBuildNumber, '26110502');
      expect(M3x.appBuildDate, 'Nov 5, 2026 (rev 02)');
      expect(M3x.versionDisplay, '1.2.9 (Nov 5, 2026 (rev 02))');
      expect(M3x.storageBoxName, 'demo_storage');
      expect(M3x.githubOwner, 'Puzzaks');
      expect(M3x.githubRepo, 'demo');
      expect(M3x.githubUrl, 'https://github.com/Puzzaks/demo');
    });

    test('formatBuildDate parses 8-digit and 6-digit codes', () {
      expect(M3x.formatBuildDate('26110601'), 'Nov 6, 2026 (rev 01)');
      expect(M3x.formatBuildDate('26010105'), 'Jan 1, 2026 (rev 05)');
      expect(M3x.formatBuildDate('251231'), 'Dec 31, 2025');
    });

    test('storageBoxName sanitizes spaces to underscores', () {
      const yaml = '''
name: Puzzak Ecosystem
version: 2.0.0
''';
      M3x.parsePubspec(yaml);
      expect(M3x.storageBoxName, 'puzzak_ecosystem_storage');
      expect(M3x.versionDisplay, '2.0.0');
    });

    test('auto-detects GitHub from homepage if repository is absent', () {
      const yaml = '''
name: cool_app
homepage: https://github.com/my-org/my-repo.git
version: 1.0.0+26051501
''';
      M3x.parsePubspec(yaml);
      expect(M3x.githubOwner, 'my-org');
      expect(M3x.githubRepo, 'my-repo');
      expect(M3x.versionDisplay, '1.0.0 (May 15, 2026 (rev 01))');
    });

    test('re-exports m3x_mesh, m3x_storage, and m3x_gh correctly', () {
      // Mesh re-export
      final tool = M3xTool(
        name: 'test_mesh_tool',
        description: 'Test mesh description',
      );
      expect(tool.name, equals('test_mesh_tool'));
      final client = M3xMeshClient(enableSimulation: true);
      expect(client.isSimulationMode, isTrue);

      // Storage re-export
      expect(M3xStorage.instance, isNotNull);

      // GitHub re-export
      expect(M3xGitHubService.instance, isNotNull);
      expect(M3xGitHubService.instance.owner, equals('Puzzaks'));
    });

    test('parsePubspec extracts single-line and multi-line dependencies and syncs SettingsBentoHeader', () {
      const yaml = '''
name: geminilocal
description: "Local AI, on-device client"
version: 1.3.2+26110903

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  m3x:
    path: ../demo/packages/m3x
  m3x_ui:
    path: ../demo/packages/m3x_ui
  provider: ^6.0.5 # state management
  dynamic_color: ">=1.8.1 <1.9.0"
  flutter_markdown: 0.7.7+1
  custom_git_pkg:
    git:
      url: https://github.com/Puzzaks/custom_git_pkg.git

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
''';

      M3x.parsePubspec(yaml);

      expect(M3x.dependencies.containsKey('flutter'), isFalse);
      expect(M3x.dependencies.containsKey('flutter_localizations'), isFalse);
      expect(M3x.dependencies.containsKey('flutter_lints'), isFalse);
      expect(M3x.dependencies['m3x'], 'path: ../demo/packages/m3x');
      expect(M3x.dependencies['m3x_ui'], 'path: ../demo/packages/m3x_ui');
      expect(M3x.dependencies['provider'], '^6.0.5');
      expect(M3x.dependencies['dynamic_color'], '>=1.8.1 <1.9.0');
      expect(M3x.dependencies['flutter_markdown'], '0.7.7+1');
      expect(
        M3x.dependencies['custom_git_pkg'],
        'git: https://github.com/Puzzaks/custom_git_pkg.git',
      );
      expect(M3x.config.dependencies.length, 6);
      expect(SettingsBentoHeader.defaultDependencies.length, 6);
      expect(
        SettingsBentoHeader.defaultDependencies['m3x'],
        'path: ../demo/packages/m3x',
      );
    });

    test('M3x.init populates SettingsBentoHeader defaultChangelogContent and defaultVersionDisplay', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final bundle = _TestAssetBundle({
        'pubspec.yaml': '''
name: test_app
version: 1.4.2+26111301
''',
        'CHANGELOG.md': '# Changelog\n\n## 1.4.2\n- Added feature.',
      });

      await M3x.init(bundle: bundle);

      expect(
        SettingsBentoHeader.defaultChangelogContent,
        '# Changelog\n\n## 1.4.2\n- Added feature.',
      );
      expect(
        SettingsBentoHeader.defaultVersionDisplay,
        'v1.4.2 • Nov 13, 2026 (rev 01)',
      );

      M3x.reset();
      expect(SettingsBentoHeader.defaultChangelogContent, isEmpty);
      expect(SettingsBentoHeader.defaultVersionDisplay, isEmpty);
    });
  });
}
