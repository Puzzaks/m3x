import 'package:flutter/foundation.dart';
import 'package:m3x_dict/m3x_dict.dart';

Future<void> main() async {
  final storage = InMemoryDictionaryStorage();
  final dict = Dictionary(
    path: 'assets/translations',
    storage: storage,
    onRemoteUpdated: () {
      debugPrint('Remote translations refreshed.');
    },
  );

  // Example lookup API (call `await dict.setup()` after binding Flutter assets):
  debugPrint('Current locale: ${dict.locale}');
  debugPrint('Sample lookup: ${dict.value('app_title')}');
}
