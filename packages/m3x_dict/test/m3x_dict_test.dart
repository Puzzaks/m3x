import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_dict/m3x_dict.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryDictionaryStorage & CallbackDictionaryStorage', () {
    test('InMemoryDictionaryStorage supports get, put, delete, containsKey, and clear', () async {
      final storage = InMemoryDictionaryStorage({'initial': 'value'});
      expect(storage.containsKey('initial'), isTrue);
      expect(storage.get('initial'), equals('value'));

      await storage.put('language', 'uk');
      expect(storage.containsKey('language'), isTrue);
      expect(storage.get('language'), equals('uk'));
      expect(storage.entries['language'], equals('uk'));

      await storage.delete('initial');
      expect(storage.containsKey('initial'), isFalse);
      expect(storage.get('initial'), isNull);

      storage.clear();
      expect(storage.entries, isEmpty);
    });

    test('CallbackDictionaryStorage delegates operations to provided callbacks', () async {
      final backingMap = <String, dynamic>{};
      final storage = CallbackDictionaryStorage(
        getFn: (key) => backingMap[key],
        putFn: (key, val) => backingMap[key] = val,
        deleteFn: (key) => backingMap.remove(key),
        containsKeyFn: (key) => backingMap.containsKey(key),
      );

      expect(storage.containsKey('k1'), isFalse);
      await storage.put('k1', 'v1');
      expect(storage.containsKey('k1'), isTrue);
      expect(storage.get('k1'), equals('v1'));

      await storage.delete('k1');
      expect(storage.containsKey('k1'), isFalse);
    });
  });

  group('Dictionary initialization, lookup, and fallbacks', () {
    late InMemoryDictionaryStorage storage;

    setUp(() {
      storage = InMemoryDictionaryStorage({
        'cached_languages_json': jsonEncode([
          {'id': 'en', 'name': 'English', 'origin': 'English'},
          {'id': 'uk', 'name': 'Ukrainian', 'origin': 'Українська'},
        ]),
        'cached_dict_en': jsonEncode({
          'app_title': 'Puzzak Playground',
          'only_in_english': 'Fallback String',
        }),
        'cached_dict_uk': jsonEncode({
          'app_title': 'Майданчик Puzzak',
        }),
        'cached_demo_dictionary_json': jsonEncode({
          'servers': [
            {'name': 'Kyiv Edge', 'ping': 12},
            {'name': 'Frankfurt Core', 'ping': 34},
          ],
          'meta': {'version': 2},
        }),
      });
    });

    test('setup() loads cached languages, dictionaries, and demoData', () async {
      final dict = Dictionary(
        path: 'assets/non_existent_test_path',
        demoDataPath: 'assets/non_existent_demo.json',
        storage: storage,
        systemLocaleProvider: () => 'en',
        debugHighlightFallbacks: false,
      );

      await dict.setup(backgroundRefresh: false);

      expect(dict.languages.length, equals(2));
      expect(dict.locale, equals('en'));
      expect(dict.currentLanguageName, equals('English'));
      expect(dict.isSystemLanguage, isTrue);
      expect(dict.value('app_title'), equals('Puzzak Playground'));
      expect(dict.data('servers.0.name'), equals('Kyiv Edge'));
      expect(dict.data('servers.1.ping'), equals(34));
      expect(dict.data('meta.version'), equals(2));
      expect(dict.data('servers.99.name'), isNull);
      expect(dict.data('invalid.path'), isNull);
    });

    test('value(key) falls back to English and key name in release and debug modes', () async {
      final dictRelease = Dictionary(
        path: 'assets/non_existent_test_path',
        storage: storage,
        systemLocaleProvider: () => 'uk',
        debugHighlightFallbacks: false,
      );
      await dictRelease.setup(backgroundRefresh: false);

      expect(dictRelease.locale, equals('uk'));
      expect(dictRelease.value('app_title'), equals('Майданчик Puzzak'));
      expect(dictRelease.value('only_in_english'), equals('Fallback String'));
      expect(dictRelease.value('completely_missing_key'), equals('completely_missing_key'));

      final dictDebug = Dictionary(
        path: 'assets/non_existent_test_path',
        storage: storage,
        systemLocaleProvider: () => 'uk',
        debugHighlightFallbacks: true,
      );
      await dictDebug.setup(backgroundRefresh: false);

      expect(dictDebug.value('app_title'), equals('Майданчик Puzzak'));
      expect(dictDebug.value('only_in_english'), equals('!Fallback String!'));
      expect(dictDebug.value('completely_missing_key'), equals('!!! completely_missing_key'));
    });

    test('value(key) returns Loading... before dictionary is initialized for active locale', () {
      final uninitializedDict = Dictionary(path: 'assets/translations');
      expect(uninitializedDict.value('any_key'), equals('Loading...'));
    });

    test('language switching persists to storage and setSystemLanguage resets to OS locale', () async {
      final dict = Dictionary(
        path: 'assets/non_existent_test_path',
        storage: storage,
        systemLocaleProvider: () => 'uk_UA',
        debugHighlightFallbacks: false,
      );
      await dict.setup(backgroundRefresh: false);

      // Normalized 'uk_UA' -> 'uk'
      expect(dict.locale, equals('uk'));
      expect(dict.isSystemLanguage, isTrue);

      // Switch explicitly to 'en'
      await dict.setLanguage('en');
      expect(dict.locale, equals('en'));
      expect(dict.isSystemLanguage, isFalse);
      expect(storage.get('language'), equals('en'));
      expect(dict.value('app_title'), equals('Puzzak Playground'));

      // New Dictionary instance should restore saved 'en' preference over system 'uk_UA'
      final restoredDict = Dictionary(
        path: 'assets/non_existent_test_path',
        storage: storage,
        systemLocaleProvider: () => 'uk_UA',
      );
      await restoredDict.setup(backgroundRefresh: false);
      expect(restoredDict.locale, equals('en'));
      expect(restoredDict.isSystemLanguage, isFalse);

      // Reset to system language deletes 'language' key and resolves 'uk'
      await restoredDict.setSystemLanguage();
      expect(restoredDict.locale, equals('uk'));
      expect(restoredDict.isSystemLanguage, isTrue);
      expect(storage.containsKey('language'), isFalse);
    });

    test('setSystemLanguage falls back to en when system locale is unsupported', () async {
      final dict = Dictionary(
        path: 'assets/non_existent_test_path',
        storage: storage,
        systemLocaleProvider: () => 'fr_FR',
      );
      await dict.setup(backgroundRefresh: false);
      expect(dict.locale, equals('en'));
    });
  });

  group('Remote HTTP fetch and timeout handling', () {
    setUp(() {
      HttpOverrides.global = null;
    });

    test('refreshFromRemote handles slow/hanging servers within httpTimeout without throwing', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((HttpRequest request) async {
        // Delay longer than the Dictionary's httpTimeout
        await Future<void>.delayed(const Duration(milliseconds: 400));
        try {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('[]');
          await request.response.close();
        } catch (_) {}
      });

      final storage = InMemoryDictionaryStorage({
        'cached_languages_json': jsonEncode([
          {'id': 'en', 'name': 'English'},
        ]),
        'cached_dict_en': jsonEncode({'hello': 'Cached Hello'}),
      });

      bool remoteUpdatedCalled = false;
      final dict = Dictionary(
        url: 'http://${server.address.host}:${server.port}',
        path: 'translations',
        storage: storage,
        httpTimeout: const Duration(milliseconds: 60),
        enableRemoteRefreshInDebug: true,
        debugHighlightFallbacks: false,
        onRemoteUpdated: () => remoteUpdatedCalled = true,
      );

      final stopwatch = Stopwatch()..start();
      await dict.setup(backgroundRefresh: false);
      stopwatch.stop();

      // Should time out quickly and preserve cached strings
      expect(stopwatch.elapsedMilliseconds, lessThan(350));
      expect(remoteUpdatedCalled, isFalse);
      expect(dict.value('hello'), equals('Cached Hello'));
    });

    test('refreshFromRemote fetches, merges, and persists remote translations', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));

      server.listen((HttpRequest request) async {
        final path = request.uri.path;
        request.response.headers.contentType = ContentType.json;
        if (path.endsWith('/translations/languages.json')) {
          request.response.write(jsonEncode([
            {'id': 'en', 'name': 'English'},
            {'id': 'uk', 'name': 'Ukrainian'},
          ]));
        } else if (path.endsWith('/translations/en.json')) {
          request.response.write(jsonEncode({
            'hello': 'Remote Hello',
            'new_remote_key': 'Added OTA',
          }));
        } else if (path.endsWith('/translations/uk.json')) {
          request.response.write(jsonEncode({
            'hello': 'Привіт з сервера',
          }));
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });

      final storage = InMemoryDictionaryStorage({
        'cached_languages_json': jsonEncode([
          {'id': 'en', 'name': 'English'},
        ]),
        'cached_dict_en': jsonEncode({
          'hello': 'Local Hello',
          'local_only': 'Kept Local',
        }),
      });

      int updateNotifications = 0;
      final dict = Dictionary(
        url: 'http://${server.address.host}:${server.port}',
        path: 'translations',
        storage: storage,
        httpTimeout: const Duration(seconds: 2),
        enableRemoteRefreshInDebug: true,
        debugHighlightFallbacks: false,
        systemLocaleProvider: () => 'en',
        onRemoteUpdated: () => updateNotifications++,
      );

      await dict.setup(backgroundRefresh: false);

      expect(updateNotifications, equals(1));
      expect(dict.value('hello'), equals('Remote Hello'));
      expect(dict.value('new_remote_key'), equals('Added OTA'));
      expect(dict.value('local_only'), equals('Kept Local'));

      await dict.setLanguage('uk');
      expect(dict.value('hello'), equals('Привіт з сервера'));
      expect(storage.containsKey('cached_dict_uk'), isTrue);
    });
  });
}
