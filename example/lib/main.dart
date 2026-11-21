import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:m3x/m3x.dart';

import 'engine.dart';
import 'pages/complications_tab.dart';
import 'pages/dashboard_tab.dart';
import 'pages/elements_tab.dart';
import 'pages/settings_tab.dart';

final PlaygroundEngine playgroundEngine = PlaygroundEngine();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider<PlaygroundEngine>.value(
      value: playgroundEngine,
      child: const PuzzakPlaygroundApp(),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> m3xMeshMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await playgroundEngine.startHeadlessForMesh();
}

class PuzzakPlaygroundApp extends StatefulWidget {
  const PuzzakPlaygroundApp({super.key});

  @override
  State<PuzzakPlaygroundApp> createState() => _PuzzakPlaygroundAppState();
}

class _PuzzakPlaygroundAppState extends State<PuzzakPlaygroundApp> {
  @override
  void initState() {
    super.initState();
    playgroundEngine.start();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaygroundEngine>(
      builder: (context, engine, _) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final ThemeData lightTheme = PuzzakTheme.buildTheme(
              brightness: Brightness.light,
              seedColor: engine.seedColor,
              dynamicScheme: engine.useDynamicColor ? lightDynamic : null,
            );
            final ThemeData darkTheme = PuzzakTheme.buildTheme(
              brightness: Brightness.dark,
              seedColor: engine.seedColor,
              dynamicScheme: engine.useDynamicColor ? darkDynamic : null,
            );

            return MaterialApp(
              title: 'Puzzak UI Playground',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: engine.themeMode,
              home: StartupCrossFadeShell(
                appStarted: engine.appStarted,
                child: const PlaygroundHomeShell(),
              ),
            );
          },
        );
      },
    );
  }
}

class PlaygroundHomeShell extends StatelessWidget {
  const PlaygroundHomeShell({super.key});

  static const List<({Color color, String name})> _seedPresets = [
    (color: Colors.teal, name: 'Teal (Default)'),
    (color: Colors.indigo, name: 'Indigo'),
    (color: Colors.deepOrange, name: 'Orange'),
    (color: Colors.green, name: 'Emerald'),
    (color: Colors.purple, name: 'Purple'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<PlaygroundEngine>(
      builder: (context, engine, _) {
        final List<Widget> tabBodies = const [
          DashboardTab(),
          ElementsTab(),
          SettingsTab(),
          ComplicationsTab(),
        ];

        Widget activeBody = tabBodies[engine.selectedTab];

        // If user selected a simulated viewport width, constrain and frame the canvas
        if (engine.simulatedViewportWidth != null) {
          activeBody = Container(
            color: scheme.surfaceContainerLowest,
            alignment: Alignment.topCenter,
            child: Container(
              width: engine.simulatedViewportWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: scheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
              ),
              child: activeBody,
            ),
          );
        }

        return AdaptiveNavScaffold(
          selectedIndex: engine.selectedTab,
          onDestinationSelected: (idx) {
            engine.performHapticImpact();
            engine.setSelectedTab(idx);
          },
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Material(
              color: scheme.surfaceContainer,
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        engine.dict.value('app_name'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Theme Mode Quick Toggle
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded, size: 16),
                          ),
                        ],
                        selected: {engine.themeMode},
                        onSelectionChanged: (s) {
                          engine.performHapticClick();
                          engine.setThemeMode(s.first);
                        },
                      ),
                      const SizedBox(width: 12),

                      // Dynamic System Color Option
                      ChoiceChip(
                        avatar: Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: engine.useDynamicColor ? scheme.onPrimaryContainer : null,
                        ),
                        label: const Text('System Dynamic', style: TextStyle(fontSize: 12)),
                        selected: engine.useDynamicColor,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => engine.setUseDynamicColor(true),
                      ),
                      const SizedBox(width: 8),

                      // Preset Seed Color Swatches
                      for (final preset in _seedPresets)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () {
                              engine.performHapticClick();
                              engine.setSeedColor(preset.color, preset.name);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: preset.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (!engine.useDynamicColor &&
                                          engine.seedColor == preset.color)
                                      ? scheme.onSurface
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),

                      // Viewport Width Simulator Chips (Foldable & Mobile Testing)
                      ChoiceChip(
                        label: const Text('Full Width', style: TextStyle(fontSize: 12)),
                        selected: engine.simulatedViewportWidth == null,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          engine.performHapticClick();
                          engine.setSimulatedViewportWidth(null);
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('360px Mobile', style: TextStyle(fontSize: 12)),
                        selected: engine.simulatedViewportWidth == 360,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          engine.performHapticClick();
                          engine.setSimulatedViewportWidth(360);
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('600px Foldable', style: TextStyle(fontSize: 12)),
                        selected: engine.simulatedViewportWidth == 600,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          engine.performHapticClick();
                          engine.setSimulatedViewportWidth(600);
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('840px Tablet', style: TextStyle(fontSize: 12)),
                        selected: engine.simulatedViewportWidth == 840,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          engine.performHapticClick();
                          engine.setSimulatedViewportWidth(840);
                        },
                      ),
                      const SizedBox(width: 12),

                      // Language Toggle Chip
                      ActionChip(
                        avatar: const Icon(Icons.language_rounded, size: 16),
                        label: Text(
                          engine.dict.locale.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          engine.performHapticImpact();
                          final next = engine.dict.locale == 'en' ? 'uk' : 'en';
                          engine.selectLanguage(next);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Desktop Side-Panel Log Toggle
                      IconButton(
                        tooltip: 'Toggle Desktop Live Log Side-Panel',
                        icon: Icon(
                          engine.showDesktopLogPanel
                              ? Icons.dock_rounded
                              : Icons.terminal_rounded,
                          size: 20,
                        ),
                        onPressed: () {
                          engine.performHapticClick();
                          engine.toggleDesktopLogPanel();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          destinations: [
            AdaptiveNavDestination(
              icon: Icons.dns_outlined,
              selectedIcon: Icons.dns_rounded,
              label: engine.dict.value('tab_dashboard'),
            ),
            AdaptiveNavDestination(
              icon: Icons.widgets_outlined,
              selectedIcon: Icons.widgets_rounded,
              label: engine.dict.value('tab_elements'),
            ),
            AdaptiveNavDestination(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: engine.dict.value('tab_settings'),
            ),
            AdaptiveNavDestination(
              icon: Icons.science_outlined,
              selectedIcon: Icons.science_rounded,
              label: engine.dict.value('tab_complications'),
              badgeLabel: '${engine.logger.logs.length}',
            ),
          ],
          sidePanel: engine.showDesktopLogPanel
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Telemetry & Event Log',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: scheme.primary,
                                    ),
                          ),
                          IconButton(
                            tooltip: 'Clear Logs',
                            icon: const Icon(
                              Icons.delete_sweep_rounded,
                              size: 18,
                            ),
                            onPressed: () {
                              engine.performHapticImpact();
                              engine.logger.clearLogs();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        child: LogViewerList(
                          logs: engine.logger.logs,
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          body: activeBody,
        );
      },
    );
  }
}
