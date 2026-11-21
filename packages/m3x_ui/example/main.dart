// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:m3x_ui/m3x_ui.dart';

void main() {
  runApp(const M3xUiExampleApp());
}

class M3xUiExampleApp extends StatelessWidget {
  const M3xUiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const _SettingsPreview(),
    );
  }
}

class _SettingsPreview extends StatefulWidget {
  const _SettingsPreview();

  @override
  State<_SettingsPreview> createState() => _SettingsPreviewState();
}

class _SettingsPreviewState extends State<_SettingsPreview> {
  bool _motionBlur = true;

  @override
  Widget build(BuildContext context) {
    return SliverPageScaffold(
      title: 'Material 3 eXtended',
      children: [
        Category.settings(title: 'Appearance', context: context),
        context.cards.cardGroup([
          CardContents.tap(
            title: 'Dynamic Theme',
            subtitle: 'Material 3 eXtended (m3x) segmented card group',
            action: () {},
          ),
          CardContents.turn(
            title: 'Motion Blur',
            subtitle: 'Scroll-velocity GPU blur',
            value: _motionBlur,
            action: () => setState(() => _motionBlur = !_motionBlur),
            switcher: (v) => setState(() => _motionBlur = v),
          ),
        ]),
      ],
    );
  }
}
