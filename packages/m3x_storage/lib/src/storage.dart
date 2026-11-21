import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:m3x_dict/m3x_dict.dart';

/// Opinionated Hive persistence middleware for the M3x ecosystem.
///
/// Provides type-safe primitives, domain-specific chat message caching, and
/// zero-overhead [DictionaryStorage] integration for `m3x_dict`.
class M3xStorage {
  static final M3xStorage instance = M3xStorage._();
  factory M3xStorage() => instance;
  M3xStorage._();

  /// Default box name if omitted during [init].
  static String defaultBoxName = 'm3x_storage';

  Box<dynamic>? _box;
  String _boxName = '';

  /// Returns `true` once [init] has successfully opened the backing Hive box.
  bool get isInitialized => _box != null && _box!.isOpen;

  /// Returns the underlying Hive [Box]. Throws [StateError] if not initialized.
  Box<dynamic> get box {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError(
        'M3xStorage has not been initialized. Call await M3xStorage.instance.init() first.',
      );
    }
    return b;
  }

  /// Name of the currently opened box.
  String get boxName => _boxName;

  /// Initializes the storage engine.
  ///
  /// - [boxName]: Name of the Hive box to open. Defaults to [defaultBoxName] if omitted.
  /// - [customBox]: Optional pre-opened box (ideal for headless unit testing or in-memory mock boxes).
  /// - [storagePath]: Optional directory path for Hive initialization.
  Future<void> init({
    String? boxName,
    Box<dynamic>? customBox,
    String? storagePath,
  }) async {
    if (customBox != null) {
      _box = customBox;
      _boxName = customBox.name;
      return;
    }

    final effectiveBoxName =
        (boxName != null && boxName.isNotEmpty) ? boxName : defaultBoxName;

    if (storagePath != null && storagePath.isNotEmpty) {
      Hive.init(storagePath);
    } else {
      try {
        await Hive.initFlutter();
      } catch (_) {
        // Fallback for headless environments or unit tests
        try {
          Hive.init('.');
        } catch (_) {}
      }
    }

    _box = await Hive.openBox<dynamic>(effectiveBoxName);
    _boxName = effectiveBoxName;
  }

  // ==========================================
  // Primitive Accessors
  // ==========================================

  /// Retrieves a [String] value by [key], returning [defaultValue] if null or missing.
  String? getString(String key, {String? defaultValue}) {
    final val = box.get(key);
    if (val == null) return defaultValue;
    return val.toString();
  }

  /// Persists a [String] value under [key].
  Future<void> setString(String key, String value) => box.put(key, value);

  /// Retrieves a [bool] value by [key], returning [defaultValue] if null or missing.
  bool? getBool(String key, {bool? defaultValue}) {
    final val = box.get(key);
    if (val is bool) return val;
    if (val is String) {
      final lower = val.toLowerCase().trim();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return defaultValue;
  }

  /// Persists a [bool] value under [key].
  Future<void> setBool(String key, bool value) => box.put(key, value);

  /// Retrieves an [int] value by [key], returning [defaultValue] if null or missing.
  int? getInt(String key, {int? defaultValue}) {
    final val = box.get(key);
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  /// Persists an [int] value under [key].
  Future<void> setInt(String key, int value) => box.put(key, value);

  /// Retrieves a [double] value by [key], returning [defaultValue] if null or missing.
  double? getDouble(String key, {double? defaultValue}) {
    final val = box.get(key);
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  /// Persists a [double] value under [key].
  Future<void> setDouble(String key, double value) => box.put(key, value);

  /// Retrieves an arbitrary [dynamic] value by [key].
  dynamic get(String key, {dynamic defaultValue}) =>
      box.get(key, defaultValue: defaultValue);

  /// Persists an arbitrary [dynamic] value under [key].
  Future<void> set(String key, dynamic value) => box.put(key, value);

  /// Removes an entry by [key].
  Future<void> remove(String key) => box.delete(key);

  /// Alias for [remove].
  Future<void> delete(String key) => remove(key);

  /// Checks whether [key] exists in storage.
  bool containsKey(String key) => box.containsKey(key);

  /// Clears all entries in the current box.
  Future<void> clear() => box.clear();

  /// Returns an immutable map snapshot of all entries in the box.
  Map<String, dynamic> getAll() {
    final map = <String, dynamic>{};
    for (final key in box.keys) {
      map[key.toString()] = box.get(key);
    }
    return Map<String, dynamic>.unmodifiable(map);
  }

  // ==========================================
  // Domain-Specific Chat Helpers
  // ==========================================

  /// Appends a chat message to the history list for [chatId].
  Future<void> saveChatMessage(
      String chatId, Map<String, dynamic> message) async {
    final key = 'chat_$chatId';
    final existing = getChatMessages(chatId);
    final updated = List<Map<String, dynamic>>.from(existing)..add(message);
    await box.put(key, updated);
  }

  /// Retrieves the list of stored chat messages for [chatId].
  List<Map<String, dynamic>> getChatMessages(String chatId) {
    final key = 'chat_$chatId';
    final raw = box.get(key);
    if (raw is List) {
      return raw.map((item) {
        if (item is Map<String, dynamic>) return item;
        if (item is Map) return Map<String, dynamic>.from(item);
        return <String, dynamic>{'text': item.toString()};
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  /// Clears stored chat history for [chatId].
  Future<void> clearChat(String chatId) async {
    await box.delete('chat_$chatId');
  }

  // ==========================================
  // Localization Adapter
  // ==========================================

  /// Returns a [DictionaryStorage] adapter wrapping this [M3xStorage] instance
  /// for use with [Dictionary].
  DictionaryStorage asDictionaryStorage() {
    return CallbackDictionaryStorage(
      getFn: (key) => get(key),
      putFn: (key, val) => set(key, val),
      deleteFn: (key) => remove(key),
      containsKeyFn: (key) => containsKey(key),
    );
  }

  /// Closes the backing Hive box and resets internal state (useful for tests).
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = null;
    _boxName = '';
  }
}
