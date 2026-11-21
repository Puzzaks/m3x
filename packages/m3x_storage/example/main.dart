import 'package:flutter/foundation.dart';
import 'package:m3x_dict/m3x_dict.dart';
import 'package:m3x_storage/m3x_storage.dart';

Future<void> main() async {
  final storage = M3xStorage.instance;
  await storage.init(boxName: 'm3x_storage_example');

  await storage.setBool('motion_blur', true);
  final enabled = storage.getBool('motion_blur', defaultValue: false);
  debugPrint('motion_blur: $enabled');

  final dict = Dictionary(
    path: 'assets/translations',
    storage: storage.asDictionaryStorage(),
  );
  debugPrint('Dictionary wired with Hive storage: ${dict.locale}');
}
