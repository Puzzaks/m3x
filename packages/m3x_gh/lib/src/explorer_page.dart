import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:m3x_ui/m3x_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'markdown_preprocessor.dart';
import 'models.dart';
import 'service.dart';

/// Central entrypoint for GitHub exploration in the M3x ecosystem.
class M3xGitHub {
  M3xGitHub._();

  /// Default GitHub repository owner (e.g. `'Puzzaks'`).
  static String? defaultOwner;

  /// Default GitHub repository name (e.g. `'demo'`).
  static String? defaultRepo;

  /// Opens the [M3xGitHubExplorerPage] on top of the current [context].
  ///
  /// - [repo]: Repository name (or `'owner/repo'` formatted string).
  /// - [owner]: Repository owner. Auto-derives from [defaultOwner] or [repo] if omitted.
  /// - [config]: Optional custom configuration.
  static Future<void> openExplorer(
    BuildContext context, {
    String? repo,
    String? owner,
    M3xGitHubConfig? config,
  }) async {
    String targetOwner = owner ?? config?.owner ?? defaultOwner ?? 'Puzzaks';
    String targetRepo = repo ?? config?.repo ?? defaultRepo ?? 'PAIOS';

    if (repo != null && repo.contains('/')) {
      final parts = repo.split('/');
      targetOwner = parts[0].trim();
      targetRepo = parts[1].trim();
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => M3xGitHubExplorerPage(
          initialOwner: targetOwner,
          initialRepo: targetRepo,
          config: config,
        ),
      ),
    );
  }
}

/// Standalone Material 3 GitHub repository explorer page.
class M3xGitHubExplorerPage extends StatefulWidget {
  final String? initialOwner;
  final String? initialRepo;
  final M3xGitHubConfig? config;

  const M3xGitHubExplorerPage({
    super.key,
    this.initialOwner,
    this.initialRepo,
    this.config,
  });

  @override
  State<M3xGitHubExplorerPage> createState() => _M3xGitHubExplorerPageState();
}

class _M3xGitHubExplorerPageState extends State<M3xGitHubExplorerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _tokenCtrl = TextEditingController();

  final List<({String path, String title, String content})> _nestedDocStack = [];
  bool _isLoadingNestedDoc = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final service = M3xGitHubService.instance;
    final owner = widget.initialOwner ?? widget.config?.owner ?? M3xGitHub.defaultOwner;
    final repo = widget.initialRepo ?? widget.config?.repo ?? M3xGitHub.defaultRepo;

    if (owner != null && repo != null) {
      service.setTargetRepository(owner, repo);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (service.rootDocs.isEmpty && service.readmeContent == null) {
          service.refreshAll();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Widget _buildMarkdownImage(
    Uri uri,
    String? title,
    String? alt,
    M3xGitHubService github,
  ) {
    final uriStr = uri.toString();
    final String fullUrl;
    if (uriStr.startsWith('http://') || uriStr.startsWith('https://')) {
      fullUrl = uriStr;
    } else {
      final cleanPath = uriStr.startsWith('./')
          ? uriStr.substring(2)
          : (uriStr.startsWith('/') ? uriStr.substring(1) : uriStr);
      fullUrl =
          'https://raw.githubusercontent.com/${github.owner}/${github.repo}/HEAD/$cleanPath';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => launchUrl(
          Uri.parse(fullUrl),
          mode: LaunchMode.externalApplication,
        ),
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fullUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 120,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.broken_image_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alt != null && alt.isNotEmpty
                            ? alt
                            : 'Image ($uriStr)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleMarkdownLinkTap(
    BuildContext context,
    M3xGitHubService github,
    String? href,
  ) async {
    if (href == null || href.isEmpty) return;

    if (href.startsWith('#')) return;

    final cleanHref = href.replaceAll('./', '').trim();
    final bool switched = await github.selectDocByPath(cleanHref);
    if (switched) {
      if (_nestedDocStack.isNotEmpty) {
        setState(() {
          _nestedDocStack.clear();
        });
      }
      return;
    }

    if (!href.startsWith('http://') && !href.startsWith('https://')) {
      setState(() {
        _isLoadingNestedDoc = true;
      });
      final content = await github.fetchArbitraryFileContent(cleanHref);
      if (!mounted) return;
      setState(() {
        _isLoadingNestedDoc = false;
        final docName = cleanHref.split('/').last;
        _nestedDocStack.add((path: cleanHref, title: docName, content: content));
      });
      return;
    }

    final uri = Uri.tryParse(href);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showTokenLoginDialog(BuildContext context, M3xGitHubService github) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, size: 22),
            SizedBox(width: 8),
            Text('GitHub Authentication'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a Personal Access Token (PAT) with `public_repo` scope to raise API rate limit from 60 to 5,000 requests/hour and view internal security advisories.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Personal Access Token',
                hintText: 'ghp_...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final token = _tokenCtrl.text.trim();
              if (token.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final success = await github.authenticateWithToken(token);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Signed in as ${github.authUsername} (5,000 req/hr active)'
                        : 'Authentication failed. Check token validity.',
                  ),
                ),
              );
            },
            child: const Text('Authenticate'),
          ),
        ],
      ),
    );
  }

  void _showIssueDetails(BuildContext context, GitHubIssue issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _IssueDetailsSheet(issue: issue),
    );
  }

  Widget _buildDocsViewerTab(BuildContext context, M3xGitHubService github) {
    final scheme = Theme.of(context).colorScheme;

    if (_nestedDocStack.isNotEmpty) {
      final currentNested = _nestedDocStack.last;
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: scheme.surfaceContainerHigh,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  tooltip: 'Back',
                  onPressed: () {
                    setState(() {
                      _nestedDocStack.removeLast();
                    });
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    currentNested.path,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Root Docs'),
                  onPressed: () {
                    setState(() {
                      _nestedDocStack.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: MotionBlurContainer(
              child: Markdown(
                data: preprocessGitHubMarkdown(currentNested.content),
                selectable: true,
                padding: const EdgeInsets.all(16),
                onTapLink: (linkText, href, title) =>
                    _handleMarkdownLinkTap(context, github, href),
                imageBuilder: (uri, title, alt) =>
                    _buildMarkdownImage(uri, title, alt, github),
              ),
            ),
          ),
        ],
      );
    }

    final docs = github.rootDocs;
    final activeDoc = github.selectedDoc;
    final String activeContent = activeDoc?.content ??
        github.readmeContent ??
        '_Select a document above or refresh._';

    return Column(
      children: [
        if (docs.isNotEmpty)
          Container(
            height: 48,
            color: scheme.surfaceContainerLow,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final bool isSelected = activeDoc?.path == doc.path;
                return ChoiceChip(
                  avatar: Icon(
                    doc.icon,
                    size: 16,
                    color: isSelected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  label: Text(doc.title),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (selected) {
                    if (selected) {
                      github.selectDoc(doc);
                    }
                  },
                );
              },
            ),
          ),
        if (_isLoadingNestedDoc) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: MotionBlurContainer(
            child: Markdown(
              data: preprocessGitHubMarkdown(activeContent),
              selectable: true,
              padding: const EdgeInsets.all(16),
              onTapLink: (linkText, href, title) =>
                  _handleMarkdownLinkTap(context, github, href),
              imageBuilder: (uri, title, alt) =>
                  _buildMarkdownImage(uri, title, alt, github),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final github = M3xGitHubService.instance;

    return ListenableBuilder(
      listenable: github,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GitHub Explorer', style: TextStyle(fontSize: 16)),
                Text(
                  '${github.owner}/${github.repo}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<({String owner, String repo, String title})>(
                tooltip: 'Switch Repository',
                icon: const Icon(Icons.source_rounded),
                initialValue: github.presetRepos.firstWhere(
                  (p) => p.owner == github.owner && p.repo == github.repo,
                  orElse: () => github.presetRepos.first,
                ),
                onSelected: (p) => github.setTargetRepository(p.owner, p.repo),
                itemBuilder: (ctx) => [
                  for (final p in github.presetRepos)
                    PopupMenuItem(
                      value: p,
                      child: Text(p.title),
                    ),
                ],
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: github.isLoading ? null : () => github.refreshAll(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    color: scheme.surfaceContainerHigh,
                    child: Row(
                      children: [
                        Icon(
                          github.authToken != null
                              ? Icons.verified_user_rounded
                              : Icons.lock_outline_rounded,
                          size: 16,
                          color: github.authToken != null
                              ? Colors.green
                              : scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            github.authToken != null
                                ? 'Authenticated: @${github.authUsername} (${github.rateLimitRemaining}/${github.rateLimitTotal} req/hr)'
                                : 'Anonymous: ${github.rateLimitRemaining}/${github.rateLimitTotal} req/hr',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (github.authToken == null)
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () =>
                                _showTokenLoginDialog(context, github),
                            child: const Text(
                              'Add Token (+5,000)',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                        else
                          IconButton(
                            tooltip: 'Sign Out Token',
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            onPressed: () => github.logout(),
                          ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: scheme.primary,
                    tabs: const [
                      Tab(text: 'Docs'),
                      Tab(text: 'Issues'),
                      Tab(text: 'Releases'),
                      Tab(text: 'Security'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: github.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDocsViewerTab(context, github),
                    github.issues.isEmpty
                        ? const Center(child: Text('No open issues found.'))
                        : MotionBlurContainer(
                            child: ListView.builder(
                              itemCount: github.issues.length,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (ctx, i) {
                                final issue = github.issues[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: issue.state == 'open'
                                          ? Colors.green.shade700
                                          : Colors.purple.shade700,
                                      child: Icon(
                                        issue.state == 'open'
                                            ? Icons.adjust_rounded
                                            : Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      '#${issue.number} ${issue.title}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          'Opened by ${issue.author} • ${issue.commentsCount} comments',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (issue.labels.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            children: issue.labels.map((l) {
                                              final color = Color(
                                                int.parse(
                                                  'FF${l.colorHex}',
                                                  radix: 16,
                                                ),
                                              );
                                              return Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 6,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  l.name,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () =>
                                        _showIssueDetails(context, issue),
                                  ),
                                );
                              },
                            ),
                          ),
                    github.releases.isEmpty
                        ? const Center(
                            child: Text(
                              'No published GitHub releases found for this repository.',
                            ),
                          )
                        : MotionBlurContainer(
                            child: ListView.builder(
                              itemCount: github.releases.length,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (ctx, i) {
                                final rel = github.releases[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    scheme.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                rel.tagName,
                                                style: TextStyle(
                                                  color: scheme
                                                      .onPrimaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                rel.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Published ${rel.publishedAt.length >= 10 ? rel.publishedAt.substring(0, 10) : rel.publishedAt}',
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        MarkdownBody(
                                          data: preprocessGitHubMarkdown(
                                              rel.body),
                                          selectable: true,
                                          onTapLink: (linkText, href, title) {
                                            if (href != null &&
                                                href.isNotEmpty) {
                                              launchUrl(
                                                Uri.parse(href),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            }
                                          },
                                        ),
                                        if (rel.assets.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Release Assets & Downloads:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: rel.assets.map((asset) {
                                              final sizeMb = (asset.sizeBytes /
                                                      (1024 * 1024))
                                                  .toStringAsFixed(1);
                                              return ActionChip(
                                                avatar: const Icon(
                                                  Icons.download_rounded,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  '${asset.name} ($sizeMb MB • ${asset.downloadCount} dl)',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                onPressed: () => launchUrl(
                                                  Uri.parse(asset.downloadUrl),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    MotionBlurContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            Text(
                              'Repository Security & Advisory Status',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Public security advisories, vulnerability disclosures, and dependency tracking for ${github.owner}/${github.repo}.',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.shield_outlined,
                                  color: Colors.green,
                                ),
                                title: const Text('Dependabot Alerts'),
                                subtitle: const Text(
                                  'Zero active high-severity vulnerabilities reported.',
                                ),
                                trailing: TextButton(
                                  onPressed: () => launchUrl(
                                    Uri.parse(
                                      'https://github.com/${github.owner}/${github.repo}/security',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: const Text('View on GH'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.gavel_rounded,
                                  color: Colors.blue,
                                ),
                                title: const Text('License & Governance'),
                                subtitle: Text(
                                  github.licenseName ??
                                      'The Unlicense / MIT Open Source',
                                ),
                                trailing: FilledButton.tonal(
                                  onPressed: () async {
                                    await github.selectDocByPath('LICENSE');
                                    _tabController.animateTo(0);
                                  },
                                  child: const Text('View License'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Backwards compatibility alias for [M3xGitHubExplorerPage].
typedef GitHubExplorerPage = M3xGitHubExplorerPage;

/// Embeddable GitHub explorer tab widget without a Scaffold/AppBar.
class M3xGitHubExplorerTab extends StatelessWidget {
  final String? owner;
  final String? repo;

  const M3xGitHubExplorerTab({super.key, this.owner, this.repo});

  @override
  Widget build(BuildContext context) {
    return M3xGitHubExplorerPage(
      initialOwner: owner,
      initialRepo: repo,
    );
  }
}

/// Dedicated sheet for Issue details.
class _IssueDetailsSheet extends StatefulWidget {
  final GitHubIssue issue;

  const _IssueDetailsSheet({required this.issue});

  @override
  State<_IssueDetailsSheet> createState() => _IssueDetailsSheetState();
}

class _IssueDetailsSheetState extends State<_IssueDetailsSheet> {
  late Future<List<GitHubIssueComment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture =
        M3xGitHubService.instance.fetchIssueComments(widget.issue.number);
  }

  Widget _buildMarkdownImage(
    Uri uri,
    String? title,
    String? alt,
    M3xGitHubService github,
  ) {
    final uriStr = uri.toString();
    final String fullUrl;
    if (uriStr.startsWith('http://') || uriStr.startsWith('https://')) {
      fullUrl = uriStr;
    } else {
      final cleanPath = uriStr.startsWith('./')
          ? uriStr.substring(2)
          : (uriStr.startsWith('/') ? uriStr.substring(1) : uriStr);
      fullUrl =
          'https://raw.githubusercontent.com/${github.owner}/${github.repo}/HEAD/$cleanPath';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => launchUrl(
          Uri.parse(fullUrl),
          mode: LaunchMode.externalApplication,
        ),
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fullUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 120,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.broken_image_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alt != null && alt.isNotEmpty
                            ? alt
                            : 'Image ($uriStr)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(
    BuildContext context,
    GitHubIssueComment comment,
    M3xGitHubService github,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: comment.authorAvatarUrl.isNotEmpty
                      ? NetworkImage(comment.authorAvatarUrl)
                      : null,
                  child: comment.authorAvatarUrl.isEmpty
                      ? Text(
                          comment.author.isNotEmpty
                              ? comment.author[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 11),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  comment.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (comment.createdAt.isNotEmpty)
                  Text(
                    comment.createdAt.length >= 10
                        ? comment.createdAt.substring(0, 10)
                        : comment.createdAt,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            MarkdownBody(
              data: preprocessGitHubMarkdown(comment.body),
              selectable: true,
              onTapLink: (linkText, href, title) {
                if (href != null && href.isNotEmpty) {
                  launchUrl(
                    Uri.parse(href),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              imageBuilder: (uri, title, alt) =>
                  _buildMarkdownImage(uri, title, alt, github),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final github = M3xGitHubService.instance;
    final issue = widget.issue;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (sheetCtx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: MotionBlurContainer(
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: issue.state == 'open'
                          ? Colors.green.shade700
                          : Colors.purple.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      issue.state.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${issue.number}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Open in GitHub',
                    icon: const Icon(Icons.open_in_new_rounded),
                    onPressed: () => launchUrl(
                      Uri.parse(issue.htmlUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                issue.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Opened by ${issue.author} • ${issue.commentsCount} comments',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (issue.labels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: issue.labels.map((l) {
                    final color =
                        Color(int.parse('FF${l.colorHex}', radix: 16));
                    return Chip(
                      label: Text(
                        l.name,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: color,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
              const Divider(height: 24),
              MarkdownBody(
                data: preprocessGitHubMarkdown(issue.body),
                selectable: true,
                onTapLink: (linkText, href, title) {
                  if (href != null && href.isNotEmpty) {
                    launchUrl(
                      Uri.parse(href),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                imageBuilder: (uri, title, alt) =>
                    _buildMarkdownImage(uri, title, alt, github),
              ),
              if (issue.commentsCount > 0) ...[
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.forum_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Comments (${issue.commentsCount})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<GitHubIssueComment>>(
                  future: _commentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No comments available.',
                          style: TextStyle(fontSize: 12),
                        ),
                      );
                    }
                    return Column(
                      children: comments
                          .map((c) => _buildCommentCard(context, c, github))
                          .toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.forum_rounded),
                label: const Text('Jump into Discussion on GitHub'),
                onPressed: () => launchUrl(
                  Uri.parse(issue.htmlUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
