# m3x_ui

Pure-Flutter **Material 3 eXtended (`m3x`)** UI elements, segmented bento card groups, adaptive responsive scaffolds, option pickers, onboarding wizards, telemetry cards, and velocity-driven motion blur — with **zero third-party dependencies**.

> *Material 3 eXtended (`m3x`) is an independent open-source project by Puzzak built on top of Flutter's Material 3 design system and is not affiliated with or endorsed by Google.*

## Features

- **Segmented Card Groups (`elements.dart`)**:
  - `Cards(context: context).cardGroup(...)` (`context.cards.cardGroup(...)`) & declarative `CardGroup` widget with `20px` outer corners and `5px` inner edges across both 1-column lists and multi-column (`columns >= 2`) bento grids.
  - `ReorderableCardGroup`: Reorderable segmented card list with dynamic corner radii and per-index drag handles.
  - `CardContents`: Responsive `tap`, `halfTap`, `tapIcon`, `static`, `progress`, `doubleTap`, `longTap`, `turn`, `slider`, and `addretract` rows built with `Row`/`Expanded` (never raw physical screen dimensions).
  - `Category` (`settings`, `headerLine`, `divider`) and `TextPart` (`info`, `infoShort`, `userMessage`).
- **Bento Settings Header (`bento.dart`)**:
  - `SettingsBentoHeader`: Expressive app identity header with automatic native app icon display, intelligent version & release date parsing, changelog viewer dialog, and live installed-packages inspector.
- **Adaptive Scaffolds & Layouts (`scaffolds.dart`)**:
  - `SliverPageScaffold`: Standard `CustomScrollView` + `SliverAppBar.large` page scaffold.
  - `AdaptiveNavScaffold`: Responsive navigation switching between a mobile bottom `NavigationBar` and a desktop/tablet floating pill `NavigationRail` + optional right `sidePanel`.
  - `M3xAdaptiveMasterDetail`: Two-pane master/detail layout on wide viewports that collapses cleanly to single-pane navigation on phones.
  - `M3xAdaptiveSplitHero`: Split hero header + content layout for foldables, tablets, and desktop windows.
  - `M3xAdaptiveContentFrame`: Centered max-width reading/control frame for wide screens.
  - `EmptyStateView`, `PuzzakTheme`, and `StartupCrossFadeShell`.
- **Pickers & Dialogs (`pickers.dart`)**:
  - `OptionPickerBottomSheet`, `OptionPickerDialog`, and `TextInputDialog`.
- **Onboarding (`onboarding.dart`)**:
  - `OnboardingWizard`, `OnboardingSlideData`, `ChoiceCard`, and `ChecklistGroupCard`.
- **Telemetry & Dashboard Cards (`telemetry.dart`)**:
  - `TelemetrySparklineCard`, `CircularGaugeCard`, `SyncStatusCard`, `ThemeModeSwitchCard`, and `LogViewerList`.
- **Motion Blur (`motion_blur.dart`)**:
  - `MotionBlurContainer`: Scroll-velocity-driven directional GPU blur wrapper for expressive scrolling surfaces.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:m3x_ui/m3x_ui.dart';

Widget buildSettings(BuildContext context) {
  return SliverPageScaffold(
    title: 'Settings',
    children: [
      Category.settings(title: 'General', context: context),
      context.cards.cardGroup([
        CardContents.tap(
          title: 'Appearance',
          subtitle: 'Material 3 eXtended dynamic color',
          action: () {},
        ),
        CardContents.turn(
          title: 'Motion Blur',
          subtitle: 'Scroll-velocity GPU blur',
          value: true,
          action: () {},
          switcher: (v) {},
        ),
      ]),
    ],
  );
}
```

## License

Released into the public domain under [The Unlicense](LICENSE).
