import 'package:flutter/material.dart';
import 'package:m3x/m3x.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../engine.dart';
import '../services/billing_service.dart';
import '../services/crashlytics_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showChangelogDialog(BuildContext context, PlaygroundEngine engine) {
    SettingsBentoHeader.showChangelogDialog(
      context,
      title: 'Version & Changelog',
      subtitle: 'v${engine.appVersionDisplay} • ${engine.appBuildDate}',
      changelogContent: engine.changelogContent,
      emptyMessage: 'No changelog entries available.',
    );
  }

  void _showPackagesDialog(BuildContext context, PlaygroundEngine engine) {
    final deps = M3x.dependencies.isNotEmpty
        ? M3x.dependencies
        : {
            for (final pkg in engine.installedPackages) pkg.name: pkg.version,
          };

    SettingsBentoHeader.showDependenciesDialog(
      context,
      title: 'Installed Packages (${deps.length})',
      subtitle:
          'Live dependencies dynamically parsed from pubspec.yaml via M3x.init(). Tap any pub package to view on pub.dev.',
      dependencies: deps,
      onPackageTap: (name, spec, isWorkspace) {
        if (isWorkspace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$name ($spec): Modular Puzzak M3x ecosystem package.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          launchUrl(
            Uri.parse('https://pub.dev/packages/$name'),
            mode: LaunchMode.externalApplication,
          );
        }
      },
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
              title: Text(engine.dict.value('settings')),
            ),
            SliverToBoxAdapter(
              child: MotionBlurContainer(
                enabled: engine.motionBlurEnabled,
                maxBlur: engine.motionBlurIntensity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Declarative Settings Bento Header (puzzak_ui)
                    SettingsBentoHeader(
                      appName: 'Puzzak Playground',
                      subtitle: engine.appDescription.isNotEmpty
                          ? engine.appDescription
                          : M3x.config.appDescription,
                      versionDisplay: engine.appVersionDisplay,
                      onVersionTap: () => _showChangelogDialog(context, engine),
                      onModulesTap: () => _showPackagesDialog(context, engine),
                    ),

                    // 3. GitHub Repository Explorer Launcher
                    Category.settings(
                      title: 'GitHub Integration & Community',
                      context: context,
                    ),
                    context.cards.cardGroup([
                      CardContents.tapIcon(
                        title: 'GitHub Repository Explorer',
                        subtitle:
                            'Inspect README, Issues with comments, Releases, and PAT Auth (+5,000 req/hr)',
                        icon: Icons.hub_rounded,
                        color: scheme.onTertiaryContainer,
                        colorBG: scheme.tertiaryContainer,
                        action: () {
                          engine.performHapticImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GitHubExplorerPage(),
                            ),
                          );
                        },
                      ),
                    ]),

                    // 4. Appearance & Display
                    Category.settings(
                      title: engine.dict.value('appearance'),
                      context: context,
                    ),
                    ThemeModeSwitchCard(
                      title: engine.dict.value('theme_mode'),
                      mode: engine.themeMode,
                      onChanged: (mode) {
                        engine.performHapticImpact();
                        engine.setThemeMode(mode);
                      },
                    ),
                    const SizedBox(height: 4),
                    context.cards.cardGroup([
                      CardContents.turn(
                        title: engine.dict.value('dynamic_system_color'),
                        subtitle:
                            'Extract Material 3 palette from system/wallpaper (Pixel 9 Pro)',
                        value: engine.useDynamicColor,
                        action: () {
                          engine.setUseDynamicColor(!engine.useDynamicColor);
                        },
                        switcher: (v) {
                          engine.setUseDynamicColor(v);
                        },
                      ),
                      CardContents.turn(
                        title: engine.dict.value('motion_blur'),
                        subtitle: engine.dict.value('motion_blur_subtitle'),
                        value: engine.motionBlurEnabled,
                        action: () {
                          engine.toggleMotionBlur(!engine.motionBlurEnabled);
                        },
                        switcher: engine.toggleMotionBlur,
                      ),
                      if (engine.motionBlurEnabled)
                        CardContents.slider(
                          title: 'Motion Blur Max Intensity',
                          subtitle:
                              '${engine.motionBlurIntensity.toStringAsFixed(1)} px (Sameera Essentials Slider)',
                          value: engine.motionBlurIntensity,
                          min: 2.0,
                          max: 14.0,
                          divisions: 24,
                          onChanged: (val) {
                            engine.setMotionBlurIntensity(val);
                          },
                        ),
                      CardContents.turn(
                        title: engine.dict.value('haptics'),
                        subtitle: engine.dict.value('haptics_subtitle'),
                        value: engine.hapticsEnabled,
                        action: () {
                          engine.toggleHaptics(!engine.hapticsEnabled);
                        },
                        switcher: engine.toggleHaptics,
                      ),
                    ]),

                    // 5. Google Play Store Billing & Subscriptions
                    Category.settings(
                      title: 'Subscriptions & Google Play Billing',
                      context: context,
                    ),
                    AnimatedBuilder(
                      animation: BillingService.instance,
                      builder: (ctx, _) {
                        final billing = BillingService.instance;
                        return Column(
                          children: [
                            SubscriptionTierCard(
                              title: 'Puzzak Ecosystem Pro',
                              price: '\$2.99',
                              period: 'lifetime unlock',
                              badgeText: billing.isPro ? 'ACTIVE' : 'LIFETIME',
                              badgeColor: billing.isPro ? Colors.green : null,
                              isFeatured: true,
                              icon: Icons.stars_rounded,
                              features: const [
                                'Unlimited Server Watchers & Status Pages',
                                'Direct GitHub Issue and Discussion jumping',
                                'Ad-free Experience across all Puzzak tools',
                                'Early Beta Releases & Developer Support',
                              ],
                              ctaText: billing.isPro
                                  ? 'Pro Member (Active)'
                                  : 'Unlock with Google Play',
                              onCtaPressed: () {
                                engine.performHapticImpact();
                                if (billing.products.isNotEmpty) {
                                  billing.buyProduct(billing.products.first);
                                } else {
                                  // Sandbox fallback toggle
                                  billing.toggleSimulatedPro(!billing.isPro);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.restore_rounded, size: 18),
                                      label: const Text('Restore Purchases'),
                                      onPressed: () {
                                        engine.performHapticClick();
                                        billing.restorePurchases();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: Icon(
                                        billing.isPro
                                            ? Icons.check_circle_rounded
                                            : Icons.bug_report_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        billing.isPro
                                            ? 'Sandbox Pro: ON'
                                            : 'Sandbox Pro: OFF',
                                      ),
                                      onPressed: () {
                                        engine.performHapticClick();
                                        billing.toggleSimulatedPro(!billing.isPro);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // // 6. Google Mobile Ads & Monetization Lab
                    // Category.settings(
                    //   title: 'Google Mobile Ads & Monetization Lab',
                    //   context: context,
                    // ),
                    // AnimatedBuilder(
                    //   animation: AdService.instance,
                    //   builder: (ctx, _) {
                    //     final adService = AdService.instance;
                    //     return context.cards.cardGroup([
                    //       // Card 1: Interactive settings toggle
                    //       CardContents.turn(
                    //         title: 'Personalized Test Ads',
                    //         subtitle:
                    //             'AdMob test consent & device targeting mode',
                    //         value: true,
                    //         action: () {},
                    //         switcher: (v) {},
                    //       ),
                    //       // Card 2: The test ad seamlessly inserted IN-BETWEEN other cards!
                    //       CardContents.ad(
                    //         child: _bannerAdLoaded && _bannerAd != null
                    //             ? SizedBox(
                    //                 width: _bannerAd!.size.width.toDouble(),
                    //                 height: _bannerAd!.size.height.toDouble(),
                    //                 child: AdWidget(ad: _bannerAd!),
                    //               )
                    //             : null,
                    //         isLoaded: _bannerAdLoaded && _bannerAd != null,
                    //         action: () {
                    //           engine.performHapticClick();
                    //           _initBanner();
                    //         },
                    //       ),
                    //       // Card 3: Interstitial Ad full row
                    //       CardContents.tapIcon(
                    //         title: 'Show Interstitial Ad',
                    //         subtitle:
                    //             'Full-screen test display unit (Google Mobile Ads)',
                    //         icon: Icons.fullscreen_rounded,
                    //         color: scheme.onSecondaryContainer,
                    //         colorBG: scheme.secondaryContainer,
                    //         action: () {
                    //           engine.performHapticClick();
                    //           adService.showInterstitialAd();
                    //         },
                    //       ),
                    //       // Card 4: Rewarded Ad full row
                    //       CardContents.tapIcon(
                    //         title: 'Show Rewarded Video Ad',
                    //         subtitle:
                    //             'Watch video to unlock simulated Pro session privileges',
                    //         icon: Icons.card_giftcard_rounded,
                    //         color: scheme.onTertiaryContainer,
                    //         colorBG: scheme.tertiaryContainer,
                    //         action: () {
                    //           engine.performHapticClick();
                    //           adService.showRewardedAd(
                    //             onRewarded: (reward) {
                    //               BillingService.instance.toggleSimulatedPro(true);
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 SnackBar(
                    //                   content: Text(
                    //                     '🎉 Reward Unlocked: ${reward.amount} ${reward.type}! Pro privileges granted for this session.',
                    //                   ),
                    //                 ),
                    //               );
                    //             },
                    //           );
                    //         },
                    //       ),
                    //     ]);
                    //   },
                    // ),

                    // 7. Google Firebase Crashlytics & Analytics Lab
                    Category.settings(
                      title: 'Google Firebase Crashlytics & Diagnostics Lab',
                      context: context,
                    ),
                    context.cards.cardGroup([
                      CardContents.tapIcon(
                        title: 'Record Non-Fatal Exception',
                        subtitle:
                            'Captures handled errors with stack traces to Crashlytics buffer',
                        icon: Icons.healing_rounded,
                        color: scheme.onPrimaryContainer,
                        colorBG: scheme.primaryContainer,
                        action: () {
                          engine.performHapticClick();
                          CrashlyticsService.instance.testNonFatalError();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Recorded non-fatal test exception in Crashlytics buffer',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      CardContents.tapIcon(
                        title: 'Log Diagnostic Breadcrumb & Custom Key',
                        subtitle:
                            'Appends breadcrumb and attaches session metadata to crash logs',
                        icon: Icons.history_edu_rounded,
                        color: scheme.onSecondaryContainer,
                        colorBG: scheme.secondaryContainer,
                        action: () {
                          engine.performHapticClick();
                          CrashlyticsService.instance.logBreadcrumb('User triggered diagnostic audit');
                          CrashlyticsService.instance.setCustomKey('test_key', 'antigravity_session');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Breadcrumb & custom key attached to session'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      CardContents.tapIcon(
                        title: 'Simulate Fatal Crash Error',
                        subtitle:
                            'Simulates critical unhandled fatal exception for Play Console Vitals',
                        icon: Icons.dangerous_rounded,
                        color: scheme.onErrorContainer,
                        colorBG: scheme.errorContainer,
                        action: () {
                          engine.performHapticImpact();
                          CrashlyticsService.instance.testFatalCrash();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Simulated fatal crash reported to telemetry engine'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ]),

                    // 8. Localization
                    Category.settings(
                      title: engine.dict.value('select_language'),
                      context: context,
                    ),
                    context.cards.cardGroup([
                      CardContents.doubleTap(
                        title: engine.dict.value('select_language'),
                        subtitle:
                            '${engine.dict.currentLanguageName} (${engine.dict.locale.toUpperCase()}) — ${engine.dict.value('select_language_subtitle')}',
                        icon: Icons.language_rounded,
                        secondTooltip: 'Reset to system language',
                        action: () {
                          engine.performHapticClick();
                          OptionPickerDialog.show<String>(
                            context: context,
                            title: engine.dict.value('select_language'),
                            currentValue: engine.dict.locale,
                            options: engine.dict.languages
                                .map(
                                  (lang) => OptionPickerItem<String>(
                                    value: lang['id'].toString(),
                                    title: lang['name'].toString(),
                                    subtitle: lang['origin'].toString(),
                                  ),
                                )
                                .toList(),
                            onSelected: (code) {
                              engine.performHapticImpact();
                              engine.selectLanguage(code);
                            },
                          );
                        },
                        secondAction: () {
                          engine.performHapticImpact();
                          engine.resetToSystemLanguage();
                        },
                      ),
                      CardContents.turn(
                        title: 'Debug Fallback Highlights',
                        subtitle:
                            'Mark missing translations with "!...!" and "!!!"',
                        value: engine.dict.debugHighlightFallbacks,
                        action: () {
                          engine.toggleDebugFallbackHighlights(
                            !engine.dict.debugHighlightFallbacks,
                          );
                        },
                        switcher: engine.toggleDebugFallbackHighlights,
                      ),
                    ]),

                    // 9. Data & Sync
                    Category.settings(
                      title: engine.dict.value('sync'),
                      context: context,
                    ),
                    context.cards.cardGroup([
                      CardContents.tapIcon(
                        title: 'Synchronize Storage & Settings',
                        subtitle: 'Last synced: Just now (0 conflicts)',
                        icon: Icons.cloud_sync_rounded,
                        color: scheme.onSecondaryContainer,
                        colorBG: scheme.secondaryContainer,
                        action: () {
                          engine.performHapticImpact();
                          engine.triggerSimulatedSync();
                        },
                      ),
                      CardContents.tapIcon(
                        title: 'Clear Event Logs & Memory Buffer',
                        subtitle:
                            'Currently holding ${engine.logger.logs.length} deduplicated log entries',
                        icon: Icons.cleaning_services_rounded,
                        color: scheme.onErrorContainer,
                        colorBG: scheme.errorContainer,
                        action: () {
                          engine.performHapticImpact();
                          engine.logger.clearLogs();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Log buffer cleared'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ]),

                    // 10. About & Credits
                    Category.settings(
                      title: 'About Puzzak UI',
                      context: context,
                    ),
                    context.cards.cardGroup([
                      CardContents.tapIcon(
                        title: 'Stand with Ukraine',
                        subtitle: 'Supporting the Armed Forces of Ukraine',
                        icon: Icons.favorite_rounded,
                        color: Colors.white,
                        colorBG: Colors.blue.shade700,
                        action: () {
                          engine.performHapticClick();
                          engine.logger.log('Community', 'info', 'Stand with Ukraine link clicked');
                        },
                      ),
                    ]),
                    TextPart.info(
                      title:
                          'Consolidated UI, Google Mobile Ads, Play Billing, Crashlytics & GitHub Explorer created for Puzzak apps.',
                      subtitle: 'Puzzak Development System',
                      action: () {},
                      context: context,
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
