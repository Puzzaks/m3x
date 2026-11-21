# Changelog

## 0.1.3

- Added runnable `example/main.dart`, `pub.dev` package links, and Flutter 3.50 static analysis compatibility for 160/160 pub points.

## 0.1.2

- Standardized documentation and metadata to Material 3 eXtended (m3x) branding with independence disclaimer.

## 0.1.1

- Added adaptive layout primitives (`M3xAdaptiveMasterDetail`, `M3xAdaptiveSplitHero`, `M3xAdaptiveContentFrame`) and scroll-velocity `MotionBlurContainer`.
- Added `pub.dev` metadata, `The Unlicense` license, `.pubignore`, and modernized README documentation.

## 0.0.4

- Added automatic native app launcher icon support in `SettingsBentoHeader`:
  - Added optional constructor parameters: `iconWidget`, `iconBytes`, and `iconAsset`.
  - Automatically falls back to `SettingsBentoHeader.defaultIconBytes` (populated via `M3x.init()`) rendered with 10px rounded corners.
  - Maintains 100% backwards compatibility with fallback to Material `Icon(icon, ...)`.

## 0.0.3

- Enhanced `SettingsBentoHeader` with intelligent version parsing: version number automatically displayed in the card title (`Version 1.2.10`) with release date in primary bold text.
- Symmetrical 2-row layout across Version and Modules bento cards (`$count Packages` header and `Tap to view` action text).
- Added `FittedBox` scale-down wrappers to prevent overflow and line-wrapping on narrow screens and high DPI.
- Added optional override parameters: `versionTitle`, `versionSubtitle`, `modulesTitle`, `modulesSubtitle`.

## 0.0.2

- Added `SettingsBentoHeader` and enhanced expressive scaffold integration.

## 0.0.1

- Initial release of `m3x_ui`.
- Material 3 Expressive grouped cards, bento elements, motion blur, and page scaffolds.
- Zero third-party pub dependencies.
