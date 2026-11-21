# Project Roadmap
  - [ ] Planned/ indev change
  - [x] Implemented change
  - `~version` Upstream version of this change
  - `version` Downstream version of this change

---
## Phase 1 `Consolidation & Playground` 7/8
 - [x] **Cross-Project Audit** `1.0.0`
    - Audited all 6 reference repositories (`PTK`, `the2k48`, `geminilocal`, `Website`, `ggscanus`, `binotool`) for UI evolution, page patterns, engine architecture, and latent bugs
 - [x] **Core UI Package (`puzzak_ui`)** `1.0.0`
    - Consolidated `elements.dart` (`Cards`, `CardGroup`, `ReorderableCardGroup`, `CardContents`, `Category`, `TextPart` / `text`) with 100% backwards-compatible signatures
    - Replaced physical screen-width math (`views.first.physicalSize`) with responsive `Expanded`, `Flexible`, and `LayoutBuilder` constraints
    - Generalized `Cards.cardGroup` for both single-column segmented lists and multi-column responsive grids (fixing the 3-card duplicate bug from `Website`)
 - [x] **UI Complications & Sameera Essentials** `1.1.0`
    - Extracted modular page & widget complications in `puzzak_ui`: `scaffolds.dart` (`SliverPageScaffold`, `AdaptiveNavScaffold`, `FloatingNavPill`, `EmptyStateView`, `PuzzakTheme`, `StartupCrossFadeShell`), `pickers.dart` (`OptionPickerBottomSheet`, `OptionPickerDialog`, `TextInputDialog`), `onboarding.dart` (`OnboardingWizard`, `ChoiceCard`, `ChecklistGroupCard`), `telemetry.dart` (`TelemetrySparklineCard`, `CircularGaugeCard`, `SyncStatusCard`, `ThemeModeSwitchCard`, `LogViewerList`), `motion_blur.dart` (`MotionBlurScrollView`), and `monetization.dart` (`SubscriptionTierCard`, `AdPlaceholderCard`)
    - Extracted chat-specific widgets into standalone sub-package `puzzak_ui_chat` (`ChatBubbleList`, `ChatMessageBubble`, `ChatTextPart`) so non-chat apps don't pull in `flutter_markdown`
 - [x] **Standalone Dictionary & Core (`puzzak_dict`, `puzzak_core`)** `1.0.0`
    - Decoupled 3-tier JSON translator (`Dictionary`) into `puzzak_dict` with pluggable storage (`InMemoryDictionaryStorage`, `CallbackDictionaryStorage`), HTTP timeout protection, and combined system-locale reset/fallback fixes
    - Extracted consecutive-deduplicating `AnalyticsService` logger and unified byte/speed/duration formatters (`PuzzakFormatters`) into `puzzak_core`
 - [x] **Interactive Showcase App** `1.1.0`
    - Built live Playground app in root `lib/` with simulated viewport width slider, dynamic system wallpaper color (Pixel 9 Pro) & preset seed switcher, interactive `CardContents` laboratory, telemetry & chat complications showcase, page templates launcher, and `Dictionary`/`AnalyticsService` inspector
    - Restructured into real production app tabs: **Dashboard** (Thinkpad.dev screen, server uptime, smooth sparklines, floating capsule nav, reorderable servers), **Elements**, **Settings** (appearance, dynamic color, blur, haptics, localization, pro membership, sync), and **Complications**
 - [x] **CI/CD & Android Studio Release Pipeline** `1.1.0`
    - Automated cross-platform build scripts (`scripts/build_releases.ps1`), Android Studio 1-click execution configs (`.run/Build and Release All.run.xml`, `.run/Test and Analyze.run.xml`), and GitHub Actions release workflow (`.github/workflows/ci_cd.yml`)
 - [x] **AI Agent Rules & Skills** `1.0.0`
    - Authored workspace `GEMINI.md`, `.agents/docs/` living reference library (`UI_PALETTE_CATALOG.md`, `ARCHITECTURE_AND_QUIRKS.md`, `CROSS_PROJECT_ANALYSIS.md`), and workspace/global `puzzak-dev-system` Antigravity skill
 - [ ] **Golden & Widget Test Suite**
    - Automated visual regression and layout stress tests for every `CardContents` variant across narrow (`280px`), mobile (`400px`), tablet (`720px`), and desktop (`1200px`) widths
 - [ ] **Pub.dev & Git Subpackage Publishing Readiness**
    - Finalizing package metadata, licenses, changelogs, and standalone Git repository / tag exports for `puzzak_ui`, `puzzak_ui_chat`, `puzzak_dict`, and `puzzak_core`


## Phase 2 `Downstream Migration` 0/6
 - [ ] **Migrate `PTK` (Puzzak's ToolKit)**
    - Switch `lib/pages/support/elements.dart` and `translator.dart` to `puzzak_ui`, `puzzak_dict`, and `puzzak_core`
    - Fix hardcoded `index: 0` in `ReorderableDragStartListener` (`servers.dart:200`), unlocalized `.label` keys (`server_editor.dart:595-615`), raw status enum strings (`status_page_detail.dart`, `status_page_lists.dart`), and `_bgMonitor` tri-state toggle logic (`server_editor.dart:534-550`)
 - [ ] **Migrate `geminilocal` (PAIOS)**
    - Switch `elements.dart` and chat bubbles to `puzzak_ui` + `puzzak_ui_chat`, and `translator.dart` to `puzzak_dict` (with `'paios_storage'` box adapter)
    - Fix missing `AIEngine.cards` field (`main.dart:89`), nested `MaterialApp` + legacy grey light theme in `intro.dart:108-136`, and inverted `"Other chats"` header check in `chats.dart:248`
 - [ ] **Migrate `the2k48` & `quickstart/starter_project`**
    - Replace local `elements.dart` and `translator.dart` with `puzzak_ui`, `puzzak_dict`, and `puzzak_core`, removing dead `flutter_markdown` / `chatlog` dependencies
    - Wire `engine.darkModeOverride` into `main.dart`'s `themeMode` and update `quickstart` blueprint to reference the consolidated packages
 - [ ] **Migrate `Website` (`new_website`)**
    - Replace `widgets/elements.dart`, `responsive_scaffold.dart`, and `dashboard_cards.dart` telemetry widgets with `puzzak_ui`
    - Fix invisible white-on-white Markdown text in Light Mode (`story_detail_screen.dart:143-204`) and stale `backend.context` usage in `RusnyaCard` (`dashboard_cards.dart:646-727`)
 - [ ] **Migrate `ggscanus`**
    - Replace inline `cardContents` (`main.dart:18-353`) and local `cardGroup`/`settingsDivider` closures with `puzzak_ui` and `puzzak_core`
    - Fix `splitText` `RangeError` crash when role strings > 40 chars have fewer than 3 spaces (`main.dart:620-632`, `search.dart:269-281`) and fix typo in `scan.dart:541`
 - [ ] **Migrate `binotool`**
    - Modernize inline dashboard, sync status cards, and proto-translator using `puzzak_ui` (`SyncStatusCard`, `CardGroup`), `puzzak_dict`, and `puzzak_core`
    - Fix $O(N^2)$ `.reversed.toList()` allocation inside `cdr_filtered` `.map()` loop (`main.dart:820-821`)


## Phase 3 `Ecosystem Expansion` 1/4
 - [x] **Desktop & Web Adaptive Split-Pane Templates** `1.4.0`
    - Added `M3xWindowSizeClass`, `M3xAdaptiveMasterDetail`, `M3xAdaptiveSplitHero`, `M3xAdaptiveContentFrame`, auto-adaptive `SliverPageScaffold` (`maxContentWidth`, `embedded`, `adaptiveSidebar`), smoothly animated 3-tier `AdaptiveNavScaffold`, and `CardContents` animated `selected` state in `m3x_ui` `0.1.0+26112001`
 - [ ] **Chart & Gauge Extensions (`puzzak_ui_charts`)**
    - Optional multi-series interactive time-series charts and server status timeline bars
 - [ ] **Interactive Theme & Token Exporter**
    - Export customized seed colors, surface overrides, and card radius presets directly from the Playground app as ready-to-paste `PuzzakTheme` code
 - [ ] **Automated Translation Validator CLI**
    - Command-line script in `puzzak_dict` to diff `en.json` against all other locale files across repositories and flag missing or stale translation keys before release
