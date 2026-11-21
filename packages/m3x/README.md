# m3x

Master umbrella package for the **Material 3 eXtended (`m3x`)** Flutter ecosystem by [Puzzak](https://puzzak.page).

> *Material 3 eXtended (`m3x`) is an independent open-source project by Puzzak built on top of Flutter's Material 3 design system and is not affiliated with or endorsed by Google.*

Re-exports all modular `m3x_*` packages and provides `M3x.init()` to automatically derive app metadata, human-readable build dates, live dependency lists, Hive storage box names, native Android launcher icons, and GitHub repository coordinates directly from your bundled `pubspec.yaml` and `CHANGELOG.md`.

## Included Packages

- **[`m3x_ui`](https://github.com/Puzzaks/m3x/tree/main/packages/m3x_ui)** — Pure-Flutter Material 3 eXtended widgets, segmented `CardGroup`s, adaptive scaffolds, pickers, onboarding, telemetry, and `MotionBlurContainer`.
- **[`m3x_core`](https://github.com/Puzzaks/m3x/tree/main/packages/m3x_core)** — Deduplicating `AnalyticsService` logger and `M3xFormatters` (bytes, throughput, durations).
- **[`m3x_dict`](https://github.com/Puzzaks/m3x/tree/main/packages/m3x_dict)** — Standalone 3-tier JSON localization engine (`Dictionary`, `DictionaryStorage`).
- **[`m3x_chat`](https://github.com/Puzzaks/m3x/tree/main/packages/m3x_chat)** — AI/assistant chat bubbles, reasoning blocks (`ChatThoughtsBlock`), loading skeletons, and Markdown rendering.
- **[`m3x_gh`](https://github.com/Puzzaks/m3x/tree/main/packages/m3x_gh)** — Standalone GitHub repository explorer (Docs, Issues, Releases, Security Advisories, PAT auth).
- **[`m3x_mesh`](https://github.com/Puzzaks/m3x/tree/main/packages/m3x_mesh)** — Inter-App Agentic Mesh Protocol (Android `ContentProvider` IPC, headless Kotlin tool calling, MCP-compatible tool schemas).
- **[`m3x_storage`](https://github.com/Puzzaks/m3x/tree/main/packages/m3x_storage)** — Opinionated Hive persistence middleware with chat history caching and `DictionaryStorage` adapters.

## Quick Start

Bundle `pubspec.yaml` (and optionally `CHANGELOG.md`) in your app's `flutter.assets`, then initialize `M3x` once at startup:

```dart
import 'package:m3x/m3x.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await M3x.init();

  print(M3x.config.appName);
  print(M3x.config.versionDisplay); // e.g. 1.3.8 (Nov 15, 2026 (rev 01))
  print(M3x.config.storageBoxName); // e.g. my_app_storage
}
```

## License

Released into the public domain under [The Unlicense](LICENSE).
