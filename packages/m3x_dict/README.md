# m3x_dict

Standalone triple-tier JSON localization and dictionary manager (local cache, bundled assets, and background remote HTTP refresh) for the [M3x](https://github.com/Puzzaks/m3x) Flutter ecosystem.

Completely decoupled from UI widgets and specific persistence plugins, `m3x_dict` delivers instant (`<10ms`) offline-first startup with Stale-While-Revalidate (SWR) over-the-air translation updates.

## 3-Tier Loading & Lookup Architecture

When `await dict.setup()` runs, translations and optional structured data are resolved through three tiers:

1. **Tier 1 — Bundled Assets (`rootBundle`)**:
   Loads `$path/languages.json`, `$path/<langId>.json`, and optional `demoDataPath` immediately from app assets.
2. **Tier 2 — Local Cache Overlay (`DictionaryStorage`)**:
   Merges persisted `cached_languages_json`, `cached_dict_<langId>`, and `cached_demo_dictionary_json` on top of bundled defaults so previously downloaded OTA strings work 100% offline.
3. **Tier 3 — Remote HTTP Refresh (`http` with timeout protection)**:
   When `url` is non-empty (and either in release/profile mode or `enableRemoteRefreshInDebug: true`), fetches updated JSON files in parallel with `httpTimeout` (default `5s`) and invokes `onRemoteUpdated`.

### String Lookup (`dict.value(key)`)
- Returns `"Loading..."` if the active `locale` has not been loaded yet.
- Returns `dictionary[locale][key]` if present.
- Falls back to `dictionary["en"][key]` (wrapped as `!value!` when `debugHighlightFallbacks` is `true`).
- Falls back to `"!!! key"` (when `debugHighlightFallbacks` is `true`) or `key` (in release mode) if missing in both locales.

## Usage

```dart
import 'package:m3x_dict/m3x_dict.dart';

final dict = Dictionary(
  url: 'https://raw.githubusercontent.com/org/repo/main',
  path: 'assets/translations',
  demoDataPath: 'assets/data/demo_dictionary.json',
  onRemoteUpdated: () => notifyListeners(),
);

await dict.setup();

print(dict.value('app_title'));
print(dict.data('router.interfaces.0.ip'));
```

## Storage Adapters

- **`InMemoryDictionaryStorage`** (default): Ephemeral in-memory map for unit tests and playgrounds.
- **`CallbackDictionaryStorage`**: Binds any external key-value store (`Hive`, `SharedPreferences`, `m3x_storage`) without coupling `m3x_dict` to a persistence plugin.

## License

Released into the public domain under [The Unlicense](LICENSE).
