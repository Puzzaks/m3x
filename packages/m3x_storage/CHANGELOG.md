# Changelog

## 0.0.2

- Standardized documentation and metadata to Material 3 eXtended (m3x) branding with independence disclaimer.

## 0.0.1

- Initial release of `m3x_storage` opinionated Hive persistence middleware.
- Provides type-safe primitives (`getString`, `setString`, `getBool`, `setBool`, `getInt`, `setInt`, `getDouble`, `setDouble`, `remove`, `delete`, `containsKey`, `clear`, `getAll`).
- Implements domain-specific chat message caching (`saveChatMessage`, `getChatMessages`, `clearChat`).
- Implements `asDictionaryStorage()` zero-overhead adapter for `m3x_dict` localization.
