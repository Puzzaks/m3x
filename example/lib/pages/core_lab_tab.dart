import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:m3x_core/m3x_core.dart';
import 'package:m3x_ui/m3x_ui.dart';
import '../engine.dart';

class CoreLabTab extends StatelessWidget {
  const CoreLabTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<PlaygroundEngine>(
      builder: (context, engine, _) {
        final dict = engine.dict;

        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              surfaceTintColor: Colors.transparent,
              pinned: true,
              title: Text(dict.value('tab_core_lab')),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Standalone Dictionary (puzzak_dict) Inspector
                  Category.settings(
                    title: dict.value('dict_inspector'),
                    context: context,
                  ),
                  context.cards.cardGroup([
                    CardContents.doubleTap(
                      title: 'Active Locale: ${dict.currentLanguageName} (${dict.locale})',
                      subtitle: dict.isSystemLanguage
                          ? 'Mode: Following OS System Language (with safe "en" fallback)'
                          : 'Mode: Explicit User Override ("language" key saved in storage)',
                      icon: Icons.restore_rounded,
                      secondTooltip: 'Reset to system language',
                      action: () {
                        final String nextLang = dict.locale == 'en' ? 'uk' : 'en';
                        engine.selectLanguage(nextLang);
                      },
                      secondAction: engine.resetToSystemLanguage,
                    ),
                    CardContents.turn(
                      title: 'Debug Fallback Markers (!fallback! & !!! key)',
                      subtitle:
                          'Wraps English fallbacks in !...! and missing keys in !!!',
                      value: dict.debugHighlightFallbacks,
                      action: () => engine.toggleDebugFallbackHighlights(
                        !dict.debugHighlightFallbacks,
                      ),
                      switcher: engine.toggleDebugFallbackHighlights,
                    ),
                    CardContents.static(
                      title: 'dict.value("app_name") [Present in EN & UK]',
                      subtitle: '→ ${dict.value('app_name')}',
                    ),
                    CardContents.static(
                      title: 'dict.value("only_in_english_demo") [Missing in UK]',
                      subtitle: '→ ${dict.value('only_in_english_demo')}',
                    ),
                    CardContents.static(
                      title: 'dict.value("missing_key_404") [In neither JSON]',
                      subtitle: '→ ${dict.value('missing_key_404')}',
                    ),
                    CardContents.static(
                      title: 'dict.data("ecosystem.packages.0.name") [Dot-Path Traversal]',
                      subtitle:
                          '→ ${dict.data('ecosystem.packages.0.name')} (${dict.data('ecosystem.packages.0.role')})',
                    ),
                  ]),
                  TextPart.infoShort(
                    title:
                        'Switch to Ukrainian (UK) above to see "only_in_english_demo" automatically fall back to English with "!...!" debug markers.',
                    subtitle: '',
                    action: () {},
                    context: context,
                  ),

                  // 2. Byte & Duration Formatters Lab (puzzak_core)
                  Category.settings(
                    title: dict.value('formatters_lab'),
                    context: context,
                  ),
                  context.cards.cardGroup([
                    CardContents.turn(
                      title: 'Display in Bits (bps / Mbps) instead of Bytes',
                      subtitle: 'Matches PTK useBits preference',
                      value: engine.formatInBits,
                      action: () {
                        engine.formatInBits = !engine.formatInBits;
                        engine.genericRefresh();
                      },
                      switcher: (v) {
                        engine.formatInBits = v;
                        engine.genericRefresh();
                      },
                    ),
                    CardContents.static(
                      title: 'PuzzakFormatters.formatBytes(${engine.sampleBytes.round()})',
                      subtitle:
                          'Throughput: ${PuzzakFormatters.formatBytes(engine.sampleBytes, isThroughput: true, useBits: engine.formatInBits)}  •  Volume: ${PuzzakFormatters.formatBytes(engine.sampleBytes, isThroughput: false, useBits: engine.formatInBits)}',
                    ),
                    CardContents.static(
                      title:
                          'PuzzakFormatters.formatDuration(${engine.sampleDurationSeconds}s)',
                      subtitle:
                          'Full: ${PuzzakFormatters.formatDuration(Duration(seconds: engine.sampleDurationSeconds))}  •  Short: ${PuzzakFormatters.formatDuration(Duration(seconds: engine.sampleDurationSeconds), includeSeconds: false)}',
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Text('Sample Size:'),
                        Expanded(
                          child: Slider(
                            value: engine.sampleBytes,
                            min: 512,
                            max: 1073741824,
                            onChanged: (v) {
                              engine.sampleBytes = v;
                              engine.genericRefresh();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. AnalyticsService Deduplicating Logger & LogViewerList
                  Category.settings(
                    title:
                        '${dict.value('logger_inspector')} (${engine.logger.logs.length} entries)',
                    context: context,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => engine.logger.log(
                            'PollingWorker',
                            'info',
                            'Heartbeat check OK (deduplicated if clicked repeatedly)',
                          ),
                          icon: const Icon(Icons.repeat_rounded, size: 18),
                          label: const Text('Spam Identical Log (Test Deduplication)'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => engine.logger.log(
                            'Network',
                            'warning',
                            'High latency detected on Lviv Backup NAS (184 ms)',
                          ),
                          icon: Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Colors.amber.shade700,
                          ),
                          label: const Text('Log Warning'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => engine.logger.log(
                            'Parser',
                            'error',
                            'Simulated HTTP 502 Bad Gateway from remote endpoint',
                          ),
                          icon: Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: scheme.error,
                          ),
                          label: const Text('Log Error'),
                        ),
                        TextButton.icon(
                          onPressed: engine.logger.clearLogs,
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Card(
                      color: scheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: LogViewerList(
                          logs: engine.logger.logs,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
