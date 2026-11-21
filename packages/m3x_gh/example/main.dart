// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:m3x_gh/m3x_gh.dart';

void main() {
  runApp(const M3xGhExampleApp());
}

class M3xGhExampleApp extends StatelessWidget {
  const M3xGhExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const M3xGitHubExplorerPage(
        initialOwner: 'Puzzaks',
        initialRepo: 'm3x',
      ),
    );
  }
}
