import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:m3x_dict/m3x_dict.dart';
import 'package:m3x_storage/m3x_storage.dart';

void main() {
  late Directory tempDir;
  late M3xStorage storage;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('m3x_storage_test_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox<dynamic>('test_app_storage');
    storage = M3xStorage.instance;
    await storage.init(customBox: box);
  });

  tearDown(() async {
    await storage.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('M3xStorage Primitives', () {
    test('getString & setString', () async {
      expect(storage.getString('theme_mode'), isNull);
      expect(storage.getString('theme_mode', defaultValue: 'system'),
          equals('system'));

      await storage.setString('theme_mode', 'dark');
      expect(storage.getString('theme_mode'), equals('dark'));
    });

    test('getBool & setBool with string parsing support', () async {
      expect(storage.getBool('notifications_enabled'), isNull);
      expect(
          storage.getBool('notifications_enabled', defaultValue: true), isTrue);

      await storage.setBool('notifications_enabled', false);
      expect(storage.getBool('notifications_enabled'), isFalse);

      // Raw string 'true' / 'false' parsing
      await storage.set('flag_str', 'true');
      expect(storage.getBool('flag_str'), isTrue);
    });

    test('getInt & setInt', () async {
      expect(storage.getInt('login_count'), isNull);
      expect(storage.getInt('login_count', defaultValue: 0), equals(0));

      await storage.setInt('login_count', 42);
      expect(storage.getInt('login_count'), equals(42));
    });

    test('getDouble & setDouble', () async {
      expect(storage.getDouble('font_scale'), isNull);
      expect(storage.getDouble('font_scale', defaultValue: 1.0), equals(1.0));

      await storage.setDouble('font_scale', 1.25);
      expect(storage.getDouble('font_scale'), equals(1.25));
    });

    test('containsKey, remove, delete, clear, and getAll', () async {
      await storage.setString('k1', 'v1');
      await storage.setInt('k2', 200);

      expect(storage.containsKey('k1'), isTrue);
      expect(storage.containsKey('k2'), isTrue);
      expect(storage.containsKey('k3'), isFalse);

      final all = storage.getAll();
      expect(all['k1'], equals('v1'));
      expect(all['k2'], equals(200));

      await storage.remove('k1');
      expect(storage.containsKey('k1'), isFalse);

      await storage.delete('k2');
      expect(storage.containsKey('k2'), isFalse);

      await storage.setString('a', '1');
      await storage.setString('b', '2');
      await storage.clear();
      expect(storage.getAll(), isEmpty);
    });
  });

  group('M3xStorage Domain-Specific Chat Helpers', () {
    test('saveChatMessage, getChatMessages, clearChat', () async {
      const chatId = 'session_101';
      expect(storage.getChatMessages(chatId), isEmpty);

      await storage.saveChatMessage(chatId, {
        'id': 'msg_1',
        'role': 'user',
        'content': 'Hello, M3x!',
        'timestamp': 1700000000,
      });

      await storage.saveChatMessage(chatId, {
        'id': 'msg_2',
        'role': 'assistant',
        'content': 'Hello from agent mesh!',
        'timestamp': 1700000005,
      });

      final history = storage.getChatMessages(chatId);
      expect(history.length, equals(2));
      expect(history[0]['id'], equals('msg_1'));
      expect(history[0]['role'], equals('user'));
      expect(history[1]['content'], equals('Hello from agent mesh!'));

      await storage.clearChat(chatId);
      expect(storage.getChatMessages(chatId), isEmpty);
    });
  });

  group('M3xStorage asDictionaryStorage Adapter', () {
    test('DictionaryStorage bridge synchronizes with M3xStorage', () async {
      final dictStorage = storage.asDictionaryStorage();

      expect(dictStorage.get('language'), isNull);
      expect(dictStorage.containsKey('language'), isFalse);

      await dictStorage.put('language', 'uk');
      expect(dictStorage.get('language'), equals('uk'));
      expect(storage.getString('language'), equals('uk'));
      expect(dictStorage.containsKey('language'), isTrue);

      await dictStorage.delete('language');
      expect(dictStorage.containsKey('language'), isFalse);
      expect(storage.containsKey('language'), isFalse);
    });

    test('Dictionary reads language preference saved through M3xStorage',
        () async {
      await storage.setString('language', 'uk');

      final dict = Dictionary(
        path: 'assets/translations',
        storage: storage.asDictionaryStorage(),
      );

      await dict.decideLanguage();
      expect(dict.locale, equals('uk'));
    });
  });
}
