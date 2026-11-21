## Update 1.4.0 `ADAPTIVE MATERIAL 3 LAYOUT PRIMITIVES & AUTO-ADAPTIVE SCAFFOLDS`
#### Changes
- **Adaptive Layout Primitives (`packages/m3x_ui` `0.1.0+26112001`)**:
  - Added `M3xWindowSizeClass` (`compact < 680dp`, `medium 680..960dp`, `expanded >= 960dp`) with `fromWidth(...)` and convenience getters (`isCompact`, `isSplit`, `isExpanded`).
  - Added `M3xAdaptiveMasterDetail` with zero-Navigator-duplication live resizing (`400px ↔ 1200px ↔ 400px`), `PopScope` compact back navigation, 60fps mouse-draggable desktop vertical splitter with hover pill indicator (double-tap to reset), smooth sidebar collapse to `0` width (`masterCollapsed`) via `OverflowBox`, rounded Material 3 detail container (`surfaceContainerLowest`, `24px` radius), `AnimatedSwitcher` detail transitions, and `emptyDetailBuilder`.
  - Added `M3xAdaptiveSplitHero` smoothly adapting welcome/onboarding layouts between a centered scrollable column (`maxWidth: 580`) below `760dp` and a 42%/58% 2-column side-by-side split (`maxWidth: 1080`) at/above `760dp`.
  - Added `M3xAdaptiveContentFrame` for animated responsive width clamping (`maxWidth: 880`) and interpolated horizontal padding on non-sliver pages (chat columns, composers, forms).
- **Auto-Adaptive Scaffolds & Selected Card Rows (`packages/m3x_ui`)**:
  - Upgraded `SliverPageScaffold` with backwards-compatible adaptive defaults (`maxContentWidth = 880.0`, `adaptivePadding = true`, `embedded = false` split-pane styling, and optional animated `adaptiveSidebar` at `sidebarBreakpoint = 840.0`).
  - Upgraded `AdaptiveNavScaffold` to a single unified `Scaffold` preserving body state across smoothly animated 3-tier transitions (`< 680dp` bottom `NavigationBar` ↔ `680..960dp` compact `NavigationRail` ↔ `>= 960dp` extended `NavigationRail`).
  - Added optional `bool selected = false` parameter to `CardContents.tap`, `CardContents.doubleTap`, and `CardContents.tapIcon` with smooth `AnimatedContainer` (`secondaryContainer` / `onSecondaryContainer`) highlighting and full ink ripple preservation.
- **Interactive Adaptive Layouts Lab & Widget Tests (`lib/pages/adaptive_layouts_demo.dart`, `packages/m3x_ui/test/adaptive_master_detail_test.dart`)**:
  - Added interactive **Adaptive Layouts Lab** in `ComplicationsTab` with live width simulator slider, `M3xWindowSizeClass` badge, sidebar collapse toggle, `M3xAdaptiveMasterDetail` / `M3xAdaptiveSplitHero` previews, and full-screen adaptive launchers.
  - Added comprehensive widget test suite covering compact/split transitions, live resize, `masterCollapsed`, `M3xAdaptiveSplitHero`, `CardContents` selected highlights, `M3xAdaptiveContentFrame`, `SliverPageScaffold`, and 3-tier `AdaptiveNavScaffold`.
- Bumped `m3x_ui` to `0.1.0+26112001`.

## Update 1.3.8 `STANDARDIZED M3X_CHAT SCHEMA, SKELETON & THOUGHTS`
#### Changes
- **Standardized `ChatMessage` Schema & Serialization (`packages/m3x_chat` `0.2.0+26111501`)**:
  - Added `author` (`displayAuthor`), `thoughts`, `isLoading`, `loadingLabel`, `isThinkingStreaming`, `avatarBytes`, `avatarText`, `avatarIcon`, `avatarBackgroundColor`, `copyWith(...)`, and `toJson()` while keeping 100% backwards compatibility on `fromLegacyMap(...)` (parsing `'time'` epoch ms or ISO-8601 strings, `'thoughts'` / `'thoughtProcess'`, `'author'`, `'isLoading'`, and `'loadingLabel'`) and `toLegacyMap()`.
- **Pure-Flutter Animated Loading Skeleton (`ChatAnimatedSkeleton`)**:
  - Added `ChatAnimatedSkeleton` with Material 3 shimmer sweep and optional `loadingLabel`, wrapped in `AnimatedSize` + `AnimatedSwitcher` (`SizeTransition` + `FadeTransition`) inside `ChatMessageBubble` so empty loading states and streaming continuations animate smoothly in and out.
- **Collapsible Reasoning Sub-Card (`ChatThoughtsBlock`)**:
  - Added `ChatThoughtsBlock` with pulsing `Icons.psychology_alt_rounded` header while `isThinkingStreaming` is active, auto-collapse when response text starts, manual toggle override, and bounded `220px` scrollable `SelectableText`.
- **Tap-to-Reveal Metadata, Avatars & Custom Body Slot (`ChatMessageBubble`, `ChatBubbleList`, `ChatTextPart`)**:
  - Added tap-to-reveal animated `author • timestamp` pill below bubbles, optional `showAvatar` (`CircleAvatar` badge, defaulting to `false`), `customContent`, `thoughtsTrailing`, localized labels, and `markdownStyleSheet`.
- **Interactive Playground Showcase (`lib/engine.dart`, `lib/pages/complications_tab.dart`)**:
  - Added live **Show Chat Avatars** toggle, pre-populated `thoughts` & `author` metadata, and upgraded `simulateAiStreamResponse` to demonstrate skeleton warm-up → streaming thoughts → Markdown + forward skeleton → smooth completion.
- Bumped `m3x_chat` to `0.2.0+26111501` and `demo` to `1.3.8+26111501`.

## Update 1.3.7 `MESH TOOL DESCRIPTION GUARDRAILS`
#### Changes
- Tightened `demo_get_environment` tool description in both `assets/mesh_tools.json` and `lib/engine.dart` (`_initMesh()`) to restrict invocations to explicit Demo UI Playground app queries and prevent false-positive calls on images, general questions, or unrelated follow-ups.
- Bumped `demo` to `1.3.7+26111401`.

## Update 1.3.6 `STANDARDIZED BENTO CHANGELOG MODAL`
#### Changes
- **Zero-Dependency Changelog Modal (`packages/m3x_ui` `0.0.7+26111301`)**:
  - Added `SettingsBentoHeader.defaultChangelogContent`, `SettingsBentoHeader.defaultVersionDisplay`, and `SettingsBentoHeader.showChangelogDialog(...)` in `packages/m3x_ui/lib/bento.dart` with pure Flutter Material 3 Markdown rendering (headings, nested bullets, numbered lists, horizontal rules, `**bold**`, `` `inline code` ``, and `SelectionArea` support) and automatic `onVersionTap` fallback when `defaultChangelogContent` is populated.
  - Updated `lib/pages/settings_tab.dart` so `_showChangelogDialog` delegates directly to `SettingsBentoHeader.showChangelogDialog(...)`.
- Bumped `demo` to `1.3.6+26111303` and `m3x_ui` to `0.0.7+26111301`.

## Update 1.3.5 `COLD-START MESH TOOL MANIFEST`
#### Changes
- Added bundled `assets/mesh_tools.json` declaring `demo_get_environment` and `demo_get_components` (`app: "demo"`, `packageName: "page.puzzak.demo"`) and registered it in `pubspec.yaml` so `M3xMeshContentProvider.query_tools` returns Demo's tool schemas before first app launch.
- Bumped `demo` to `1.3.5+26111302`.

## Update 1.3.4 `HEADLESS M3X MESH HOST & RELIABILITY HARDENING`
#### Changes
- **Decentralized Mesh Cold-Start & Tool Parser (`packages/m3x_mesh` `1.1.2+26111301`)**:
  - Updated Demo engine initialization (`lib/engine.dart`) to register mesh tools via `meshClient.startListening()`, added `startHeadlessForMesh()`, exported `@pragma('vm:entry-point') m3xMeshMain()` in `lib/main.dart`, and configured `com.puzzak.m3x.mesh.HEADLESS_ENTRYPOINT` in `AndroidManifest.xml` so Demo can handle cold-start inter-app mesh tool invocations seamlessly.
- Bumped `demo` to `1.3.4+26111301`.

## Update 1.3.0 `MULTIMODAL VISION CHAT BUBBLES, SYNTHETIC 2048 BOARD & ASSISTANT BUBBLE LAB`
#### Changes
- **Multimodal Image Bubble Support (`packages/m3x_chat`)**:
  - Added optional `imagePath` (`String?`) and `imageBytes` (`Uint8List?`) to `ChatMessage` and `ChatMessageBubble` (with automatic extraction from legacy conversation maps in `ChatBubbleList` / `ChatTextPart.chatlog`).
  - Renders a rounded Material 3 image thumbnail (`ClipRRect` with `BorderRadius.circular(12)`, max height `200px`, `BoxFit.cover`) above the message text inside user and AI bubbles.
  - Added interactive tap-to-zoom full-screen `Dialog.fullscreen` + `InteractiveViewer` modal (`ChatMessageBubble.showFullScreenImage`) with a close button for inspecting image details.
- **Multimodal Vision & Assistant Bubble Lab (`lib/pages/agentic_mesh_lab.dart`, `lib/engine.dart`)**:
  - Added in-memory synthetic 512×512 PNG 2048 Board & System Telemetry generator using `dart:ui` `PictureRecorder` and `Canvas` (tiles `2048`, `1024`, `512`, `256` with score and NPU metrics—zero external assets required).
  - Added **"📸 One-Shot Vision Inference (`query_local_ai` + Image)"** action sending the base64-encoded 512×512 PNG board over `M3xMeshClient` to PAIOS Gemini Nano Vision.
  - Added **"💬 Summon PAIOS Assistant Bubble (`openAssistantBubble`)"** action summoning PAIOS's interactive half-screen floating assistant sheet directly over Demo with pre-populated board image and context.
  - Added live `enableMesh` (`_meshClient.enabled`) and `downsample` (`768px Fast` vs `Full Res`) toggles in the Agentic Mesh Lab.
- Bumped `demo` to `1.3.0+26110901` and `m3x_chat` to `0.1.0+26110901`.

## Update 1.2.13 `DECENTRALIZED AGENTIC MESH DISCOVERY & DEMO TOOL HOSTING`
#### Changes
- **Decentralized Inter-App Mesh Discovery Protocol (`packages/m3x_mesh`)**:
  - Added `<intent-filter><action android:name="com.puzzak.m3x.mesh.ACTION_MESH_NODE" /></intent-filter>` to `.M3xMeshContentProvider`.
  - Added `<queries><intent><action android:name="com.puzzak.m3x.mesh.ACTION_MESH_NODE" /></intent></queries>` to library manifest, automatically merging into all apps.
  - Implemented dynamic provider query in `M3xMeshPlugin.kt` via `pm.queryIntentContentProviders(Intent("com.puzzak.m3x.mesh.ACTION_MESH_NODE"), 0)`.
  - Added `meshClient.discoverInstalledTools()` to dynamically query all installed mesh apps with 2-second timeouts and zero hardcoded package names.
- **Demo Inter-App Tool Provider Integration (`demo/lib/engine.dart`)**:
  - Integrated `M3xMeshClient` into `PlaygroundEngine.start()` at application boot.
  - Declared and registered local tools:
    - `demo_get_environment`: Returns UI playground theme, version, active platform state, and motion/haptics configuration.
    - `demo_get_components`: Returns structured catalog of registered M3x UI components across 9 categories.
  - Added startup sync via `meshClient.syncDeclaredTools()` to expose declared schemas over Android ContentProvider `content://page.puzzak.demo.mesh`.
  - Linked `AgenticMeshLabSection` directly to `playgroundEngine.meshClient` with `demo_get_components` in the available tools inspector.

## Update 1.2.11 `NATIVE APP LAUNCHER ICON EXTRACTION & AUTOMATIC BENTO HEADER DISPLAY`
#### Changes
- **Native App Launcher Icon Extraction (`packages/m3x_mesh`, `M3xMeshPlugin.kt`)**:
  - Added native Android method `"getAppIcon"` to `M3xMeshPlugin` over platform channel `com.puzzak.m3x_mesh`.
  - Automatically queries `packageManager.getApplicationIcon(packageName)`, extracts bitmap or draws Adaptive/Vector drawables onto an ARGB_8888 Canvas, and compresses to PNG bytes.
- **M3x Central Launcher Icon Pipeline (`packages/m3x`, `M3x.init()`)**:
  - Added `M3x.appIconBytes` static cache and getter/setter.
  - Automatically invokes `"getAppIcon"` during `M3x.init()` with safe fallback to `null` on unsupported platforms and unit test runners.
  - Synchronizes seamlessly with `SettingsBentoHeader.defaultIconBytes`.
- **Automatic & Declarative Bento Header Launcher Icon (`packages/m3x_ui`, `bento.dart`)**:
  - Updated `SettingsBentoHeader` with optional `iconWidget`, `iconBytes`, and `iconAsset` parameters.
  - Automatically falls back to native launcher icon PNG bytes (`iconBytes ?? SettingsBentoHeader.defaultIconBytes`) rendered via `ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(..., width: 32, height: 32))` inside the top header card.
  - Fully backward compatible: falls back cleanly to Material `Icon(icon, ...)` when no icon bytes or assets are available.
- Bumped `m3x_mesh` to `0.1.5+26110707`, `m3x` to `0.0.2+26110702`, and `m3x_ui` to `0.0.4+26110702`.

## Update 1.2.10 `REAL ANDROID CONTENTPROVIDER MESH PLUGIN, BIDIRECTIONAL IPC & AGENTIC MESH LAB`
#### Changes
- **Real Android ContentProvider IPC Mesh Plugin (`packages/m3x_mesh`)**:
  - Transformed `m3x_mesh` into a real Flutter Android plugin with native `M3xMeshContentProvider` and `M3xMeshPlugin`.
  - Registered ContentProvider on `${applicationId}.mesh` (`page.puzzak.demo.mesh` and `page.puzzak.paios.mesh`) supporting `call_tool` and `query_tools`.
  - Implemented bidirectional IPC bridging between native Binder threads and Flutter's Main Thread via MethodChannel `com.puzzak.m3x_mesh` (`onIncomingToolCall`, `callContentProvider`, `queryMeshTools`, `listMeshApps`, `setDeclaredTools`).
  - Added comprehensive native (`android.util.Log.d("M3xMesh", ...)`) and Dart (`debugPrint('[M3xMesh] ...')`) request/response telemetry logs with latency benchmarking.
  - Added Android 11+ package visibility `<queries>` across `demo` and `geminilocal` manifests for seamless inter-app querying.
- **Declarative Settings Bento Header (`SettingsBentoHeader`)** (`packages/m3x_ui/lib/bento.dart`, `packages/m3x_ui/lib/elements.dart`):
  - Created standalone 3-card Material 3 Expressive bento header widget replacing manual 60-line boilerplate.
  - Features top wide app header card with customizable icon, dynamic title, and subtitle, plus bottom-left Version card and bottom-right Connected Modules card with clean interactive tap actions.
  - Integrated into `SettingsTab` with live bindings to `engine.appDescription`, `engine.appVersionDisplay`, and `engine.installedPackages.length`.
- **Interactive Inter-App Agentic Mesh Lab** (`lib/pages/agentic_mesh_lab.dart`, `lib/pages/complications_tab.dart`):
  - Added live explorer and execution playground for M3x Mesh agentic tools (`the2k48_get_board`, `ptk_get_incidents`, `ptk_ping_host`, `query_local_ai`, `demo_get_environment`, `get_playback_status`).
  - Added Live Android ContentProvider IPC vs Simulation Fallback Mode toggle with dynamic target URI display.
  - Added local tool hosting in Demo (`demo_get_environment`) so sibling apps can call Demo over the mesh.
  - Added simulated AI Provider mode toggle between PAIOS Gemini Nano (On-Device AICore Floating Sheet) and Cloud AI Studio (Gemini 2.0 Flash Endpoint).
- Bumped `m3x_mesh` to `0.1.0+26110702` and `demo` to `1.2.10+26110701`.

## Update 1.2.9 `PURE FITTED AD BANNER, DYNAMIC PUBSPEC VERSION & BUILD DATE, FACTUAL DEPENDENCIES`
#### Changes
- **Pure Fitted Banner Ad Card (`CardContents.ad`)** (`packages/puzzak_ui/lib/elements.dart`):
  - Streamlined `CardContents.ad` to render **strictly the banner unit** fitted cleanly into the card via `FittedBox(fit: BoxFit.contain)` without superfluous titles, headers, icons, or badges.
  - Automatically takes on the surrounding `CardGroup`'s segmented 20px / 5px corner radii, background styling, and tap actions.
  - Retained backwards-compatible optional parameters for legacy call sites.
- **Dynamic Pubspec Version & Formatted Build Date** (`lib/engine.dart`, `lib/pages/settings_tab.dart`):
  - Dynamic parsing of `version: X.Y.Z+YYMMDDNN` from bundled `pubspec.yaml` (e.g. `1.2.9+26110501`).
  - Automated extraction of ecosystem build date from `YYMMDDNN` (`Nov 5, 2026 (rev 01)`), displayed directly in the Bento Version card.
- **Interactive Markdown Changelog in Settings** (`lib/pages/settings_tab.dart`):
  - Bundled `CHANGELOG.md` in app assets and loaded dynamically into a scrollable Material 3 modal sheet with full CommonMark rendering and external links.
- **Factual Dependency Metadata (Zero Fabricated Descriptions)** (`lib/engine.dart`, `lib/pages/settings_tab.dart`):
  - Removed artificial descriptions from `_parsePackagesFromPubspec` and `InstalledPackageInfo`.
  - Packages inspector now displays factual dependency data parsed from `pubspec.yaml` with workspace badges and direct pub.dev links.
- **Subagent-First Archetypes & Anti-Lobotomy Technical Lore** (`GEMINI.md`, `.agents/docs/TECHNICAL_LORE.md`):
  - Formally established 5 specialized subagent archetypes (`ui-engineer`, `backend-engineer`, `technical-lore-documenter`, `qa-verifier`, `researcher`) with strict non-overlapping file ownership and zero-tolerance delegation rules.
  - Linked each archetype to its canonical document in `.agents/docs/`.
  - Created `.agents/docs/TECHNICAL_LORE.md` as high-density LLM-to-LLM ground truth to survive context compaction (`/compact`).
- Bumped version across all packages to `1.2.9+26110502`.

## Update 1.2.8 `FULL NORMAL CARD PROPERTIES FOR AD UNITS & IN-BETWEEN CARD GROUP`
#### Changes
- **Full Normal Card Properties for `CardContents.ad`** (`packages/puzzak_ui/lib/elements.dart`):
  - Completely redesigned `CardContents.ad` to guarantee 100% parity with standard Puzzak cards (`CardContents.tapIcon`):
    - Standard card header with leading `35×35` icon, bold `18px` title, and `13px` subtitle.
    - Clean trailing `[ TEST AD ]` chip safely positioned in the header row, completely eliminating banner text overlap.
    - Centered, `12px` rounded-corner banner slot positioned below the card header inside the theme's `surfaceContainer`.
    - Integrated loading shimmer state matching card typography.
- **Embedded In-Between Two Normal Cards in Settings** (`lib/pages/settings_tab.dart`):
  - In Section 6 ("Google Mobile Ads & Monetization Lab"), embedded the ad card directly between `CardContents.turn` (Personalized Test Ads switch) and two standard `CardContents.tapIcon` action cards (Show Interstitial Ad and Show Rewarded Ad).
  - All 4 cards form a seamless segmented card group with 20px outer and 5px inner radii.
- Bumped versions across all packages to `1.2.8+26110309`.

## Update 1.2.7 `IN-BETWEEN CARDLIST-ABLE AD INTEGRATION`
#### Changes
- **CardList-able Ad Component (`CardContents.ad` & `CardContents.bannerAd`)** (`packages/puzzak_ui/lib/elements.dart`):
  - Created first-class `CardContents.ad(...)` and `CardContents.bannerAd(...)` components designed to be inserted anywhere inside a `CardGroup` or `context.cards.cardGroup([ ... ])`.
  - Automatically adapts to surrounding card radii (20px outer / 5px inner) based on its index in the group, inheriting surface colors, elevation, and card padding.
  - Renders live Google AdMob banners centered with an upper-corner `[ AD ]` or `[ TEST AD ]` badge, or renders an integrated Material 3 placeholder with title, subtitle, and icon when loading/offline.
- **`AdPlaceholderCard.inCardGroup(...)`** (`packages/puzzak_ui/lib/monetization.dart`):
  - Added factory constructor allowing developers to drop ads directly into card groups without redundant borders or padding.
- **Integrated Google Mobile Ads Lab & Elements Showcase**:
  - Replaced the standalone banner in `SettingsTab` with an in-between `CardContents.ad` card seamlessly positioned between `CardContents.turn` (Personalized Test Ads) and `CardContents.doubleTap` (Interstitial & Rewarded triggers).
  - Added interactive `CardContents.ad` sample in `ElementsTab` under Section 2 ("All CardContents Archetypes").
- Bumped versions across all packages to `1.2.7+26110308`.

## Update 1.2.6 `ROOT DOC TABS, DYNAMIC PUBSPEC PACKAGES, HTML PREPROCESSOR & COMMENTS CACHE`
#### Changes
- **Dynamic Installed Packages from `pubspec.yaml` (MCPlayer Pattern)** (`lib/engine.dart`, `lib/pages/settings_tab.dart`):
  - Replaced hardcoded packages list with dynamic runtime parsing of bundled `pubspec.yaml`, automatically detecting all top-level dependencies, versions, and ecosystem categories.
  - Tapping external packages opens `https://pub.dev/packages/{name}` in the system browser matching MCPlayer heritage.
  - Linked the Bento header cards in Settings to live `package_info_plus` version (`1.2.6 [26110307]`) and live package count (`${packages.length} Connected`).
- **GitHub Explorer Root Documentation Tabs & Deep Links** (`lib/pages/github_explorer_page.dart`, `lib/services/github_service.dart`):
  - Dynamic discovery of repository root documents via GitHub contents API (`README.md`, `LICENSE`, `SECURITY.md`, `ROADMAP.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`, `PRIVACY.md`).
  - Rendered horizontal document pills matching the GitHub web UI (`[ 📖 README ]  [ ⚖️ License ]  [ 🛡️ Security ]  [ 🗺️ Roadmap ] ...`).
  - Smart link tap handler: switches document tabs for root doc links, and pushes a nested document viewer with breadcrumb navigation for subfolder files (e.g. `docs/...`).
- **Markdown HTML Preprocessor for GitHub Content**:
  - Automatically transforms raw GitHub HTML tags (`<div align="center">`, `<h1>`..`<h4>`, `<br>`, linked badges, and `<img>` tags) into clean, standard Markdown, preventing raw HTML code blocks from rendering as unformatted text.
- **Fixed Issue Comments Infinite Refresh Loop**:
  - Implemented in-memory comments cache in `GitHubService` and migrated `_showIssueDetails` to a dedicated `_IssueDetailsSheet` (`StatefulWidget`) that initializes its query once in `initState()`.
  - Issue bodies and comments render full Markdown, embedded screenshots, and syntax-highlighted code blocks.
- **Directional Trailing Streak Motion Blur & Isolated Tab Transitions**:
  - Directional asymmetric trailing translation offset behind velocity vector (`-sign(velocity) * sigma * 0.38`).
  - Added strict axis filtering to `MotionBlurContainer` and `NeverScrollableScrollPhysics` on `TabBarView`, completely preventing horizontal tab switches from firing vertical blur or causing tab sliding jitter.
- Bumped versions across all packages to `1.2.6+26110307`.

## Update 1.2.4 `PLUG-AND-PLAY MOTION BLUR CONTAINER & CONTENT-ONLY ISOLATION`
#### Changes
- **Plug-and-Play `MotionBlurContainer`** (`packages/puzzak_ui/lib/motion_blur.dart`):
  - Converted blur architecture into a plug-and-play container that automatically connects to enclosing `Scrollable` ancestor positions or catches bubbling `ScrollNotification`s from child scroll views, eliminating the need for manual controllers, listeners, or boilerplate.
- **Content-Only Blur Isolation (Eliminated Title Jitter)**:
  - In sliver pages (`DashboardTab`, `ElementsTab`, `SettingsTab`, `ComplicationsTab`, and `SliverPageScaffold`), `SliverAppBar.large` is kept outside the `MotionBlurContainer`, allowing the expanding header title, back buttons, and actions to remain completely static, crisp, and jitter-free while blurring only the moving content cards.
- **Full App-Wide Coverage**:
  - Integrated `MotionBlurContainer` across `SliverPageScaffold`, all 4 main tabs, and all 4 tabs + modal bottom sheets in `GitHubExplorerPage` (README Markdown, Issues list, Releases list, Security list, Issue details sheet, and License viewer).
- Bumped versions across all packages to `1.2.4+26110305`.

## Update 1.2.3 `GITHUB EXPLORER MARKDOWN, COMMENTS & LICENSE`
#### Changes
- **Full Markdown Rendering in GitHub Explorer** (`lib/pages/github_explorer_page.dart`):
  - Upgraded README tab to rich `Markdown` with full link handling and custom image builder resolving repository assets and external image URLs.
  - Upgraded Issue details modal to rich `MarkdownBody` rendering code blocks (e.g. ````json ... ````) and embedded screenshots (`![alt](url)`).
  - Custom image builder handles GitHub attachment URLs and network screenshots with loading placeholders and external preview support.
- **Issue Comments Thread**:
  - Added `GitHubIssueComment` data model and `fetchIssueComments` API in `GitHubService`.
  - Added full comments thread to Issue modal sheet showing author avatar, username, timestamp, and rich markdown comment content.
- **In-App License Viewer**:
  - Added `fetchLicense` in `GitHubService` with automatic base64 decode and fallback to `HEAD/LICENSE`.
  - Added modal License viewer sheet in Security tab displaying the complete license text in-app.
- Bumped versions across all packages to `1.2.3+26110304`.

## Update 1.2.2 `TICKER MOTION BLUR, BENTO CARDS & PTK DASHBOARD`
#### Changes
- **Smooth Ticker Velocity Motion Blur & 120 FPS Performance** (`packages/puzzak_ui/lib/motion_blur.dart`):
  - Rewrote `MotionBlurScrollView` with a `SingleTickerProviderStateMixin` physics ticker that smoothly interpolates blur and applies exponential decay over ~120ms, completely eliminating 1-frame flickering and abrupt visual cutoffs.
  - Utilizes `ImageFiltered.enabled` set to `false` when idle, bypassing all offscreen GPU layer allocations and texture passes to guarantee 120 FPS performance on high-refresh-rate displays (Pixel 9 Pro).
  - High-intensity directional vertical streak with `maxBlur: 8.0` and `blurFactor: 0.0035` matching Sameera's Essentials fast scroll appearance.
  - Added interactive **Motion Blur Max Intensity Slider** in Settings (`2.0` to `14.0 px`) matching Sameera Essentials' dedicated motion blur slider.
- **Segmented 3-Card Bento Layout** (`packages/puzzak_ui/lib/elements.dart`):
  - Added `leadingCardWide` parameter to `Cards.cardGroup` and `CardGroup`: Card 0 spans full width with `top: 20px, bottom: 5px` corners, while Cards 1 & 2 render side-by-side with inner `5px` radii and outer `20px` corners, forming a seamless unified bento group.
  - Added `CardContents.slider` for Material 3 card slider rows.
- **PTK Telemetry & Dashboard Refinement** (`packages/puzzak_ui/lib/telemetry.dart`):
  - Set `showAreaFill: true` by default on `TelemetrySparklineCard` with `color.withValues(alpha: 0.22)` to `0.04` gradient shader, reproducing PTK's Thinkpad.dev dashboard cards.
  - Updated card height to `136px` with generous typography padding.
- Bumped versions across all packages to `1.2.2+26110303`.

## Update 1.2.0 `BILLING, ADS, CRASHLYTICS & GITHUB EXPLORER`
#### Changes
- **Fixed Scroll Physics & Motion Blur Detachment**:
  - Rewrote `MotionBlurScrollView` with an isolated `ValueNotifier` and `RepaintBoundary` around scroll content, eliminating `setState()` rebuilds on scroll ticks that caused scroll physics stutters and layer detachment
  - Reduced default `maxBlur` to subtle 2.0px and `blurFactor` to 0.0006 for creamy high-refresh-rate velocity blur without blurring into a smear
- **Clean Standard Navigation**: Removed Sameera floating nav pill from default app navigation in favor of clean standard Material 3 scaffold navigation while retaining haptics and motion blur
- **Real Google Play In-App Purchases & Subscriptions** (`BillingService`):
  - Added `in_app_purchase: ^3.3.1` integration querying store products (`puzzak_pro_lifetime`, `puzzak_pro_monthly`)
  - Full purchase stream lifecycle, purchase verification, purchase restoration, and interactive desktop/testing sandbox mode
- **Google Mobile Ads Integration** (`AdService`):
  - Added `google_mobile_ads: ^5.3.1` with official AdMob Test Ad Units (Banner, Interstitial, and Rewarded)
  - Interactive Ad Inspector in Settings with live test banner embedding and rewarded ad unlock callback
- **Google Firebase Crashlytics & Telemetry** (`CrashlyticsService`):
  - Global error boundary hooking into `FlutterError.onError` and `PlatformDispatcher.instance.onError`
  - Crashlytics Diagnostics Lab in Settings with simulated non-fatal errors, breadcrumbs, custom keys, and fatal crashes with graceful offline fallback
- **MCPlayer Heritage & Easter Egg**:
  - Brought MCPlayer's iconic App Header Card into Settings with logo, version, and the Rickroll Easter Egg ("Stop tapping everywhere! 🎵")
  - Two-column bento quick-info cards for Version [Build] and Installed Modules
- **GitHub Repository Explorer** (`GitHubService` & `GitHubExplorerPage`):
  - Switcher for Puzzak repositories (`PAIOS`, `PTK`, `MCPlayer`, `Website`, `.github`)
  - Live README renderer, Issues list with comment counts, labels, and issue detail dialog
  - Releases list with tag notes and direct APK asset download chips
  - Optional Personal Access Token (PAT) authentication raising API rate limits from 60 to 5,000 req/hr
- **New Support Triage Skill** (`puzzak-support-triage`):
  - Created skill in `.agents/skills/puzzak-support-triage` and `~/.gemini/config/skills/` enabling autonomous triage of GitHub issues, PRs, and Play Store comments when asking *"what do we need to do"*
- Bumped versions across all packages to `1.2.0+26110301`.

## Update 1.1.1 `TELEMETRY & SAMEERA ESSENTIALS REFINEMENT`
#### Changes
- Refined `FloatingNavPill` in `puzzak_ui` to precisely match Sameera Essentials (Image 1 & 2):
  - Stadium capsule with circular high-contrast back button, title label, and standalone rounded squircle trailing button (`actionButton`)
  - Compact `MainAxisSize.min` floating island design centered at the bottom of the screen
- Refined `TelemetrySparklineCard` to perfectly reproduce PTK's Thinkpad.dev screen (Image 5):
  - Compact 102px card height matching original PTK proportions
  - Clean cubic-bezier sparkline stroke along the lower card edge with `showAreaFill: false` by default (avoiding heavy shaded blocks)
  - Circular progress gauge positioned on the right side of the card aligned with `valueText` and `subValue`
  - Stopwatch uptime card with circular accented border ring
- Bumped versions across all packages to `1.1.1+26110202`.

## Update 1.1.0 `PLAYGROUND & CI/CD`
#### Changes
- Overhauled `TelemetrySparklineCard` in `puzzak_ui` to match the exact aesthetic of PTK's server telemetry (Thinkpad.dev screen):
  - Subtle cubic-bezier spline wave in lower card background with smooth linear gradient fill fading down
  - Clean `labelLarge` top title with `Expanded` text avoiding truncation
  - Added support for `subValue` (e.g. `"18.3%"`) and `progress` gauge indicator (`CircularProgressIndicator` on the right)
- Added Sameera Essentials inspired UI capabilities:
  - `MotionBlurScrollView` (`package:puzzak_ui/motion_blur.dart`): velocity-based directional motion blur on fast scrolling with toggle support
  - `FloatingNavPill` (`package:puzzak_ui/scaffolds.dart`): floating island navigation capsule with back button, center title, and circular contrasting action buttons
  - Haptic feedback integration (`HapticFeedback.lightImpact()` and `selectionClick()`) across toggles, card taps, and bottom navigation
- Added Monetization & Pro complications in `puzzak_ui`:
  - `SubscriptionTierCard`: Pro / Supporter tier card with badge, feature checklist, and Material 3 CTA button
  - `AdPlaceholderCard`: native Material 3 ad container matching Puzzak's 20px card radius standard
- Restructured Playground App into an authentic production app experience:
  - **Dashboard Tab**: PTK Thinkpad.dev live telemetry, server uptime, floating navigation capsule, reorderable servers, and sync card
  - **Elements Tab**: Full catalog of segmented cards, switches, steppers, and multi-column bento grids
  - **Settings Tab**: Production settings structure (Display & Interface with Motion Blur & Haptics toggles, System Dynamic Color vs Presets, Localization, Pro Membership, Data & Sync, About)
  - **Complications Tab**: Streaming Markdown chat, modal bottom sheets, text input dialogs, and formatters
- Added Dynamic System Palette Option in top app bar and settings: extracts Material 3 palette directly from Android/Pixel system wallpaper
- Automated CI/CD & Android Studio 1-Click Release Pipeline:
  - `scripts/build_releases.ps1`: automated test runner, GitHub APK builder, Google Play AAB builder, Windows standalone builder, Inno Setup installer generator, and SHA256 checksums
  - Android Studio Run Configurations (`.run/Build and Release All.run.xml`, `.run/Test and Analyze.run.xml`)
  - Multi-platform GitHub Actions workflow (`.github/workflows/ci_cd.yml`)
  - Comprehensive guide in `.agents/docs/CI_CD_AND_RELEASES.md`

## Update 1.0.2 `PLAYGROUND`
#### Fixes
- Fixed Android build failure (`Unresolved reference: kotlin { compilerOptions }` in `dynamic_color-1.9.0/android/build.gradle.kts`) by capping `dynamic_color` to `>=1.8.1 <1.9.0`; `1.9.0` relies on AGP 9 built-in Kotlin while this project (and `PTK`, `geminilocal`, `the2k48`) run AGP 8.x

## Update 1.0.1 `PLAYGROUND`
#### Changes
- Added mandatory `X.Y.Z+YYMMDDNN` versioning rule (`+0.0.1` small change, `+0.1.0` big feature, `+1.0.0` major release, `+YYMMDDNN` 8-digit build date + daily counter suffix) to `GEMINI.md` and the `puzzak-dev-system` skill
- Clarified target project scope rules in `GEMINI.md` and `puzzak-dev-system` so agents working on downstream apps (`PTK`, `geminilocal` / PAIOS, `the2k48`, `Website`, `ggscanus`, `binotool`) while referencing `demo` can freely edit their target app without rule conflicts
- Updated `pubspec.yaml` versions across root app (`1.0.1+26103101`) and packages (`1.0.0+26103101`)

## Update 1.0.0 `PLAYGROUND`
#### Changes
- Consolidated UI and core utilities from 6 reference projects (`PTK`, `the2k48`, `geminilocal`, `Website`, `ggscanus`, `binotool`) into 4 modular packages under `packages/`:
  - `puzzak_ui`: Core `elements.dart` (`Cards`, `CardGroup`, `ReorderableCardGroup`, `CardContents`, `Category`, `TextPart`) plus complications (`scaffolds.dart`, `pickers.dart`, `onboarding.dart`, `telemetry.dart`) with zero third-party dependencies
  - `puzzak_ui_chat`: Standalone chat UI complication (`ChatBubbleList`, `ChatMessageBubble`, `ChatTextPart.chatlog`) isolating `flutter_markdown` and `url_launcher`
  - `puzzak_dict`: Standalone 3-tier JSON localization engine (`Dictionary`, `DictionaryStorage`, `InMemoryDictionaryStorage`, `CallbackDictionaryStorage`) with zero UI dependencies
  - `puzzak_core`: Shared `AnalyticsService` consecutive-deduplicating logger and `PuzzakFormatters` (`formatBytes`, `convertSize`, `formatDuration`)
- Built the interactive **Puzzak UI Playground** app (`lib/`) featuring:
  - Live Material 3 seed color picker, `ThemeMode` switcher (`Light` / `System` / `Dark`), language switcher (`English` / `Українська`), and simulated viewport width slider (`280px` – `1200px`)
  - Interactive showcase tabs for Core Elements (`Cards`, `CardContents`, `ReorderableCardGroup`), Complications (`TelemetrySparklineCard`, `CircularGaugeCard`, `SyncStatusCard`, `ChatBubbleList`, modals & pickers), Page Templates (`SliverPageScaffold`, `OnboardingWizard`, `EmptyStateView`), and Core & Dict Lab (`Dictionary` fallback tester, `AnalyticsService` log deduplication tester, byte/duration formatters)
- Added AI-first workspace and global customization system:
  - Created `GEMINI.md` enforcing subagent delegation, living documentation updates, and UI standards
  - Created `.agents/docs/` reference catalogs (`UI_PALETTE_CATALOG.md`, `ARCHITECTURE_AND_QUIRKS.md`, `CROSS_PROJECT_ANALYSIS.md`)
  - Created `puzzak-dev-system` Antigravity skill in both `.agents/skills/` and `~/.gemini/config/skills/`
#### Fixes
- Fixed physical screen-width layout bug across `Cards`, `CardContents`, and `TextPart` where `(WidgetsBinding.instance.platformDispatcher.views.first.physicalSize / ...).width` and magic-number subtractions (`width - 70`, `width - 140`, `width - 190`) broke inside width-constrained containers, landscape split-views, and resizable desktop/web windows
- Fixed `RenderFlex` horizontal overflow in `CardContents.addretract` when displaying long titles or subtitles by wrapping the text column in `Expanded`
- Fixed vertical misalignment in `CardContents.turn` when `subtitle` is empty (`""`) by omitting the empty subtitle `Text` widget and centering the title row cleanly
- Fixed `Cards.cardGroup` multi-column mode (from `Website`) where passing 3 cards rendered `cards[1]` twice (producing 4 cards) and misaligned bottom outer corners on odd item counts
- Fixed `CardContents.progress` indeterminate spinner bug (from `geminilocal`, `the2k48`, `Website`) where `progress == 0.0` (0%) and `progress == 1.0` (100%) evaluated to `value: null`; now uses `progress < 0 ? null : progress.clamp(0.0, 1.0)`
- Fixed `ReorderableCardGroup` drag handle bug (from `PTK/lib/pages/servers.dart:200`) where `ReorderableDragStartListener` hardcoded `index: 0` instead of the item's index
- Fixed `TelemetrySparklineCard` history mutation bug (from `Website`'s `TestTelemetryGraphCard`) where every parent widget rebuild appended a duplicate data point even when telemetry had not ticked
- Fixed `ChatTextPart.chatlog` historical message hiding bug (from `geminilocal`/`the2k48`) where `!(lastUser == userMessage)` hid every earlier message in the conversation that had the same text as `lastUser`, and fixed null-unsafe `Uri.parse(href!)` on Markdown links
- Fixed `Dictionary.setup()` network hang risk by adding configurable `httpTimeout` (default 5 seconds) to remote GitHub translation fetches
- Fixed `Dictionary.setSystemLanguage()` bug by combining `storage.delete("language")` (from `geminilocal`/`the2k48`) with the `"en"` fallback when the device locale is unsupported (from `PTK`), using web-safe `PlatformDispatcher.instance.locale.languageCode`
#### Miscellaneous
- Decoupled `Cards` from `AppEngine` by introducing the `context.cards` extension and `CardGroup` widget while keeping `Cards(context: context)` for 100% drop-in backwards compatibility


---
> Template for later updates
```Markdown
## Update 1.0.0 `PLAYGROUND`
#### Changes
#### Fixes
#### Known Issues
#### Miscellaneous
```
