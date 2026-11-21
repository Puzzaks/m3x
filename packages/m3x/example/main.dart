// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:m3x/m3x.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await M3x.init();

  runApp(const M3xUmbrellaExampleApp());
}

class M3xUmbrellaExampleApp extends StatelessWidget {
  const M3xUmbrellaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: SliverPageScaffold(
        title: M3x.config.appName,
        children: [
          Category.settings(title: 'App Metadata', context: context),
          context.cards.cardGroup([
            CardContents.static(
              title: 'Version',
              subtitle: M3x.config.versionDisplay,
            ),
            CardContents.static(
              title: 'Storage Box',
              subtitle: M3x.config.storageBoxName,
            ),
          ]),
        ],
      ),
    );
  }
}
