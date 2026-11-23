# m3x

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](https://unlicense.org)
[![Publisher: puzzak.page](https://img.shields.io/badge/publisher-puzzak.page-teal.svg)](https://puzzak.page)
[![CI](https://github.com/Puzzaks/m3x/actions/workflows/ci.yml/badge.svg)](https://github.com/Puzzaks/m3x/actions/workflows/ci.yml)

Modular **Material 3 eXtended (`m3x`)** Flutter packages & Android **M3X Mesh IPC** ecosystem by [Puzzak](https://puzzak.page).

> *Material 3 eXtended (`m3x`) is an independent open-source project by Puzzak built on top of Flutter's Material 3 design system and is not affiliated with or endorsed by Google.*

Every package in this monorepo is designed to stay focused, dependency-light, and composable — use only the leaf packages you need, or import the `m3x` umbrella package for automatic `pubspec.yaml` metadata derivation and full ecosystem wiring.

---

## Packages

| Package | Version | Pub Status | Description |
| :--- | :---: | :---: | :--- |
| **[`m3x_ui`](packages/m3x_ui)** | `0.1.4` | Leaf (0 third-party deps) | Pure-Flutter Material 3 eXtended widgets: segmented `CardGroup`, `CardContents`, `SettingsBentoHeader`, adaptive scaffolds (`SliverPageScaffold`, `AdaptiveNavScaffold`, `M3xAdaptiveMasterDetail`, `M3xAdaptiveSplitHero`, `M3xAdaptiveContentFrame`), pickers, onboarding, telemetry cards, and `MotionBlurContainer`. |
| **[`m3x_core`](packages/m3x_core)** | `0.0.3` | Leaf (0 third-party deps) | Shared core utilities: consecutive-deduplicating `AnalyticsService` logger and `M3xFormatters` (bytes, throughput, durations). |
| **[`m3x_dict`](packages/m3x_dict)** | `0.0.4` | Leaf (`http` only) | Standalone 3-tier JSON localization engine (`Dictionary`, `DictionaryStorage`) with bundled assets, local cache overlay, and non-blocking SWR remote HTTP refresh. |
| **[`m3x_chat`](packages/m3x_chat)** | `0.2.5` | Complication (`m3x_ui`) | AI/assistant chat UI: `ChatMessage`, `ChatBubbleList`, `ChatMessageBubble`, `ChatAnimatedSkeleton`, `ChatThoughtsBlock` with live-stream auto-scroll, and `flutter_markdown_plus` rendering. |
| **[`m3x_gh`](packages/m3x_gh)** | `0.0.3` | Complication (`m3x_ui`, `m3x_core`) | Standalone GitHub Repository Explorer (root Markdown doc tabs, Issues & comments, Releases with asset downloads, Security Advisories, and PAT auth). |
| **[`m3x_mesh`](packages/m3x_mesh)** | `1.1.8` | Android Plugin (`m3x_core`) | Inter-App Agentic Mesh Protocol over Android `ContentProvider` IPC, headless native Kotlin tool calling, MCP-compatible tool schemas, and Gemma/JSON tool-call parsing. |
| **[`m3x_storage`](packages/m3x_storage)** | `0.0.3` | Middleware (`m3x_core`, `m3x_dict`) | Opinionated Hive persistence middleware with type-safe primitive accessors, chat history helpers, and `asDictionaryStorage()` adapter. |
| **[`m3x`](packages/m3x)** | `0.0.7` | Umbrella | Re-exports all 7 packages and provides `M3x.init()` to auto-derive app identity, version dates, dependencies, native launcher icons, storage box names, and GitHub coordinates from `pubspec.yaml`. |

---

## Installation

### Leaf packages (via pub.dev or Git)

```yaml
dependencies:
  m3x_ui: ^0.1.1
  m3x_core: ^0.0.1
  m3x_dict: ^0.0.2
```

### From Git (all packages, including umbrella & complications)

```yaml
dependencies:
  m3x:
    git:
      url: https://github.com/Puzzaks/m3x.git
      path: packages/m3x
```

---

## Interactive Playground (`example/`)

An interactive Material 3 eXtended showcase and stress-test app lives in [`example/`](example/):

```bash
cd example
flutter pub get
flutter run
```

---

## Automated Publishing (`pub.dev` OIDC)

This repository includes [`.github/workflows/publish.yml`](.github/workflows/publish.yml) for keyless OIDC publishing to `pub.dev` on tag push (`<package>-v<version>`, e.g. `m3x_ui-v0.1.2`, `m3x_mesh-v1.1.7`, `m3x-v0.0.6`).

To enable automated publishing for each package on `pub.dev`, open its **Admin** tab and configure **Automated publishing → Enable publishing from GitHub Actions**:

- **Repository**: `Puzzaks/m3x`
- **Tag pattern**: `<package>-v{{version}}` (e.g. `m3x_chat-v{{version}}`, `m3x_gh-v{{version}}`, `m3x_mesh-v{{version}}`, `m3x_storage-v{{version}}`)

---

## License

All packages and examples in this repository are released into the public domain under **[The Unlicense](LICENSE)**.
