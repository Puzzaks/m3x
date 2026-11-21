import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:m3x_ui/m3x_ui.dart';
import '../engine.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<PlaygroundEngine>(
      builder: (context, engine, _) {
        final double latestCpu =
            engine.cpuHistory.isNotEmpty ? engine.cpuHistory.last : 0.35;
        final double latestRam =
            engine.ramHistory.isNotEmpty ? engine.ramHistory.last : 0.62;
        final double latestNet =
            engine.netHistory.isNotEmpty ? engine.netHistory.last : 0.40;
        final double latestPing = 42.0 + (latestCpu * 60.0);
        final double latestTemp = 41.0 + (latestCpu * 24.0);

        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              surfaceTintColor: Colors.transparent,
              pinned: true,
              title: const Text('Thinkpad.dev'),
              actions: [
                IconButton(
                  tooltip: 'Edit Server',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    engine.performHapticClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Server details editor triggered'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: MotionBlurContainer(
                enabled: engine.motionBlurEnabled,
                maxBlur: engine.motionBlurIntensity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // 1. PTK Uptime Header Card (matching Image 5)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: scheme.primary
                                            .withValues(alpha: 0.35),
                                        width: 1.5,
                                      ),
                                      color: scheme.primary
                                          .withValues(alpha: 0.10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.timer_outlined,
                                        size: 24,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          engine.dict.value('server_uptime'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                        Text(
                                          '9d 14:42:45',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 2. Overhauled Telemetry Cards (PTK Aesthetic matching Image 5)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: TelemetrySparklineCard(
                            title: engine.dict.value('ping'),
                            valueText: '${latestPing.toStringAsFixed(0)} ms',
                            history: engine.cpuHistory,
                            isOnline: true,
                            onTap: () {
                              engine.performHapticClick();
                              engine.logger.log('Dashboard', 'info', 'Tapped Ping card');
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: TelemetrySparklineCard(
                            title: engine.dict.value('cpu_load'),
                            valueText:
                                '${(latestCpu * 100).toStringAsFixed(1)}%',
                            history: engine.cpuHistory,
                            onTap: () {
                              engine.performHapticClick();
                              engine.logger.log('Dashboard', 'info', 'Tapped CPU Load card');
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: TelemetrySparklineCard(
                            title: engine.dict.value('temperature'),
                            valueText:
                                '${latestTemp.toStringAsFixed(1)} °C',
                            history: engine.cpuHistory,
                            onTap: () {
                              engine.performHapticClick();
                              engine.logger.log('Dashboard', 'info', 'Tapped Temperature card');
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: TelemetrySparklineCard(
                            title: engine.dict.value('ram_usage'),
                            valueText:
                                '${(latestRam * 11.34).toStringAsFixed(2)} GB / 11.34 GB',
                            subValue:
                                '${(latestRam * 100).toStringAsFixed(1)}%',
                            progress: latestRam,
                            history: engine.ramHistory,
                            onTap: () {
                              engine.performHapticClick();
                              engine.logger.log('Dashboard', 'info', 'Tapped RAM card');
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: TelemetrySparklineCard(
                            title: '${engine.dict.value('network')} (In)',
                            valueText:
                                '${(latestNet * 4.5).toStringAsFixed(2)} kB/s',
                            history: engine.netHistory,
                            onTap: () {
                              engine.performHapticClick();
                              engine.logger.log('Dashboard', 'info', 'Tapped Network card');
                            },
                          ),
                        ),

                        // 3. Sync Status Card
                        SyncStatusCard(
                          title: 'Contact & Cloud Sync',
                          statusText: engine.isSyncingContacts
                              ? 'Synchronizing telemetry snapshots...'
                              : 'Tap to trigger background sync animation',
                          isSyncing: engine.isSyncingContacts,
                          progress: engine.syncProgress,
                          onSyncTap: () {
                            engine.performHapticImpact();
                            engine.triggerSimulatedSync();
                          },
                        ),

                        // 4. Reorderable Servers List
                        Category.settings(
                          title: engine.dict.value('reorderable_cards'),
                          context: context,
                        ),
                        ReorderableCardGroup(
                          itemCount: engine.reorderableServers.length,
                          keyBuilder: (i) =>
                              ValueKey(engine.reorderableServers[i].id),
                          onReorder: (oldIdx, newIdx) {
                            engine.performHapticImpact();
                            engine.reorderServers(oldIdx, newIdx);
                          },
                          itemBuilder: (context, index) {
                            final srv = engine.reorderableServers[index];
                            return CardContents.tapIcon(
                              title: '${index + 1}. ${srv.name}',
                              subtitle: '${srv.status} • ${srv.url}',
                              icon: Icons.dns_rounded,
                              color: scheme.onSecondaryContainer,
                              colorBG: scheme.secondaryContainer,
                              action: () {
                                engine.performHapticClick();
                                engine.logger.log(
                                  'ReorderableCardGroup',
                                  'info',
                                  'Tapped server ${srv.name}',
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            );
      },
    );
  }
}
