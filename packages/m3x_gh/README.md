# m3x_gh

Standalone Material 3 **GitHub Repository Explorer** for the [M3x](https://github.com/Puzzaks/m3x) Flutter ecosystem.

Embed a full-featured repository browser inside any Flutter app with one line — complete with root Markdown doc tabs, Issues & comments, Releases with downloadable asset chips, Security Advisories, and optional GitHub Personal Access Token (PAT) authentication for 5,000 req/hr rate limits.

## Features

- **One-Line Navigation**: `M3xGitHub.openExplorer(context)` automatically uses `M3x.config.githubOwner` / `M3x.config.githubRepo` (or explicit `owner` / `repo` overrides).
- **Full-Page & Embeddable Views**: Use `M3xGitHubExplorerPage` as a pushed route or `M3xGitHubExplorerTab` inside a tab/navigation shell.
- **`M3xGitHubService`**: Cached REST API client for root Markdown documentation discovery, issues + comments, releases + asset downloads, and security advisories.
- **Markdown Preprocessor (`preprocessGitHubMarkdown`)**: Sanitizes raw HTML tags and converts GitHub badge markup for clean rendering via `flutter_markdown_plus`.

## Usage

```dart
import 'package:m3x_gh/m3x_gh.dart';

// Push the explorer for a repository (or omit owner/repo if M3x.init() detected it)
M3xGitHub.openExplorer(
  context,
  owner: 'Puzzaks',
  repo: 'm3x',
);
```

## License

Released into the public domain under [The Unlicense](LICENSE).
