# Changelog

## 0.0.7

- Added runnable `example/main.dart`, `pub.dev` package links, and Flutter 3.50 static analysis compatibility for 160/160 pub points.

## 0.0.6

- Standardized documentation and metadata to Material 3 eXtended (m3x) branding with independence disclaimer.

## 0.0.5

- Standardized `pub.dev` metadata, `The Unlicense` license, `.pubignore`, and documentation across the M3x ecosystem.
- Automatically syncs `SettingsBentoHeader` defaults (`defaultDependencies`, `defaultChangelogContent`, `defaultVersionDisplay`, and `defaultIconBytes`) during `M3x.init()`.

## 0.0.2+26110702

- Added native app launcher icon cache `M3x.appIconBytes` and getter/setter.
- In `M3x.init()`, automatically invokes platform channel `com.puzzak.m3x_mesh` method `getAppIcon` and synchronizes with `SettingsBentoHeader.defaultIconBytes`.
- Added `appIconBytes` property to `M3xConfig`.

## 0.0.1+26110701

- Re-exports `m3x_mesh` (Inter-App Agentic Mesh Protocol & Tool Calling).
- Re-exports `m3x_storage` (Opinionated Hive Persistence Middleware).
- Re-exports `m3x_gh` (Standalone GitHub Explorer).
- Automatic propagation of `M3x.storageBoxName` to `M3xStorage` and GitHub owner/repo to `M3xGitHub`.

## 0.0.1

- Initial release of `m3x` master umbrella package for the M3x Flutter ecosystem.
- Bundles and re-exports `m3x_ui`, `m3x_chat`, `m3x_dict`, and `m3x_core`.
- Introduces `M3x` orchestrator with automatic `pubspec.yaml` parsing and version formatting.
