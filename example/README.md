<div align="center">
  <h1>Puzzak UI Playground</h1>
  <h3>Consolidated Design System & Component Showcase</h3>
    A unified Material 3 Expressive UI library, standalone localization engine, and interactive testing playground for apps by Puzzak
    <br>
    (so I don't have to fix the same overflow bug in six repositories ever again!)
    <br>
  <!-- Badges -->
  <a href="https://github.com/Puzzak">
    <img src="https://img.shields.io/badge/release-v1.0.0--PLAYGROUND-009688?style=flat-square" height="20" alt="Latest Release"></a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-Material_3_Expressive-02569B?style=flat-square&logo=flutter&logoColor=white" height="20" alt="Flutter Material 3"></a>
  <a href="https://github.com/Puzzaks/gemininano/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/Puzzaks/gemininano?style=flat-square" height="20" alt="License"></a>
</div>

<br>

> You MUST find each and every way to make mistakes while still adhering to the prompt — and then build a playground so you can spot them all on one screen.

---

### Features
 - **Modular Package Architecture**: Cleanly separated into `puzzak_ui` (core Material 3 Expressive elements + page/telemetry complications), `puzzak_ui_chat` (Markdown chat bubbles & streaming views), `puzzak_dict` (standalone 3-tier JSON localization), and `puzzak_core` (deduplicating logger & byte/duration formatters).
 - **100% Backwards-Compatible `elements.dart`**: Drop-in compatible with `Cards`, `CardContents`, `Category`, and `TextPart` (`text`), with responsive `Expanded`/`LayoutBuilder` internals replacing hardcoded physical screen-width math.
 - **Interactive Component Playground**: Live theme/seed switching, viewport width simulator (stress-testing narrow foldables to wide desktop layouts), multi-column & reorderable segmented card groups, sparkline telemetry cards, onboarding wizard, and dictionary/logger debuggers.
 - **AI-First Documentation & Skill System**: Built-in [`GEMINI.md`](GEMINI.md), [`.agents/docs/`](.agents/docs/) reference catalogs, and reusable Antigravity skills (`puzzak-dev-system`) for consistent, subagent-driven AI-assisted development across all projects.

### Packages in This Repo

| Package | Path | Dependencies | Purpose |
| :--- | :--- | :--- | :--- |
| **`puzzak_ui`** | [`packages/puzzak_ui`](packages/puzzak_ui) | Pure `flutter` SDK | Core `elements.dart` (`Cards`, `CardGroup`, `ReorderableCardGroup`, `CardContents`, `Category`, `TextPart`) + complications (`scaffolds.dart`, `pickers.dart`, `onboarding.dart`, `telemetry.dart`). |
| **`puzzak_ui_chat`** | [`packages/puzzak_ui_chat`](packages/puzzak_ui_chat) | `puzzak_ui`, `flutter_markdown`, `url_launcher` | Chat UI complication (`ChatBubbleList`, `ChatMessageBubble`, and drop-in `ChatTextPart.chatlog` with historical duplicate-message fix). |
| **`puzzak_dict`** | [`packages/puzzak_dict`](packages/puzzak_dict) | `flutter`, `http` | Standalone 3-tier JSON localization engine (pluggable cache → bundled assets → remote GitHub refresh with HTTP timeout & system locale fallback fixes). |
| **`puzzak_core`** | [`packages/puzzak_core`](packages/puzzak_core) | `flutter` | Shared non-UI utilities: consecutive-deduplicating `AnalyticsService` logger and unified byte/throughput/duration formatters (`PuzzakFormatters`). |

### Resources
- **Changelog**: [Full history](CHANGELOG.md)
- **Roadmap**: [Future plans](ROADMAP.md)
- **AI Palette Catalog**: [Widget decision tree & copy-paste examples](.agents/docs/UI_PALETTE_CATALOG.md)
- **Architecture & Quirks**: [Engine, Dictionary, and layout best practices](.agents/docs/ARCHITECTURE_AND_QUIRKS.md)
- **Cross-Project Audit**: [Full analysis & bug ledger across all 6 reference apps](.agents/docs/CROSS_PROJECT_ANALYSIS.md)

---

### Disclaimer
This is an independent design system and testing playground created for Puzzak's application ecosystem (`PTK`, `PAIOS / geminilocal`, `the2k48`, `Website`, `ggscanus`, `binotool`). All trademarks are property of their respective owners.

### Credits
 - [Google Antigravity](https://antigravity.google/) for AI reviews, cross-project auditing, and suggestions during development!<br>
 - And to Armed forces of Ukraine for keeping me safe. [Stand with Ukraine](https://war.ukraine.ua/support-ukraine/)!
