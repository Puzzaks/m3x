library;

import 'package:flutter/services.dart';
import 'package:m3x_gh/m3x_gh.dart';
import 'package:m3x_storage/m3x_storage.dart';
import 'package:m3x_ui/m3x_ui.dart';

export 'package:m3x_chat/m3x_chat.dart';
export 'package:m3x_core/m3x_core.dart';
export 'package:m3x_dict/m3x_dict.dart';
export 'package:m3x_gh/m3x_gh.dart';
export 'package:m3x_mesh/m3x_mesh.dart';
export 'package:m3x_storage/m3x_storage.dart';
export 'package:m3x_ui/m3x_ui.dart';

/// Central orchestration class for the M3x Flutter ecosystem.
///
/// Automatically parses bundled `pubspec.yaml` metadata, configures standard
/// storage box names, derives human-friendly version displays, and auto-detects
/// repository information.
class M3x {
  M3x._();

  static bool _initialized = false;

  /// Returns `true` once [init] has successfully executed.
  static bool get isInitialized => _initialized;

  /// Structured configuration view for [M3x].
  static const M3xConfig config = M3xConfig();

  /// Application package name derived from `name:` in `pubspec.yaml`.
  static String appName = '';

  /// Application description derived from `description:` in `pubspec.yaml`.
  static String appDescription = '';

  /// Application semantic version (e.g. `1.2.9`).
  static String appVersion = '';

  /// Ecosystem build number (e.g. `26110502`).
  static String appBuildNumber = '';

  /// Human-readable build date (e.g. `Nov 5, 2026 (rev 02)`).
  static String appBuildDate = '';

  /// Clean display version formatted strictly as `X.Y.Z (Month DD, YYYY (rev NN))`
  /// (e.g. `1.2.9 (Nov 5, 2026 (rev 02))`), omitting raw bracketed build numbers.
  static String versionDisplay = '';

  /// Default persistent storage box name derived from [appName].
  ///
  /// Format: `${appName.toLowerCase().replaceAll(' ', '_')}_storage`.
  static String storageBoxName = '';

  /// Auto-detected GitHub repository owner if `repository:` or `homepage:` is defined.
  static String githubOwner = '';

  /// Auto-detected GitHub repository name if `repository:` or `homepage:` is defined.
  static String githubRepo = '';

  /// Full GitHub repository URL if detected.
  static String? githubUrl;

  /// Cached native app launcher icon bytes extracted via `m3x_mesh`.
  static Uint8List? _appIconBytes;

  /// Cached native app launcher icon bytes extracted via `m3x_mesh`.
  static Uint8List? get appIconBytes => _appIconBytes;
  static set appIconBytes(Uint8List? bytes) {
    _appIconBytes = bytes;
    SettingsBentoHeader.defaultIconBytes = bytes;
  }

  /// Content of the bundled `CHANGELOG.md` file, or empty if not bundled.
  static String changelogContent = '';

  /// Whether Inter-App Agentic Mesh (`m3x_mesh`) discovery and IPC are enabled for this app.
  static bool enableMesh = true;

  /// Raw key-value metadata parsed from `pubspec.yaml`.
  static final Map<String, String> metadata = <String, String>{};

  /// Live package dependencies (`name -> version/path spec`) parsed from `pubspec.yaml`.
  static final Map<String, String> dependencies = <String, String>{};

  /// Initializes the M3x ecosystem by loading and parsing bundled `pubspec.yaml`
  /// and `CHANGELOG.md` assets.
  static Future<void> init({
    String pubspecAssetPath = 'pubspec.yaml',
    String changelogAssetPath = 'CHANGELOG.md',
    String? pubspecPath,
    String? changelogPath,
    bool enableMesh = true,
    AssetBundle? bundle,
  }) async {
    M3x.enableMesh = enableMesh;
    final AssetBundle effectiveBundle = bundle ?? rootBundle;
    final String effectivePubspecPath = pubspecPath ?? pubspecAssetPath;
    final String effectiveChangelogPath = changelogPath ?? changelogAssetPath;

    // 1. Load and parse pubspec.yaml
    try {
      final String yaml =
          await effectiveBundle.loadString(effectivePubspecPath);
      parsePubspec(yaml);
    } catch (_) {
      // Graceful fallback when assets are not bundled (e.g. headless unit tests)
      if (appName.isEmpty) {
        appName = 'm3x_app';
        storageBoxName = 'm3x_app_storage';
      }
    }

    // 2. Load CHANGELOG.md if bundled
    try {
      changelogContent =
          await effectiveBundle.loadString(effectiveChangelogPath);
    } catch (_) {
      changelogContent = '';
    }

    // 3. Extract native launcher icon via M3xMesh platform channel
    try {
      const channel = MethodChannel('com.puzzak.m3x_mesh');
      appIconBytes = await channel.invokeMethod<Uint8List>('getAppIcon');
    } catch (_) {
      appIconBytes = null;
    }

    // 4. Sync SettingsBentoHeader defaults for changelog & version display
    SettingsBentoHeader.defaultChangelogContent = changelogContent;
    SettingsBentoHeader.defaultVersionDisplay =
        appVersion.isNotEmpty && appBuildDate.isNotEmpty
            ? 'v$appVersion • $appBuildDate'
            : (versionDisplay.isNotEmpty ? 'v$versionDisplay' : '');

    _initialized = true;
  }

  /// Parses raw YAML string content from `pubspec.yaml` and populates [M3x] metadata
  /// and [dependencies].
  static void parsePubspec(String yaml) {
    metadata.clear();
    dependencies.clear();

    String rawName = '';
    String rawDescription = '';
    String rawVersion = '';
    String rawRepo = '';
    String rawHomepage = '';

    bool inDependencies = false;
    String? pendingDepName;
    final Map<String, String> pendingDepProps = <String, String>{};

    void flushPendingDep() {
      if (pendingDepName == null) return;
      final String name = pendingDepName!;
      pendingDepName = null;

      if (name == 'flutter' ||
          name == 'flutter_localizations' ||
          pendingDepProps['sdk'] == 'flutter') {
        pendingDepProps.clear();
        return;
      }

      if (pendingDepProps.containsKey('path') &&
          pendingDepProps['path']!.isNotEmpty) {
        dependencies[name] = 'path: ${pendingDepProps['path']}';
      } else if (pendingDepProps.containsKey('version') &&
          pendingDepProps['version']!.isNotEmpty) {
        dependencies[name] = pendingDepProps['version']!;
      } else if (pendingDepProps.containsKey('git') &&
          pendingDepProps['git']!.isNotEmpty) {
        dependencies[name] = 'git: ${pendingDepProps['git']}';
      } else if (pendingDepProps.containsKey('url') &&
          pendingDepProps['url']!.isNotEmpty) {
        dependencies[name] = 'git: ${pendingDepProps['url']}';
      } else if (pendingDepProps.containsKey('sdk') &&
          pendingDepProps['sdk']!.isNotEmpty) {
        dependencies[name] = 'sdk: ${pendingDepProps['sdk']}';
      } else if (pendingDepProps.isNotEmpty) {
        final MapEntry<String, String> first = pendingDepProps.entries.first;
        dependencies[name] = '${first.key}: ${first.value}';
      } else {
        dependencies[name] = 'workspace';
      }
      pendingDepProps.clear();
    }

    final RegExp topLevelDepRegex = RegExp(r'^  ([a-zA-Z0-9_]+):(?:\s*(.*))?$');
    final RegExp nestedDepPropRegex =
        RegExp(r'^\s{4,}([a-zA-Z0-9_]+):(?:\s*(.*))?$');

    for (final String rawLine in yaml.split('\n')) {
      final String cleanLine = rawLine.replaceAll('\r', '');
      final String trimmed = cleanLine.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final bool isTopLevel =
          !cleanLine.startsWith(' ') && !cleanLine.startsWith('\t');

      if (isTopLevel) {
        if (inDependencies) {
          flushPendingDep();
          inDependencies = false;
        }

        if (trimmed.startsWith('name:')) {
          rawName = _cleanYamlValue(trimmed.substring('name:'.length));
          metadata['name'] = rawName;
        } else if (trimmed.startsWith('description:')) {
          rawDescription =
              _cleanYamlValue(trimmed.substring('description:'.length));
          metadata['description'] = rawDescription;
        } else if (trimmed.startsWith('version:')) {
          rawVersion = _cleanYamlValue(trimmed.substring('version:'.length));
          metadata['version'] = rawVersion;
        } else if (trimmed.startsWith('repository:')) {
          rawRepo = _cleanYamlValue(trimmed.substring('repository:'.length));
          metadata['repository'] = rawRepo;
        } else if (trimmed.startsWith('homepage:')) {
          rawHomepage = _cleanYamlValue(trimmed.substring('homepage:'.length));
          metadata['homepage'] = rawHomepage;
        } else if (trimmed.startsWith('dependencies:')) {
          inDependencies = true;
        }
        continue;
      }

      if (inDependencies) {
        final RegExpMatch? depMatch = topLevelDepRegex.firstMatch(cleanLine);
        if (depMatch != null) {
          flushPendingDep();
          final String depName = depMatch.group(1)!;
          final String inlineVal = _cleanYamlValue(depMatch.group(2) ?? '');
          if (inlineVal.isNotEmpty) {
            if (depName != 'flutter' && depName != 'flutter_localizations') {
              dependencies[depName] = inlineVal;
            }
          } else {
            pendingDepName = depName;
          }
          continue;
        }

        if (pendingDepName != null) {
          final RegExpMatch? propMatch =
              nestedDepPropRegex.firstMatch(cleanLine);
          if (propMatch != null) {
            final String propKey = propMatch.group(1)!;
            final String propVal = _cleanYamlValue(propMatch.group(2) ?? '');
            if (propVal.isNotEmpty) {
              pendingDepProps[propKey] = propVal;
            }
          }
        }
      }
    }

    if (inDependencies) {
      flushPendingDep();
    }

    SettingsBentoHeader.defaultDependencies =
        Map<String, String>.unmodifiable(dependencies);

    appName = rawName;
    appDescription = rawDescription;
    storageBoxName = appName.isNotEmpty
        ? '${appName.toLowerCase().replaceAll(' ', '_')}_storage'
        : 'm3x_storage';
    M3xStorage.defaultBoxName = storageBoxName;

    // Parse version & build date
    _parseVersion(rawVersion);

    // Auto-detect GitHub owner & repo
    final String targetUrl = rawRepo.isNotEmpty ? rawRepo : rawHomepage;
    _parseGitHub(targetUrl);
  }

  /// Parses the version string and formats [versionDisplay].
  static void _parseVersion(String rawVersion) {
    if (rawVersion.isEmpty) return;

    final List<String> parts = rawVersion.split('+');
    appVersion = parts[0].trim();

    if (parts.length > 1) {
      appBuildNumber = parts[1].trim();
      appBuildDate = formatBuildDate(appBuildNumber);
    } else {
      appBuildNumber = '';
      appBuildDate = '';
    }

    if (appBuildDate.isNotEmpty) {
      versionDisplay = '$appVersion ($appBuildDate)';
    } else if (appBuildNumber.isNotEmpty) {
      versionDisplay = '$appVersion (build $appBuildNumber)';
    } else {
      versionDisplay = appVersion;
    }
  }

  /// Parses ecosystem `+YYMMDDNN` build numbers into human-readable date strings:
  /// `Nov 5, 2026 (rev 02)`.
  static String formatBuildDate(String build) {
    if (build.length < 6) return build;

    final int? yy = int.tryParse(build.substring(0, 2));
    final int? mm = int.tryParse(build.substring(2, 4));
    final int? dd = int.tryParse(build.substring(4, 6));

    if (yy == null || mm == null || dd == null) return build;

    final String nn = build.length >= 8 ? build.substring(6, 8) : '';
    const List<String> months = <String>[
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

    final String monthName = (mm >= 1 && mm <= 12) ? months[mm] : 'Month $mm';
    final int year = 2000 + yy;
    final String revSuffix = nn.isNotEmpty ? ' (rev $nn)' : '';

    return '$monthName $dd, $year$revSuffix';
  }

  /// Auto-detects GitHub owner and repository from repository/homepage URL.
  static void _parseGitHub(String url) {
    if (url.isEmpty) return;

    githubUrl = url;
    final RegExp regExp = RegExp(r'github\.com/([^/]+)/([^/#?]+)');
    final RegExpMatch? match = regExp.firstMatch(url);
    if (match != null) {
      githubOwner = match.group(1) ?? '';
      String repo = match.group(2) ?? '';
      if (repo.endsWith('.git')) {
        repo = repo.substring(0, repo.length - 4);
      }
      githubRepo = repo;
      M3xGitHub.defaultOwner = githubOwner;
      M3xGitHub.defaultRepo = githubRepo;
    }
  }

  static String _cleanYamlValue(String value) {
    String cleaned = value.trim();
    final int commentIdx = cleaned.indexOf(' #');
    if (commentIdx != -1) {
      cleaned = cleaned.substring(0, commentIdx).trim();
    }
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.trim();
  }

  /// Resets state (mainly used for testing).
  static void reset() {
    _initialized = false;
    appName = '';
    appDescription = '';
    appVersion = '';
    appBuildNumber = '';
    appBuildDate = '';
    versionDisplay = '';
    storageBoxName = '';
    M3xStorage.defaultBoxName = 'm3x_storage';
    githubOwner = '';
    githubRepo = '';
    githubUrl = null;
    M3xGitHub.defaultOwner = null;
    M3xGitHub.defaultRepo = null;
    appIconBytes = null;
    changelogContent = '';
    enableMesh = true;
    metadata.clear();
    dependencies.clear();
    SettingsBentoHeader.defaultDependencies = const <String, String>{};
    SettingsBentoHeader.defaultChangelogContent = '';
    SettingsBentoHeader.defaultVersionDisplay = '';
  }
}

/// Dynamic, read-only configuration accessor for [M3x].
class M3xConfig {
  const M3xConfig();

  String get appName => M3x.appName;
  String get appDescription => M3x.appDescription;
  String get appVersion => M3x.appVersion;
  String get appBuildNumber => M3x.appBuildNumber;
  String get appBuildDate => M3x.appBuildDate;
  String get versionDisplay => M3x.versionDisplay;
  String get storageBoxName => M3x.storageBoxName;
  String get githubOwner => M3x.githubOwner;
  String get githubRepo => M3x.githubRepo;
  String? get githubUrl => M3x.githubUrl;
  Uint8List? get appIconBytes => M3x.appIconBytes;
  String get changelogContent => M3x.changelogContent;
  bool get enableMesh => M3x.enableMesh;
  Map<String, String> get metadata => Map.unmodifiable(M3x.metadata);
  Map<String, String> get dependencies => Map.unmodifiable(M3x.dependencies);
}
