// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_gh/m3x_gh.dart';

void main() {
  group('Markdown Preprocessor', () {
    test('preprocessGitHubMarkdown strips comments and transforms HTML tags',
        () {
      const raw = '''
<!-- Banner comment -->
<div align="center">
  <h1>Project Title</h1>
  <p>Subtitle with <br> break and &amp; symbol</p>
  <a href="https://example.com"><img src="https://example.com/badge.svg" alt="Badge"></a>
</div>
''';

      final processed = preprocessGitHubMarkdown(raw);
      expect(processed, isNot(contains('<!-- Banner comment -->')));
      expect(processed, contains('# Project Title'));
      expect(processed, contains('Subtitle with'));
      expect(processed, contains('& symbol'));
      expect(
          processed,
          contains(
              '[![Badge](https://example.com/badge.svg)](https://example.com)'));
    });
  });

  group('GitHub Models', () {
    test('GitHubRepoDoc fromContentJson detects document types', () {
      final readmeDoc = GitHubRepoDoc.fromContentJson(
        {'name': 'README.md', 'path': 'README.md'},
        'Puzzaks',
        'demo',
      );
      expect(readmeDoc.title, equals('README'));
      expect(readmeDoc.icon, equals(Icons.menu_book_rounded));

      final licenseDoc = GitHubRepoDoc.fromContentJson(
        {'name': 'LICENSE', 'path': 'LICENSE'},
        'Puzzaks',
        'demo',
      );
      expect(licenseDoc.title, equals('License'));
      expect(licenseDoc.icon, equals(Icons.gavel_rounded));
    });

    test('GitHubIssue & GitHubRelease deserialization', () {
      final issue = GitHubIssue.fromJson({
        'number': 42,
        'title': 'Test Issue',
        'state': 'open',
        'user': {'login': 'octocat', 'avatar_url': 'https://avatars.com/octo'},
        'created_at': '2026-11-06T12:00:00Z',
        'comments': 3,
        'body': 'Issue body description',
        'html_url': 'https://github.com/Puzzaks/demo/issues/42',
        'labels': [
          {'name': 'bug', 'color': 'd73a4a'},
        ],
      });

      expect(issue.number, equals(42));
      expect(issue.author, equals('octocat'));
      expect(issue.labels.first.name, equals('bug'));

      final release = GitHubRelease.fromJson({
        'name': 'v1.0.0',
        'tag_name': 'v1.0.0',
        'published_at': '2026-11-06T10:00:00Z',
        'body': 'Release notes',
        'html_url': 'https://github.com/Puzzaks/demo/releases/tag/v1.0.0',
        'assets': [
          {
            'name': 'app.apk',
            'size': 15728640,
            'browser_download_url': 'https://download.com/app.apk',
            'download_count': 120,
          }
        ],
      });

      expect(release.tagName, equals('v1.0.0'));
      expect(release.assets.length, equals(1));
      expect(release.assets.first.name, equals('app.apk'));
    });
  });

  group('M3xGitHubService', () {
    test('setTargetRepository updates owner/repo and clears cache', () {
      final service = M3xGitHubService.instance;
      service.setTargetRepository('Puzzaks', 'PTK');

      expect(service.owner, equals('Puzzaks'));
      expect(service.repo, equals('PTK'));
      expect(service.rootDocs, isEmpty);
      expect(service.selectedDoc, isNull);
    });
  });

  group('M3xGitHub UI', () {
    testWidgets('M3xGitHubExplorerPage renders basic structure and tabs',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: M3xGitHubExplorerPage(
            initialOwner: 'Puzzaks',
            initialRepo: 'demo',
          ),
        ),
      );

      expect(find.text('GitHub Explorer'), findsOneWidget);
      expect(find.text('Docs'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Releases'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
    });
  });
}
