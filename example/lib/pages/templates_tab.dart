import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:m3x_ui/m3x_ui.dart';
import '../engine.dart';

class TemplatesTab extends StatefulWidget {
  const TemplatesTab({super.key});

  @override
  State<TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends State<TemplatesTab> {
  String _selectedChoiceMode = 'smart_push';
  final Set<String> _selectedProposals = {'srv_kyiv', 'sp_cloudflare'};

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
                subtitle: 'Scroll down to collapse SliverAppBar.large into pinned AppBar',
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
        builder: (wizardCtx) => StatefulBuilder(
          builder: (ctx, setWizardState) {
            return OnboardingWizard(
              onFinish: () {
                engine.logger.log(
                  'OnboardingWizard',
                  'info',
                  'Completed OnboardingWizard (mode=$_selectedChoiceMode, proposals=${_selectedProposals.length})',
                );
                Navigator.of(wizardCtx).pop();
              },
              slides: [
                const OnboardingSlideData(
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
                  icon: Icons.checklist_rounded,
                  title: 'Starter Proposals (ChecklistGroupCard)',
                  description:
                      'Select which sample nodes and status pages to pre-populate:',
                  customBody: ChecklistGroupCard(
                    header: 'Recommended Nodes',
                    selectedIds: _selectedProposals,
                    onToggle: (id) {
                      setWizardState(() {
                        if (_selectedProposals.contains(id)) {
                          _selectedProposals.remove(id);
                        } else {
                          _selectedProposals.add(id);
                        }
                      });
                    },
                    items: const [
                      ChecklistProposalItem(
                        id: 'srv_kyiv',
                        title: 'Kyiv Edge Telemetry Node',
                        subtitle: 'https://kyiv.puzzak.page/AIO.php',
                        icon: Icons.dns_rounded,
                      ),
                      ChecklistProposalItem(
                        id: 'sp_cloudflare',
                        title: 'Cloudflare Statuspage',
                        subtitle: 'https://www.cloudflarestatus.com',
                        icon: Icons.cloud_done_rounded,
                      ),
                      ChecklistProposalItem(
                        id: 'sp_github',
                        title: 'GitHub Status',
                        subtitle: 'https://www.githubstatus.com',
                        icon: Icons.code_rounded,
                      ),
                    ],
                  ),
                ),
                OnboardingSlideData(
                  icon: Icons.notifications_active_rounded,
                  title: 'Choose Monitoring Mode (ChoiceCard)',
                  description:
                      'Select how background updates should run on your device:',
                  customBody: Column(
                    children: [
                      ChoiceCard(
                        icon: Icons.bolt_rounded,
                        title: 'Smart Foreground Watcher',
                        subtitle:
                            'Low-latency polling with persistent notification badge (PTK style)',
                        selected: _selectedChoiceMode == 'smart_push',
                        onTap: () =>
                            setWizardState(() => _selectedChoiceMode = 'smart_push'),
                      ),
                      const SizedBox(height: 8),
                      ChoiceCard(
                        icon: Icons.battery_saver_rounded,
                        title: 'Battery Saver (Manual Refresh)',
                        subtitle: 'Fetches telemetry only while the app is open',
                        selected: _selectedChoiceMode == 'manual',
                        onTap: () =>
                            setWizardState(() => _selectedChoiceMode = 'manual'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<PlaygroundEngine>(
      builder: (context, engine, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              surfaceTintColor: Colors.transparent,
              pinned: true,
              title: Text(engine.dict.value('tab_templates')),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Category.settings(
                    title: engine.dict.value('page_scaffolds'),
                    context: context,
                  ),
                  context.cards.cardGroup([
                    CardContents.tapIcon(
                      title: 'Launch SliverPageScaffold Page',
                      subtitle:
                          'Full-screen collapsible SliverAppBar.large + centered 720px max width',
                      icon: Icons.web_asset_rounded,
                      color: scheme.onPrimaryContainer,
                      colorBG: scheme.primaryContainer,
                      action: () => _openFullScreenSliverPage(context, engine),
                    ),
                    CardContents.tapIcon(
                      title: 'Launch OnboardingWizard (PTK 3-Slide Intro)',
                      subtitle:
                          'PageView with animated 24px pill dots, ChecklistGroupCard & ChoiceCard',
                      icon: Icons.rocket_launch_rounded,
                      color: scheme.onTertiaryContainer,
                      colorBG: scheme.tertiaryContainer,
                      action: () => _openOnboardingWizard(context, engine),
                    ),
                  ]),

                  Category.settings(
                    title: 'Inline ChoiceCard & ChecklistGroupCard Preview',
                    context: context,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        ChoiceCard(
                          icon: Icons.bolt_rounded,
                          title: 'ChoiceCard Option A (Selected)',
                          subtitle:
                              'Uses primaryContainer background tint + 2px primary border',
                          selected: _selectedChoiceMode == 'smart_push',
                          onTap: () =>
                              setState(() => _selectedChoiceMode = 'smart_push'),
                        ),
                        const SizedBox(height: 6),
                        ChoiceCard(
                          icon: Icons.eco_rounded,
                          title: 'ChoiceCard Option B',
                          subtitle: 'Tap to switch active ChoiceCard state',
                          selected: _selectedChoiceMode == 'manual',
                          onTap: () =>
                              setState(() => _selectedChoiceMode = 'manual'),
                        ),
                      ],
                    ),
                  ),

                  Category.settings(
                    title: 'EmptyStateView Complication (PTK Style)',
                    context: context,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Card(
                      color: scheme.surfaceContainerLow,
                      child: EmptyStateView(
                        icon: Icons.dns_outlined,
                        title: 'No Servers Configured Yet',
                        description:
                            'EmptyStateView combines a 72px muted icon, bold title, description, primary FilledButton.icon, and an optional TextPart.infoShort footer.',
                        actionLabel: 'Add Demo Server',
                        actionIcon: Icons.add_rounded,
                        onAction: () => engine.logger.log(
                          'EmptyStateView',
                          'info',
                          'Triggered EmptyStateView primary CTA button',
                        ),
                        footerTitle: 'Need the server monitoring script?',
                        footerSubtitle: 'Get AIO.php on GitHub',
                        onFooterAction: () => engine.logger.log(
                          'EmptyStateView',
                          'info',
                          'Tapped EmptyStateView infoShort footer link',
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
