import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Abstract key-value storage interface for [Dictionary].
///
/// Decouples `m3x_dict` from any specific persistence plugin (such as Hive
/// or SharedPreferences) so that the dictionary works standalone in any
/// Dart/Flutter environment.
abstract class DictionaryStorage {
  /// Retrieves the value associated with [key], or `null` if not present.
  dynamic get(String key);

  /// Persists [value] under [key].
  Future<void> put(String key, dynamic value);

  /// Deletes the entry for [key].
  Future<void> delete(String key);

  /// Returns `true` if [key] exists in storage.
  bool containsKey(String key);
}

/// Default in-memory [DictionaryStorage] backed by a [Map].
///
/// Ideal for unit tests, web playgrounds, and apps that do not require
/// persistent disk caching before initialization.
class InMemoryDictionaryStorage implements DictionaryStorage {
  final Map<String, dynamic> _store;

  /// Creates an in-memory storage, optionally seeded with [initialData].
  InMemoryDictionaryStorage([Map<String, dynamic>? initialData])
      : _store = initialData != null
            ? Map<String, dynamic>.from(initialData)
            : <String, dynamic>{};

  /// Unmodifiable snapshot of all entries currently in memory.
  Map<String, dynamic> get entries => Map<String, dynamic>.unmodifiable(_store);

  @override
  dynamic get(String key) => _store[key];

  @override
  Future<void> put(String key, dynamic value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  bool containsKey(String key) => _store.containsKey(key);

  /// Clears all stored entries.
  void clear() => _store.clear();
}

/// Adapter that binds any external storage (e.g., `Hive.box('app_storage')`,
/// `Hive.box('paios_storage')`, or `SharedPreferences`) to [DictionaryStorage]
/// via callbacks without adding plugin dependencies to `m3x_dict`.
///
/// Example with Hive:
/// ```dart
/// final box = Hive.box('app_storage');
/// final storage = CallbackDictionaryStorage(
///   getFn: box.get,
///   putFn: box.put,
///   deleteFn: box.delete,
///   containsKeyFn: box.containsKey,
/// );
/// ```
class CallbackDictionaryStorage implements DictionaryStorage {
  /// Callback to read a value by key.
  final dynamic Function(String key) getFn;

  /// Callback to write a key-value pair.
  final FutureOr<void> Function(String key, dynamic value) putFn;

  /// Callback to remove a key.
  final FutureOr<void> Function(String key)? deleteFn;

  /// Callback to check whether a key exists.
  final bool Function(String key)? containsKeyFn;

  const CallbackDictionaryStorage({
    required this.getFn,
    required this.putFn,
    this.deleteFn,
    this.containsKeyFn,
  });

  @override
  dynamic get(String key) => getFn(key);

  @override
  Future<void> put(String key, dynamic value) async {
    await putFn(key, value);
  }

  @override
  Future<void> delete(String key) async {
    if (deleteFn != null) {
      await deleteFn!(key);
    }
  }

  @override
  bool containsKey(String key) {
    if (containsKeyFn != null) {
      return containsKeyFn!(key);
    }
    return getFn(key) != null;
  }
}

/// Standalone triple-tier JSON localization and dictionary manager.
///
/// Lookup & loading tiers during [setup]:
/// 1. **Tier 1 (Cache)**: Checks [storage] (`cached_languages_json`,
///    `cached_dict_<langId>`, and `cached_demo_dictionary_json`).
/// 2. **Tier 2 (Bundled Assets)**: Falls back to [rootBundle] assets at
///    `$path/languages.json`, `$path/<langId>.json`, and [demoDataPath].
/// 3. **Tier 3 (Remote HTTP Refresh)**: When [url] is non-empty (and either in
///    release/profile mode or [enableRemoteRefreshInDebug] is `true`), fetches
///    updated JSON files over HTTP with [httpTimeout] protection and updates
///    both in-memory maps and [storage].
class Dictionary {
  /// Currently active language code (e.g., `"en"`, `"uk"`).
  String locale = "en";

  /// Optional base URL for remote over-the-air translation updates.
  String url;

  /// Relative asset/remote directory path containing `languages.json` and
  /// `<langId>.json` files (e.g., `"assets/translations"`).
  String path;

  /// Optional asset/remote path to a structured demo data JSON file
  /// (e.g., `"assets/demo_dictionary.json"`).
  String? demoDataPath;

  /// Storage backend used to persist language selection and cached JSON.
  final DictionaryStorage storage;

  /// Loaded language dictionaries keyed by language code (`locale -> {key: val}`).
  Map<String, dynamic> dictionary = {};

  /// Loaded structured demo data map (queried via [data]).
  Map<String, dynamic> demoData = {};

  /// Available language descriptors loaded from `languages.json`
  /// (each entry typically `{"id": "en", "name": "English"}`).
  List<dynamic> languages = [];

  /// When `true`, wraps English fallback values in `!value!` and missing keys
  /// in `!!! key` to make untranslated strings immediately visible during development.
  bool debugHighlightFallbacks;

  /// When `true`, allows Tier 3 remote HTTP refresh to run even in `kDebugMode`.
  bool enableRemoteRefreshInDebug;

  /// Timeout applied to each remote HTTP request during Tier 3 refresh so slow
  /// networks or captive portals never hang app startup.
  Duration httpTimeout;

  /// Optional override for detecting the device/system language code (useful
  /// for testing and custom locale simulation).
  final String Function()? systemLocaleProvider;

  /// Optional callback invoked when background Tier 3 remote HTTP refresh
  /// completes and updates [dictionary] or [demoData].
  VoidCallback? onRemoteUpdated;

  Dictionary({
    this.url = "",
    required this.path,
    this.demoDataPath,
    DictionaryStorage? storage,
    this.httpTimeout = const Duration(seconds: 5),
    this.enableRemoteRefreshInDebug = false,
    this.debugHighlightFallbacks = kDebugMode,
    this.systemLocaleProvider,
    this.onRemoteUpdated,
  }) : storage = storage ?? InMemoryDictionaryStorage();

  /// Initializes the dictionary through the Stale-While-Revalidate (SWR) 3-tier
  /// loading pipeline:
  /// 1. Loads bundled assets (`$path/languages.json` and `$path/<langId>.json`)
  ///    and merges any persisted [storage] cache (`cached_languages_json`,
  ///    `cached_dict_<langId>`) on top so startup is instantaneous (`<10ms`)
  ///    and works 100% offline with cached strings.
  /// 2. Resolves active [locale] via [decideLanguage].
  /// 3. Triggers Tier 3 remote GitHub HTTP refresh silently in the background
  ///    when [backgroundRefresh] is `true` (default), invoking [onRemoteUpdated]
  ///    once remote translations arrive.
  Future<void> setup({bool backgroundRefresh = true}) async {
    // 1. Load languages list (Bundled Assets + Storage Cache merge)
    final List<dynamic> mergedLanguages = <dynamic>[];
    final Set<String> seenLangIds = <String>{};

    try {
      final String languagesContent =
          await rootBundle.loadString('$path/languages.json');
      final dynamic decoded = jsonDecode(languagesContent);
      if (decoded is List) {
        for (final dynamic item in decoded) {
          if (item is Map && item["id"] != null) {
            seenLangIds.add(item["id"].toString());
          }
          mergedLanguages.add(item);
        }
      }
    } catch (_) {
      // Fall through if bundled asset is missing.
    }

    final dynamic cachedLanguages = storage.get("cached_languages_json");
    if (cachedLanguages is String && cachedLanguages.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(cachedLanguages);
        if (decoded is List) {
          if (mergedLanguages.isEmpty) {
            mergedLanguages.addAll(decoded);
          } else {
            for (final dynamic item in decoded) {
              if (item is Map && item["id"] != null) {
                final String id = item["id"].toString();
                if (!seenLangIds.contains(id)) {
                  seenLangIds.add(id);
                  mergedLanguages.add(item);
                }
              }
            }
          }
        }
      } catch (_) {
        // Ignore corrupted cache.
      }
    }

    if (mergedLanguages.isNotEmpty) {
      languages = mergedLanguages;
    }

    // 2. Load each language dictionary (Bundled Asset baseline + Cached Hive overlay)
    for (final dynamic lang in languages) {
      if (lang is! Map || lang["id"] == null) continue;
      final String langId = lang["id"].toString();
      final Map<String, dynamic> mergedDict = <String, dynamic>{};

      try {
        final String content =
            await rootBundle.loadString('$path/$langId.json');
        final dynamic decoded = jsonDecode(content);
        if (decoded is Map) {
          mergedDict.addAll(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Ignore missing bundled asset (e.g. remote-only language).
      }

      final dynamic cachedDict = storage.get("cached_dict_$langId");
      if (cachedDict is String && cachedDict.isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(cachedDict);
          if (decoded is Map) {
            mergedDict.addAll(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // Ignore corrupted cached dictionary.
        }
      }

      if (mergedDict.isNotEmpty) {
        dictionary[langId] = mergedDict;
      }
    }

    // 3. Load optional demoDataPath (Bundled Asset baseline + Cached overlay)
    if (demoDataPath != null && demoDataPath!.isNotEmpty) {
      final Map<String, dynamic> mergedDemo = <String, dynamic>{};
      try {
        final String demoContent = await rootBundle.loadString(demoDataPath!);
        final dynamic decoded = jsonDecode(demoContent);
        if (decoded is Map) {
          mergedDemo.addAll(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Ignore missing demo data asset.
      }

      final dynamic cachedDemo = storage.get("cached_demo_dictionary_json");
      if (cachedDemo is String && cachedDemo.isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(cachedDemo);
          if (decoded is Map) {
            mergedDemo.addAll(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // Ignore corrupted cached demo data.
        }
      }

      if (mergedDemo.isNotEmpty) {
        demoData = mergedDemo;
      }
    }

    // 4. Decide active language immediately from local data
    await decideLanguage();

    // 5. Tier 3: Remote HTTP Refresh (non-blocking background by default)
    if (url.isNotEmpty && (!kDebugMode || enableRemoteRefreshInDebug)) {
      if (backgroundRefresh) {
        unawaited(refreshFromRemote());
      } else {
        await refreshFromRemote();
      }
    }
  }

  /// Triggers a Tier 3 remote translation refresh over HTTP with [httpTimeout]
  /// protection, fetching language files in parallel and merging on top of
  /// bundled strings.
  ///
  /// Updates in-memory [languages], [dictionary], and [demoData], persists
  /// raw JSON strings into [storage], and notifies [onRemoteUpdated].
  Future<void> refreshFromRemote() async {
    if (url.isEmpty) return;
    bool updatedAny = false;

    try {
      final Uri langUri = Uri.parse(_joinUrl(url, '$path/languages.json'));
      final http.Response langRes =
          await http.get(langUri).timeout(httpTimeout);
      if (langRes.statusCode == 200) {
        final String langBody = utf8.decode(langRes.bodyBytes);
        final dynamic decodedLangs = jsonDecode(langBody);
        if (decodedLangs is List) {
          languages = List<dynamic>.from(decodedLangs);
          await storage.put("cached_languages_json", langBody);
          updatedAny = true;

          final List<Future<void>> fetchTasks = <Future<void>>[];
          for (final dynamic lang in languages) {
            if (lang is! Map || lang["id"] == null) continue;
            final String langId = lang["id"].toString();
            fetchTasks.add(() async {
              try {
                final Uri dictUri =
                    Uri.parse(_joinUrl(url, '$path/$langId.json'));
                final http.Response res =
                    await http.get(dictUri).timeout(httpTimeout);
                if (res.statusCode == 200) {
                  final String dictBody = utf8.decode(res.bodyBytes);
                  final dynamic decodedDict = jsonDecode(dictBody);
                  if (decodedDict is Map) {
                    final Map<String, dynamic> current = dictionary[langId]
                            is Map
                        ? Map<String, dynamic>.from(dictionary[langId] as Map)
                        : <String, dynamic>{};
                    current.addAll(Map<String, dynamic>.from(decodedDict));
                    dictionary[langId] = current;
                    await storage.put("cached_dict_$langId", dictBody);
                    updatedAny = true;
                  }
                }
              } catch (_) {
                // Keep cached/bundled dictionary for this language on timeout/error.
              }
            }());
          }
          await Future.wait(fetchTasks);
        }
      }
    } catch (_) {
      // Keep cached/bundled languages on network error or timeout.
    }

    if (demoDataPath != null && demoDataPath!.isNotEmpty) {
      try {
        final Uri demoUri = Uri.parse(_joinUrl(url, demoDataPath!));
        final http.Response demoRes =
            await http.get(demoUri).timeout(httpTimeout);
        if (demoRes.statusCode == 200) {
          final String demoBody = utf8.decode(demoRes.bodyBytes);
          final dynamic decodedDemo = jsonDecode(demoBody);
          if (decodedDemo is Map) {
            demoData = Map<String, dynamic>.from(decodedDemo);
            await storage.put("cached_demo_dictionary_json", demoBody);
            updatedAny = true;
          }
        }
      } catch (_) {
        // Keep cached/bundled demoData on network error or timeout.
      }
    }

    if (updatedAny) {
      onRemoteUpdated?.call();
    }
  }

  /// Determines the active [locale] from [storage] if previously set by the
  /// user, or falls back to [setSystemLanguage].
  Future<void> decideLanguage() async {
    if (storage.containsKey("language")) {
      final dynamic saved = storage.get("language");
      if (saved is String && saved.isNotEmpty) {
        locale = saved;
        return;
      }
    }
    await setSystemLanguage();
  }

  /// Sets the active [locale] to [code] and persists it in [storage].
  Future<void> setLanguage(String code) async {
    locale = code;
    await storage.put("language", code);
  }

  /// Resets language preference to follow the system locale.
  ///
  /// 1. Deletes `"language"` from [storage] so resetting to system language
  ///    persists across app restarts.
  /// 2. Detects the system language code via [systemLocaleProvider] or
  ///    `PlatformDispatcher.instance.locale.languageCode` (safe on Web, mobile,
  ///    and desktop).
  /// 3. Matches against [languages]; if unsupported, safely falls back to `"en"`.
  Future<void> setSystemLanguage() async {
    await storage.delete("language");

    String sysCode = "en";
    try {
      final String rawCode = systemLocaleProvider?.call() ??
          PlatformDispatcher.instance.locale.languageCode;
      if (rawCode.isNotEmpty) {
        sysCode = rawCode;
      }
    } catch (_) {
      sysCode = "en";
    }

    final String normalizedCode = sysCode.split(RegExp(r'[-_]')).first;

    bool foundExact = false;
    bool foundNormalized = false;

    for (final dynamic element in languages) {
      if (element is Map && element["id"] != null) {
        final String id = element["id"].toString();
        if (id == sysCode) {
          foundExact = true;
          break;
        }
        if (id == normalizedCode) {
          foundNormalized = true;
        }
      }
    }

    if (foundExact) {
      locale = sysCode;
    } else if (foundNormalized) {
      locale = normalizedCode;
    } else {
      locale = "en";
    }
  }

  /// Looks up a localized string for [entry].
  ///
  /// - Returns `"Loading..."` if [locale] has not been loaded into [dictionary].
  /// - Returns the localized string if present in `dictionary[locale]`.
  /// - Falls back to `dictionary["en"][entry]` if present (wrapped in `!value!`
  ///   when [debugHighlightFallbacks] is `true`).
  /// - Otherwise returns `"!!! $entry"` when [debugHighlightFallbacks] is `true`,
  ///   or `entry` in release mode.
  String value(String entry) {
    if (!dictionary.containsKey(locale)) {
      return "Loading...";
    }
    final dynamic activeLocaleMap = dictionary[locale];
    if (activeLocaleMap is Map &&
        activeLocaleMap.containsKey(entry) &&
        activeLocaleMap[entry] != null) {
      return activeLocaleMap[entry].toString();
    }

    final dynamic enMap = dictionary["en"];
    if (enMap is Map && enMap.containsKey(entry) && enMap[entry] != null) {
      final String fallback = enMap[entry].toString();
      return debugHighlightFallbacks ? "!$fallback!" : fallback;
    }

    return debugHighlightFallbacks ? "!!! $entry" : entry;
  }

  /// Traverses [demoData] using dot-separated keys (and integer list indices),
  /// matching PTK's `dict.data('...')` helper.
  ///
  /// Example: `dict.data('router.interfaces.0.ip')`
  dynamic data(String dotPath) {
    if (dotPath.isEmpty) return demoData;
    final List<String> parts = dotPath.split('.');
    dynamic current = demoData;

    for (final String part in parts) {
      if (current == null) return null;
      if (current is Map) {
        if (current.containsKey(part)) {
          current = current[part];
        } else {
          return null;
        }
      } else if (current is List) {
        final int? index = int.tryParse(part);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  /// Returns the human-readable `"name"` of the active [locale] from
  /// [languages], or `locale.toUpperCase()` if not found.
  String get currentLanguageName {
    for (final dynamic element in languages) {
      if (element is Map &&
          element["id"]?.toString() == locale &&
          element["name"] != null) {
        return element["name"].toString();
      }
    }
    return locale.toUpperCase();
  }

  /// Returns `true` if the dictionary is currently following the system locale
  /// (i.e. no explicit `"language"` override is stored in [storage]).
  bool get isSystemLanguage => !storage.containsKey("language");

  static String _joinUrl(String base, String subPath) {
    final String cleanBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final String cleanSub =
        subPath.startsWith('/') ? subPath.substring(1) : subPath;
    return '$cleanBase/$cleanSub';
  }
}
