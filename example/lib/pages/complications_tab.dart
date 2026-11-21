import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:m3x_chat/m3x_chat.dart';
import 'package:m3x_core/m3x_core.dart';
import 'package:m3x_ui/m3x_ui.dart';
import '../engine.dart';
import 'adaptive_layouts_demo.dart';
import 'agentic_mesh_lab.dart';

class ComplicationsTab extends StatefulWidget {
  const ComplicationsTab({super.key});

  @override
  State<ComplicationsTab> createState() => _ComplicationsTabState();
}

class _ComplicationsTabState extends State<ComplicationsTab> {
  final TextEditingController _chatCtrl = TextEditingController();

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }

  void _openFullScreenSliverPage(BuildContext context, PlaygroundEngine engine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'DemoSliverSettingsPage'),
        builder: (pageCtx) => SliverPageScaffold(
          title: 'SliverPageScaffold Demo',
          maxContentWidth: 720,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(pageCtx).pop(),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Done'),
          ),
          children: [
            Category.settings(
              title: 'Responsive Max-Width (720px) + SliverAppBar.large',
              context: pageCtx,
            ),
            pageCtx.cards.cardGroup([
              CardContents.tapIcon(
                title: 'Collapsible Material 3 Header',
                subtitle:
                    'Scroll down to collapse SliverAppBar.large into pinned AppBar',
                icon: Icons.view_day_rounded,
                color: Theme.of(pageCtx).colorScheme.onPrimaryContainer,
                colorBG: Theme.of(pageCtx).colorScheme.primaryContainer,
                action: () {},
              ),
              CardContents.static(
                title: 'Centered Tablet / Desktop Constraint',
                subtitle:
                    'Uses maxContentWidth: 720 so cards never stretch edge-to-edge on wide screens.',
              ),
              CardContents.tap(
                title: 'Pop Back to Playground',
                subtitle: 'Tap here or the top-left arrow_back_rounded button',
                action: () => Navigator.of(pageCtx).pop(),
              ),
            ]),
            TextPart.info(
              title:
                  'SliverPageScaffold standardizes the boilerplate used across PTK, geminilocal, and the2k48.',
              subtitle: 'Close preview',
              action: () => Navigator.of(pageCtx).pop(),
              context: pageCtx,
            ),
          ],
        ),
      ),
    );
  }

  void _openOnboardingWizard(BuildContext context, PlaygroundEngine engine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'DemoOnboardingWizard'),
        builder: (wizardCtx) => OnboardingWizard(
          onFinish: () {
            engine.logger.log('OnboardingWizard', 'info', 'Completed OnboardingWizard');
            Navigator.of(wizardCtx).pop();
          },
          slides: const [
            OnboardingSlideData(
              icon: Icons.auto_awesome_mosaic_rounded,
              icons: [
                Icons.widgets_rounded,
                Icons.palette_rounded,
                Icons.bolt_rounded,
              ],
              title: 'Welcome to Puzzak UI',
              description:
                  'A unified Material 3 Expressive component suite extracted from PTK, PAIOS (geminilocal), the2k48, Website, ggscanus, and binotool.',
            ),
            OnboardingSlideData(
              icon: Icons.speed_rounded,
              title: 'Telemetry & Background Monitoring',
              description:
                  'High-performance live monitoring cards, subtle wave charts, and deduplicating logging engine.',
            ),
            OnboardingSlideData(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'AI Chat & Markdown Bubbles',
              description:
                  'Streaming chat complication with selectable markdown, code highlighting, and safe external link handling.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<PlaygroundEngine>(
      builder: (context, engine, _) {
        final double latestCpu =
            engine.cpuHistory.isNotEmpty ? engine.cpuHistory.last : 0.35;
        final double latestRam =
            engine.ramHistory.isNotEmpty ? engine.ramHistory.last : 0.62;

        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              surfaceTintColor: Colors.transparent,
              pinned: true,
              title: Text(engine.dict.value('tab_complications')),
            ),
            SliverToBoxAdapter(
              child: MotionBlurContainer(
                enabled: engine.motionBlurEnabled,
                maxBlur: engine.motionBlurIntensity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Chat UI Complication
                    Category.settings(
                      title: engine.dict.value('chat_complication'),
                      context: context,
                    ),
                    context.cards.cardGroup([
                      CardContents.turn(
                        title: 'Show Chat Avatars',
                        subtitle:
                            'Toggle CircleAvatar badges beside bubbles (tap any bubble to reveal author & timestamp)',
                        value: engine.showChatAvatars,
                        action: () {
                          engine.toggleShowChatAvatars(!engine.showChatAvatars);
                        },
                        switcher: (v) => engine.toggleShowChatAvatars(v),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Card(
                        color: scheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ChatBubbleList(
                                messages: engine.chatMessages,
                                streamingAiChunk: engine.streamingAiChunk,
                                showAvatar: engine.showChatAvatars,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _chatCtrl,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Type a message (or "ok" to test duplicate preservation)...',
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      onSubmitted: (val) {
                                        if (val.trim().isEmpty) return;
                                        _chatCtrl.clear();
                                        engine.performHapticImpact();
                                        engine.simulateAiStreamResponse(val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: engine.isStreamingChat
                                        ? null
                                        : () {
                                            final text = _chatCtrl.text.trim();
                                            _chatCtrl.clear();
                                            engine.performHapticImpact();
                                            engine.simulateAiStreamResponse(
                                              text.isEmpty
                                                  ? 'Show me how puzzak_ui_chat streams Markdown!'
                                                  : text,
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.send_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Stream'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 2. Modals, Dialogs & Pickers
                    Category.settings(
                      title: engine.dict.value('modals_and_pickers'),
                      context: context,
                    ),
                    context.cards.cardGroup([
                      CardContents.tapIcon(
                        title: 'OptionPickerBottomSheet (PTK Draggable Sheet)',
                        subtitle:
                            'Selected metric: ${engine.selectedMetricOption}',
                        icon: Icons.swipe_up_rounded,
                        color: scheme.onPrimaryContainer,
                        colorBG: scheme.primaryContainer,
                        action: () {
                          engine.performHapticClick();
                          OptionPickerBottomSheet.show<String>(
                            context: context,
                            title: 'Select Primary Telemetry Metric',
                            currentValue: engine.selectedMetricOption,
                            options: const [
                              OptionPickerItem(
                                value: 'cpu_load',
                                title: 'CPU Load',
                                subtitle: 'Current: 38% (8 cores)',
                                icon: Icons.speed_rounded,
                              ),
                              OptionPickerItem(
                                value: 'ram_usage',
                                title: 'RAM Usage',
                                subtitle: 'Current: 9.8 / 16.0 GB',
                                icon: Icons.memory_rounded,
                              ),
                              OptionPickerItem(
                                value: 'network_rx',
                                title: 'Network Throughput',
                                subtitle: 'Current: 412 Mbps',
                                icon: Icons.wifi_tethering_rounded,
                              ),
                              OptionPickerItem(
                                value: 'soc_temp',
                                title: 'SoC Temperature',
                                subtitle: 'Current: 49.5 °C',
                                icon: Icons.thermostat_rounded,
                              ),
                            ],
                            onSelected: (val) {
                              engine.performHapticImpact();
                              engine.selectedMetricOption = val;
                              engine.logger.log(
                                'OptionPickerBottomSheet',
                                'info',
                                'Selected metric: $val',
                              );
                              engine.genericRefresh();
                            },
                          );
                        },
                      ),
                      CardContents.tapIcon(
                        title: 'TextInputDialog (geminilocal / ggscanus Style)',
                        subtitle:
                            'Current title: "${engine.customRenamedTitle}"',
                        icon: Icons.edit_note_rounded,
                        color: scheme.onTertiaryContainer,
                        colorBG: scheme.tertiaryContainer,
                        action: () async {
                          engine.performHapticClick();
                          final result = await TextInputDialog.show(
                            context: context,
                            title: 'Rename Node / Conversation',
                            labelText: 'Display Name',
                            initialValue: engine.customRenamedTitle,
                            hintText: 'Enter a title...',
                            suggestions: const [
                              OptionPickerItem(
                                value: 'Kyiv Primary Node',
                                title: 'Kyiv Primary Node',
                                subtitle: 'Production telemetry endpoint',
                              ),
                              OptionPickerItem(
                                value: 'PAIOS Local Agent',
                                title: 'PAIOS Local Agent',
                                subtitle: 'On-device Gemini Nano chat',
                              ),
                              OptionPickerItem(
                                value: 'Home Lab Cluster',
                                title: 'Home Lab Cluster',
                                subtitle: 'Internal LAN monitoring',
                              ),
                            ],
                          );
                          if (result != null && result.trim().isNotEmpty) {
                            engine.performHapticImpact();
                            engine.customRenamedTitle = result.trim();
                            engine.logger.log(
                              'TextInputDialog',
                              'info',
                              'Renamed item to "${engine.customRenamedTitle}"',
                            );
                            engine.genericRefresh();
                          }
                        },
                      ),
                    ]),

                    // 3. Adaptive Layouts Lab (Phone <-> Foldable <-> Desktop)
                    const AdaptiveLayoutsLabSection(),

                    // 4. Fullscreen Scaffolds & Wizards
                    Category.settings(
                      title: engine.dict.value('page_scaffolds'),
                      context: context,
                    ),
                    context.cards.cardGroup([
                      CardContents.tapIcon(
                        title: 'Launch SliverPageScaffold Demo',
                        subtitle:
                            'Collapsible header, back button, responsive 720px max width',
                        icon: Icons.web_asset_rounded,
                        color: scheme.onPrimaryContainer,
                        colorBG: scheme.primaryContainer,
                        action: () {
                          engine.performHapticClick();
                          _openFullScreenSliverPage(context, engine);
                        },
                      ),
                      CardContents.tapIcon(
                        title: 'Launch OnboardingWizard (3-Slide Intro)',
                        subtitle:
                            'PageView with animated 24px pill indicators and Skip / Next controls',
                        icon: Icons.rocket_launch_rounded,
                        color: scheme.onSecondaryContainer,
                        colorBG: scheme.secondaryContainer,
                        action: () {
                          engine.performHapticClick();
                          _openOnboardingWizard(context, engine);
                        },
                      ),
                    ]),

                    // 4. Circular Gauges
                    Category.settings(
                      title: 'Circular Gauge Complications',
                      context: context,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CircularGaugeCard(
                              title: 'CPU',
                              valueText:
                                  '${(latestCpu * 100).toStringAsFixed(0)}%',
                              progressValue: latestCpu,
                              icon: Icons.speed_rounded,
                              onTap: () => engine.performHapticClick(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CircularGaugeCard(
                              title: 'RAM',
                              valueText:
                                  '${(latestRam * 100).toStringAsFixed(0)}%',
                              progressValue: latestRam,
                              icon: Icons.storage_rounded,
                              onTap: () => engine.performHapticClick(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 5. Byte & Duration Formatters Lab
                    Category.settings(
                      title: engine.dict.value('formatters_lab'),
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
                        title:
                            'PuzzakFormatters.formatBytes(${engine.sampleBytes.round()})',
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

                    const SizedBox(height: 12),

                    // 6. Inter-App Agentic Mesh Lab (M3x Mesh)
                    const AgenticMeshLabSection(),

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
