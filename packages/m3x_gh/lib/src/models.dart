// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// Data model representing a documentation file in the repository root.
class GitHubRepoDoc {
  final String name;
  final String path;
  final String downloadUrl;
  final String title;
  final IconData icon;
  String? content;

  GitHubRepoDoc({
    required this.name,
    required this.path,
    required this.downloadUrl,
    required this.title,
    required this.icon,
    this.content,
  });

  factory GitHubRepoDoc.fromContentJson(
    Map<String, dynamic> json,
    String owner,
    String repo,
  ) {
    final name = json['name'] as String? ?? '';
    final path = json['path'] as String? ?? name;
    final downloadUrl = json['download_url'] as String? ??
        'https://raw.githubusercontent.com/$owner/$repo/HEAD/$path';

    final lower = name.toLowerCase();
    String title = name;
    IconData icon = Icons.description_outlined;

    if (lower == 'readme.md' || lower == 'readme') {
      title = 'README';
      icon = Icons.menu_book_rounded;
    } else if (lower.startsWith('license') || lower.startsWith('licence')) {
      title = 'License';
      icon = Icons.gavel_rounded;
    } else if (lower.contains('code_of_conduct') || lower.contains('conduct')) {
      title = 'Code of Conduct';
      icon = Icons.handshake_outlined;
    } else if (lower.contains('contributing')) {
      title = 'Contributing';
      icon = Icons.groups_rounded;
    } else if (lower.contains('security')) {
      title = 'Security';
      icon = Icons.shield_outlined;
    } else if (lower.contains('roadmap')) {
      title = 'Roadmap';
      icon = Icons.alt_route_rounded;
    } else if (lower.contains('changelog')) {
      title = 'Changelog';
      icon = Icons.history_rounded;
    } else if (lower.contains('privacy')) {
      title = 'Privacy';
      icon = Icons.privacy_tip_outlined;
    } else if (lower.endsWith('.md')) {
      title = name.substring(0, name.length - 3);
      if (title.isNotEmpty) {
        title = title[0].toUpperCase() +
            title.substring(1).replaceAll('_', ' ').replaceAll('-', ' ');
      }
    }

    return GitHubRepoDoc(
      name: name,
      path: path,
      downloadUrl: downloadUrl,
      title: title,
      icon: icon,
    );
  }
}

/// Data model representing a GitHub Issue Comment.
class GitHubIssueComment {
  final int id;
  final String author;
  final String authorAvatarUrl;
  final String createdAt;
  final String body;

  const GitHubIssueComment({
    required this.id,
    required this.author,
    required this.authorAvatarUrl,
    required this.createdAt,
    required this.body,
  });

  factory GitHubIssueComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return GitHubIssueComment(
      id: json['id'] as int? ?? 0,
      author: user['login'] as String? ?? 'ghost',
      authorAvatarUrl: user['avatar_url'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

/// Data model representing a GitHub Issue.
class GitHubIssue {
  final int number;
  final String title;
  final String state;
  final String author;
  final String authorAvatarUrl;
  final String createdAt;
  final int commentsCount;
  final String body;
  final String htmlUrl;
  final List<({String name, String colorHex})> labels;

  const GitHubIssue({
    required this.number,
    required this.title,
    required this.state,
    required this.author,
    required this.authorAvatarUrl,
    required this.createdAt,
    required this.commentsCount,
    required this.body,
    required this.htmlUrl,
    required this.labels,
  });

  factory GitHubIssue.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final rawLabels = json['labels'] as List<dynamic>? ?? [];
    final labels = rawLabels.map((l) {
      final map = l as Map<String, dynamic>;
      return (
        name: map['name']?.toString() ?? '',
        colorHex: map['color']?.toString() ?? '808080',
      );
    }).toList();

    return GitHubIssue(
      number: json['number'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      state: json['state'] as String? ?? 'open',
      author: user['login'] as String? ?? 'ghost',
      authorAvatarUrl: user['avatar_url'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      commentsCount: json['comments'] as int? ?? 0,
      body: json['body'] as String? ?? 'No description provided.',
      htmlUrl: json['html_url'] as String? ?? '',
      labels: labels,
    );
  }
}

/// Data model representing a GitHub Release.
class GitHubRelease {
  final String name;
  final String tagName;
  final String publishedAt;
  final String body;
  final String htmlUrl;
  final List<
          ({String name, int sizeBytes, String downloadUrl, int downloadCount})>
      assets;

  const GitHubRelease({
    required this.name,
    required this.tagName,
    required this.publishedAt,
    required this.body,
    required this.htmlUrl,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assets'] as List<dynamic>? ?? [];
    final assets = rawAssets.map((a) {
      final map = a as Map<String, dynamic>;
      return (
        name: map['name']?.toString() ?? '',
        sizeBytes: map['size'] as int? ?? 0,
        downloadUrl: map['browser_download_url']?.toString() ?? '',
        downloadCount: map['download_count'] as int? ?? 0,
      );
    }).toList();

    return GitHubRelease(
      name: json['name'] as String? ?? json['tag_name'] as String? ?? 'Release',
      tagName: json['tag_name'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      body: json['body'] as String? ?? 'No release notes provided.',
      htmlUrl: json['html_url'] as String? ?? '',
      assets: assets,
    );
  }
}
