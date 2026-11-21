# m3x_storage

Opinionated **Hive persistence middleware** with type-safe primitive accessors, chat history persistence, and zero-overhead `DictionaryStorage` adapters for the [M3x](https://github.com/Puzzaks/m3x) ecosystem.

## Features

- **Type-Safe Primitive Accessors**: `getString`, `setString`, `getBool`, `setBool`, `getInt`, `setInt`, `getDouble`, `setDouble`, `remove`, `delete`, `containsKey`, `clear`, and `getAll`.
- **Automatic Box Naming**: Integrates with `M3x.init()` via `M3xStorage.defaultBoxName` (derived from `pubspec.yaml`).
- **Chat History Helpers**: Built-in `saveChatMessage`, `getChatMessages`, and `clearChat` helpers for AI/assistant apps.
- **`m3x_dict` Integration**: Call `storage.asDictionaryStorage()` to wire persistent Hive caching directly into `m3x_dict`'s `Dictionary` in one line.

## Usage

```dart
import 'package:m3x_storage/m3x_storage.dart';
import 'package:m3x_dict/m3x_dict.dart';

final storage = M3xStorage();
await storage.init();

await storage.setBool('motion_blur', true);
final enabled = storage.getBool('motion_blur', defaultValue: false);

// Wire directly into m3x_dict:
final dict = Dictionary(
  path: 'assets/translations',
  storage: storage.asDictionaryStorage(),
);
```

## License

Released into the public domain under [The Unlicense](LICENSE).
