# Changelog

## 0.0.1

- Migrated Markdown rendering from discontinued `flutter_markdown` to `flutter_markdown_plus`.
- Initial standalone extraction of `m3x_gh` GitHub explorer from `demo`.
- Provides `M3xGitHub.openExplorer(context, ...)` one-line invocation with automatic repo derivation from `M3x.config`.
- Implements `M3xGitHubExplorerPage` and embeddable `M3xGitHubExplorerTab`.
- Implements `M3xGitHubService` (with `GitHubService` backwards-compatibility alias) supporting root doc discovery pills, issue comment caching, releases with asset download chips, and security advisories.
- Implements `preprocessGitHubMarkdown` for HTML tag sanitization and badge transformation.
