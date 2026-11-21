import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3x/m3x.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/billing_service.dart';
import 'services/crashlytics_service.dart';

class DemoServerItem {
  final String id;
  String name;
  String url;
  String status;

  DemoServerItem({
    required this.id,
    required this.name,
    required this.url,
    required this.status,
  });
}

/// Metadata model for live packages parsed dynamically from `pubspec.yaml`
/// (inspired by MCPlayer's settings package inspector).
class InstalledPackageInfo {
  final String name;
  final String version;
  final bool isPuzzak;

  const InstalledPackageInfo({
    required this.name,
    required this.version,
    required this.isPuzzak,
  });
}

class PlaygroundEngine extends ChangeNotifier {
  bool appStarted = false;
  bool showOnboardingOverlay = false;
  int selectedTab = 0;

  // Live Application Metadata & Installed Dependencies (MCPlayer pattern)
  String appName = 'demo';
  String appDescription = '';
  String appVersion = '1.2.9';
  String appBuildNumber = '26110502';
  String appBuildDate = 'Nov 5, 2026 (rev 02)';
  String appVersionDisplay = '1.2.9 (Nov 5, 2026 (rev 02))';
  String changelogContent = '';
  List<InstalledPackageInfo> installedPackages = [];

  // Theme & Viewport Inspector Controls
  ThemeMode themeMode = ThemeMode.system;
  Color seedColor = Colors.teal;
  bool useDynamicColor = true; // Default to System dynamic color on supported devices
  double? simulatedViewportWidth; // null = unconstrained (full width)
  bool showDesktopLogPanel = true;

  // Modern Experience Flags (Motion Blur, Haptics)
  bool motionBlurEnabled = true;
  double motionBlurIntensity = 8.0; // Sameera Essentials style (2.0 to 14.0 px)
  bool hapticsEnabled = true;
  bool floatingNavPillEnabled = false;
  bool isProUser = false;

  // Core Standalone Services
  late final Dictionary dict;
  late final AnalyticsService logger;
  late final M3xMeshClient meshClient;
  bool meshEnabled = true;

  // Tab 1: Elements Playground State
  bool stressTestLongStrings = false;
  int cardGroupColumns = 1;
  int cardGroupItemCount = 3;
  bool switchWithSubtitle = true;
  bool switchWithoutSubtitle = false;
  int counterValue = 4;
  double progressDemoValue = 0.65; // < 0 for indeterminate, 0.0..1.0 for determinate
  String selectedMetricOption = 'cpu_load';
  String customRenamedTitle = 'Kyiv Primary Node';

  final List<DemoServerItem> reorderableServers = [
    DemoServerItem(
      id: 'srv-1',
      name: 'Kyiv Edge Node',
      url: 'https://kyiv.puzzak.page/AIO.php',
      status: '12 ms • AIO Telemetry',
    ),
    DemoServerItem(
      id: 'srv-2',
      name: 'Frankfurt Relay',
      url: 'https://fra.puzzak.page/AIO.php',
      status: '28 ms • AIO Telemetry',
    ),
    DemoServerItem(
      id: 'srv-3',
      name: 'Lviv Backup NAS',
      url: 'https://lviv.puzzak.page',
      status: '19 ms • Ping Only',
    ),
    DemoServerItem(
      id: 'srv-4',
      name: 'Warsaw Gateway',
      url: 'https://waw.puzzak.page/AIO.php',
      status: '24 ms • AIO Telemetry',
    ),
  ];

  // Tab 2: Telemetry & Sync State
  Timer? _telemetryTimer;
  bool liveTelemetryRunning = true;
  int _tick = 0;
  List<double> cpuHistory = [0.22, 0.28, 0.35, 0.31, 0.42, 0.38, 0.45, 0.52, 0.41, 0.36];
  List<double> ramHistory = [0.58, 0.59, 0.60, 0.61, 0.62, 0.62, 0.63, 0.61, 0.62, 0.63];
  List<double> netHistory = [0.12, 0.45, 0.68, 0.30, 0.25, 0.80, 0.55, 0.40, 0.32, 0.48];
  bool isSyncingContacts = false;
  double syncProgress = 0.0;

  // Tab 2: Chat UI Complication State
  bool showChatAvatars = true;
  final List<ChatMessage> chatMessages = [
    ChatMessage(
      sender: 'User',
      author: 'You',
      message: 'ok',
      isUser: true,
      timestamp: DateTime(2026, 11, 15, 14, 28, 10),
      avatarIcon: Icons.person_rounded,
    ),
    ChatMessage(
      sender: 'Gemini',
      author: 'Gemini Nano v4',
      message:
          'Hey! Notice how your earlier **"ok"** message above stays visible even when the latest message is also `"ok"` — that fixes the historical duplicate-message filter bug from `elements.dart`!\n\nHere is a quick code sample:\n```dart\ncontext.cards.cardGroup([\n  CardContents.tap(title: "Clean UI", subtitle: "Zero screen-width math", action: () {}),\n]);\n```',
      thoughts:
          '1. Verify historical duplicate-message preservation for "ok".\n2. Include concise Material 3 cardGroup example using context.cards.',
      isUser: false,
      timestamp: DateTime(2026, 11, 15, 14, 28, 14),
      avatarIcon: Icons.auto_awesome_rounded,
    ),
    ChatMessage(
      sender: 'User',
      author: 'You',
      message: 'ok',
      isUser: true,
      timestamp: DateTime(2026, 11, 15, 14, 29, 2),
      avatarIcon: Icons.person_rounded,
    ),
  ];
  String streamingAiChunk = '';
  bool isStreamingChat = false;

  // Tab 4: Formatters Lab State
  double sampleBytes = 15728640; // ~15 MB
  bool formatAsThroughput = true;
  bool formatInBits = false;
  int sampleDurationSeconds = 93784; // 1d 2h 3m 4s

  PlaygroundEngine() {
    logger = AnalyticsService(
      notifyEngine: genericRefresh,
      defaultEnabled: false,
    );
    dict = Dictionary(
      path: 'assets/translations',
      demoDataPath: 'assets/data/demo_dictionary.json',
      debugHighlightFallbacks: true,
      onRemoteUpdated: genericRefresh,
    );
  }

  void genericRefresh() => notifyListeners();

  Future<void> start() async {
    logger.log('Engine', 'info', 'Initializing Puzzak UI Playground...');
    CrashlyticsService.instance.initialize();
    BillingService.instance.initialize();
    // AdService.instance.initialize();

    // 1. Load Live Platform Version & Pubspec Metadata (MCPlayer pattern)
    try {
      await M3x.init();
      final yamlContent = await rootBundle.loadString('pubspec.yaml');
      _parseVersionAndDateFromPubspec(yamlContent);
      installedPackages = _parsePackagesFromPubspec(yamlContent);
      logger.log(
        'Engine',
        'info',
        'Loaded ${installedPackages.length} packages dynamically from pubspec.yaml',
      );
    } catch (e) {
      logger.log('Engine', 'error', 'Error parsing pubspec.yaml: $e');
    }

    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty && info.version != '1.0.0') {
        appVersion = info.version;
        if (info.buildNumber.isNotEmpty) {
          appBuildNumber = info.buildNumber;
          appBuildDate = _formatBuildDate(appBuildNumber);
        }
        appVersionDisplay = appBuildDate.isNotEmpty
            ? '$appVersion ($appBuildDate)'
            : appVersion;
      }
    } catch (_) {
      // Retain version & date parsed from pubspec.yaml
    }

    // 2. Load CHANGELOG.md for interactive Settings Changelog modal
    try {
      if (M3x.changelogContent.isNotEmpty) {
        changelogContent = M3x.changelogContent;
      } else {
        changelogContent = await rootBundle.loadString('CHANGELOG.md');
      }
    } catch (e) {
      changelogContent = '# Changelog\n\nNo changelog available.';
    }

    await dict.setup();
    logger.log(
      'Dictionary',
      'info',
      'Loaded ${dict.languages.length} languages (active: ${dict.locale})',
    );
    await _initMesh();
    _startTelemetrySimulation();
    appStarted = true;
    notifyListeners();
  }

  Future<void> _initMesh() async {
    final isNativeAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    meshClient = M3xMeshClient(
      localAppId: 'demo',
      enableSimulation: !isNativeAndroid,
    );

    meshClient.registerLocalTool(
      M3xTool(
        name: 'demo_get_environment',
        app: 'demo',
        description:
            "Returns the Demo UI Playground app's current theme, version, haptics, and platform state. ONLY call when the user explicitly asks about the Demo UI Playground app itself. NEVER call for attached photos/images, nature/objects, general questions, AI/device architecture, or unrelated follow-ups.",
        parameters: const {'type': 'object', 'properties': {}},
        handler: (args) async => {
          'app': appName,
          'version': appVersion,
          'build_number': appBuildNumber,
          'theme_mode': themeMode.name,
          'seed_color': '#${(seedColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'dynamic_color': useDynamicColor,
          'platform': defaultTargetPlatform.name,
          'haptics_enabled': hapticsEnabled,
          'motion_blur_enabled': motionBlurEnabled,
          'status': 'online',
        },
      ),
    );

    meshClient.registerLocalTool(
      M3xTool(
        name: 'demo_get_components',
        app: 'demo',
        description:
            'Returns Flutter UI widgets (Cards, Bento, Scaffolds, Category) in the Demo UI Playground app. NEVER call for questions about AI, Gemini Nano, device hardware, or system architecture.',
        parameters: const {'type': 'object', 'properties': {}},
        handler: (args) async => {
          'count': 9,
          'packages': [
            'm3x_ui',
            'm3x_chat',
            'm3x_mesh',
            'm3x_dict',
            'm3x_core',
            'm3x_storage',
            'm3x_gh',
          ],
          'components': [
            {
              'category': 'Elements',
              'widgets': [
                'Cards',
                'CardGroup',
                'ReorderableCardGroup',
                'CardContents',
                'Category',
                'TextPart',
              ],
            },
            {
              'category': 'Bento',
              'widgets': ['BentoGrid', 'BentoCard', 'SettingsBentoHeader'],
            },
            {
              'category': 'Chat',
              'widgets': [
                'ChatBubbleList',
                'ChatMessageBubble',
                'ChatInputBar',
                'ChatTextPart',
              ],
            },
            {
              'category': 'Telemetry',
              'widgets': [
                'TelemetrySparklineCard',
                'MetricSparkline',
                'LiveProgressRing',
              ],
            },
            {
              'category': 'Scaffolds',
              'widgets': ['M3xScaffold', 'AdaptiveDrawer', 'NavigationPill'],
            },
            {
              'category': 'Pickers',
              'widgets': ['ColorPickerBottomSheet', 'DynamicSegmentedPicker'],
            },
            {
              'category': 'Onboarding',
              'widgets': ['InteractiveOnboardingSheet', 'FeatureTourModal'],
            },
            {
              'category': 'Motion & Animation',
              'widgets': ['MotionBlurWrapper', 'SmoothSheet'],
            },
            {
              'category': 'Monetization',
              'widgets': ['ProBadge', 'UpgradeGateSheet'],
            },
          ],
        },
      ),
    );

    await meshClient.startListening();
    await meshClient.syncDeclaredTools();
    logger.log(
      'Mesh',
      'info',
      'Registered local tools (demo_get_environment, demo_get_components) and synced with ContentProvider',
    );
  }

  /// Lightweight headless initialization for M3x Mesh cold-start queries.
  Future<void> startHeadlessForMesh() async {
    try {
      await M3x.init();
      final yamlContent = await rootBundle.loadString('pubspec.yaml');
      _parseVersionAndDateFromPubspec(yamlContent);
    } catch (_) {}
    await _initMesh();
  }

  /// Parses `version: X.Y.Z+YYMMDDNN`, name, and description from `pubspec.yaml`.
  void _parseVersionAndDateFromPubspec(String yaml) {
    if (M3x.appVersion.isNotEmpty) {
      appName = M3x.appName;
      appDescription = M3x.appDescription;
      appVersion = M3x.appVersion;
      appBuildNumber = M3x.appBuildNumber;
      appBuildDate = M3x.appBuildDate;
      appVersionDisplay = M3x.versionDisplay;
      return;
    }

    for (final rawLine in yaml.split('\n')) {
      final line = rawLine.replaceAll('\r', '').trim();
      if (line.startsWith('name:')) {
        appName = line.substring('name:'.length).trim().replaceAll("'", '').replaceAll('"', '');
      } else if (line.startsWith('description:')) {
        appDescription = line.substring('description:'.length).trim().replaceAll("'", '').replaceAll('"', '');
      } else if (line.startsWith('version:')) {
        final val = line
            .substring('version:'.length)
            .trim()
            .replaceAll("'", '')
            .replaceAll('"', '');
        final parts = val.split('+');
        if (parts.isNotEmpty) {
          appVersion = parts[0].trim();
        }
        if (parts.length > 1) {
          appBuildNumber = parts[1].trim();
          appBuildDate = _formatBuildDate(appBuildNumber);
        }
        appVersionDisplay = appBuildDate.isNotEmpty
            ? '$appVersion ($appBuildDate)'
            : appVersion;
      }
    }
  }

  /// Formats ecosystem `+YYMMDDNN` build number (e.g. `26110501`) into
  /// human-readable date: `Nov 5, 2026 (rev 01)`.
  String _formatBuildDate(String build) {
    if (build.length < 6) return build;
    final yy = int.tryParse(build.substring(0, 2)) ?? 26;
    final mm = int.tryParse(build.substring(2, 4)) ?? 1;
    final dd = int.tryParse(build.substring(4, 6)) ?? 1;
    final nn = build.length >= 8 ? build.substring(6, 8) : '';
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthName = (mm >= 1 && mm <= 12) ? months[mm] : 'Month $mm';
    final year = 2000 + yy;
    return '$monthName $dd, $year${nn.isNotEmpty ? ' (rev $nn)' : ''}';
  }

  /// Parses top-level packages under `dependencies:` in `pubspec.yaml` via [M3x].
  List<InstalledPackageInfo> _parsePackagesFromPubspec(String yaml) {
    if (M3x.dependencies.isEmpty) {
      M3x.parsePubspec(yaml);
    }
    return M3x.dependencies.entries.map((entry) {
      final isPuzzak = entry.key.startsWith('puzzak_') ||
          entry.key.startsWith('m3x') ||
          entry.value.startsWith('path:');
      return InstalledPackageInfo(
        name: entry.key,
        version: entry.value,
        isPuzzak: isPuzzak,
      );
    }).toList();
  }

  void _startTelemetrySimulation() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!liveTelemetryRunning) return;
      _tick++;
      final double nextCpu =
          (0.35 + 0.25 * math.sin(_tick * 0.5) + 0.1 * math.cos(_tick * 1.3))
              .clamp(0.08, 0.95);
      final double nextRam =
          (0.62 + 0.08 * math.sin(_tick * 0.2)).clamp(0.40, 0.88);
      final double nextNet =
          (0.40 + 0.35 * math.cos(_tick * 0.7)).clamp(0.05, 0.98);

      cpuHistory = [...cpuHistory.skip(cpuHistory.length >= 24 ? 1 : 0), nextCpu];
      ramHistory = [...ramHistory.skip(ramHistory.length >= 24 ? 1 : 0), nextRam];
      netHistory = [...netHistory.skip(netHistory.length >= 24 ? 1 : 0), nextNet];
      notifyListeners();
    });
  }

  void toggleLiveTelemetry() {
    liveTelemetryRunning = !liveTelemetryRunning;
    logger.log(
      'Telemetry',
      'info',
      liveTelemetryRunning ? 'Resumed live sparkline feed' : 'Paused sparkline feed',
    );
    notifyListeners();
  }

  void setSelectedTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    logger.log('Theme', 'info', 'ThemeMode switched to ${mode.name}');
    notifyListeners();
  }

  void setSeedColor(Color color, String label) {
    seedColor = color;
    useDynamicColor = false;
    logger.log('Theme', 'info', 'Seed color changed to $label');
    performHapticClick();
    notifyListeners();
  }

  void setUseDynamicColor(bool val) {
    useDynamicColor = val;
    logger.log('Theme', 'info', 'Use dynamic system color set to $val');
    performHapticClick();
    notifyListeners();
  }

  void toggleMotionBlur(bool val) {
    motionBlurEnabled = val;
    logger.log('Settings', 'info', 'Motion blur on scroll: $val');
    performHapticImpact();
    notifyListeners();
  }

  void setMotionBlurIntensity(double val) {
    motionBlurIntensity = val;
    logger.log('Settings', 'info', 'Motion blur intensity: ${val.toStringAsFixed(1)}px');
    notifyListeners();
  }

  void toggleHaptics(bool val) {
    hapticsEnabled = val;
    logger.log('Settings', 'info', 'Haptic feedback: $val');
    if (val) HapticFeedback.lightImpact();
    notifyListeners();
  }

  void toggleFloatingNavPill(bool val) {
    floatingNavPillEnabled = val;
    logger.log('Settings', 'info', 'Floating nav pill: $val');
    performHapticImpact();
    notifyListeners();
  }

  void toggleProUser(bool val) {
    isProUser = val;
    logger.log('Subscription', 'info', 'Pro status changed to $val');
    performHapticImpact();
    notifyListeners();
  }

  void toggleMeshEnabled(bool val) {
    meshEnabled = val;
    meshClient.enabled = val;
    logger.log('Mesh', 'info', 'Agentic Mesh enabled set to $val');
    performHapticImpact();
    notifyListeners();
  }

  void performHapticClick() {
    if (hapticsEnabled) HapticFeedback.selectionClick();
  }

  void performHapticImpact() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
  }

  void setSimulatedViewportWidth(double? width) {
    simulatedViewportWidth = width;
    notifyListeners();
  }

  void toggleDesktopLogPanel() {
    showDesktopLogPanel = !showDesktopLogPanel;
    notifyListeners();
  }

  Future<void> selectLanguage(String code) async {
    await dict.setLanguage(code);
    logger.log('Dictionary', 'info', 'Language set to $code');
    notifyListeners();
  }

  Future<void> resetToSystemLanguage() async {
    await dict.setSystemLanguage();
    logger.log(
      'Dictionary',
      'info',
      'Reset to system language (resolved: ${dict.locale})',
    );
    notifyListeners();
  }

  void toggleDebugFallbackHighlights(bool value) {
    dict.debugHighlightFallbacks = value;
    logger.log(
      'Dictionary',
      'info',
      'Debug fallback markers (!...!) set to $value',
    );
    notifyListeners();
  }

  void reorderServers(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = reorderableServers.removeAt(oldIndex);
    reorderableServers.insert(newIndex, item);
    logger.log(
      'ReorderableCardGroup',
      'info',
      'Moved "${item.name}" from #$oldIndex to #$newIndex',
    );
    notifyListeners();
  }

  Future<void> triggerSimulatedSync() async {
    if (isSyncingContacts) return;
    isSyncingContacts = true;
    syncProgress = -1; // start indeterminate
    logger.log('SyncCard', 'info', 'Started background contact sync...');
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));
    for (int i = 1; i <= 5; i++) {
      syncProgress = i / 5.0;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }

    isSyncingContacts = false;
    syncProgress = 1.0;
    logger.log('SyncCard', 'info', 'Sync completed: 142 contacts verified');
    notifyListeners();
  }

  void toggleShowChatAvatars(bool val) {
    showChatAvatars = val;
    logger.log('ChatUI', 'info', 'Show chat avatars set to $val');
    performHapticClick();
    notifyListeners();
  }

  Future<void> simulateAiStreamResponse([String? userPrompt]) async {
    if (isStreamingChat) return;
    if (userPrompt != null && userPrompt.trim().isNotEmpty) {
      chatMessages.add(
        ChatMessage(
          sender: 'User',
          author: 'You',
          message: userPrompt.trim(),
          isUser: true,
          timestamp: DateTime.now(),
          avatarIcon: Icons.person_rounded,
        ),
      );
    }
    isStreamingChat = true;
    streamingAiChunk = '';

    final int aiIndex = chatMessages.length;
    chatMessages.add(
      ChatMessage(
        sender: 'Gemini',
        author: 'Gemini Nano v4',
        message: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
        loadingLabel: 'Warming up reasoning…',
        avatarIcon: Icons.auto_awesome_rounded,
      ),
    );
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 420));
    chatMessages[aiIndex] = chatMessages[aiIndex].copyWith(
      thoughts: 'Analyzing prompt intent and formatting Markdown output…',
      isThinkingStreaming: true,
      loadingLabel: 'Continuing response…',
    );
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 520));
    chatMessages[aiIndex] = chatMessages[aiIndex].copyWith(
      thoughts:
          'Analyzing prompt intent and formatting Markdown output…\nSelected responsive Material 3 bubble with collapsible thoughts & forward skeleton.',
    );
    notifyListeners();

    const List<String> chunks = [
      'Streaming ',
      'via **`m3x_chat`**...\n\n',
      '- Animated shimmer skeleton (`ChatAnimatedSkeleton`)\n',
      '- Collapsible thoughts (`ChatThoughtsBlock`)\n',
      '- Tap any bubble to reveal `author` & `timestamp`!',
    ];

    String accumulated = '';
    for (final piece in chunks) {
      await Future<void>.delayed(const Duration(milliseconds: 240));
      accumulated += piece;
      chatMessages[aiIndex] = chatMessages[aiIndex].copyWith(
        message: accumulated,
        isThinkingStreaming: false,
        isLoading: true,
        loadingLabel: 'Continuing response…',
      );
      notifyListeners();
    }

    chatMessages[aiIndex] = chatMessages[aiIndex].copyWith(
      isLoading: false,
      clearLoadingLabel: true,
      timestamp: DateTime.now(),
    );
    streamingAiChunk = '';
    isStreamingChat = false;
    logger.log('ChatUI', 'info', 'Completed simulated AI streaming response');
    notifyListeners();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
