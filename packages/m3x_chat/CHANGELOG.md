# Changelog

## 0.2.5

- Added runnable `example/main.dart`, `pub.dev` package links, and Flutter 3.50 static analysis compatibility for 160/160 pub points.

## 0.2.4

- Standardized documentation and metadata to Material 3 eXtended (m3x) branding with independence disclaimer.

## 0.2.3

- Migrated from discontinued `flutter_markdown` to `flutter_markdown_plus`.
- Added smart auto-scroll to `ChatThoughtsBlock` during live streaming (`ScrollController` attached to the internal `SingleChildScrollView` automatically follows `maxScrollExtent` as new reasoning tokens arrive, snaps to bottom when expanded while streaming, pauses when the user manually scrolls >24px above the bottom, and resumes when scrolled back within 24px or collapsed/re-expanded).

## 0.2.0+26111501

- Standardized `ChatMessage` schema with `author`, `timestamp`, `thoughts`, `isLoading`, `loadingLabel`, `isThinkingStreaming`, `avatarBytes`, `avatarText`, `avatarIcon`, `avatarBackgroundColor`, `copyWith()`, `toJson()`, and expanded `fromLegacyMap()` (`'time'`, `'thoughts'`/`'thoughtProcess'`, `'author'`, `'isLoading'`, `'loadingLabel'`).
- Added `ChatAnimatedSkeleton` (pure-Flutter Material 3 shimmer loading bars + optional `loadingLabel`) with smooth `AnimatedSize` + `AnimatedSwitcher` enter/exit transitions inside `ChatMessageBubble`.
- Added `ChatThoughtsBlock` (collapsible Material 3 reasoning sub-card with pulsing icon while streaming, auto-collapse on response start, and bounded `SelectableText`).
- Added tap-to-reveal `author` & formatted `timestamp` metadata pill, optional `CircleAvatar` (`showAvatar`), `customContent` slot, `thoughtsTrailing`, localized labels, and `markdownStyleSheet` across `ChatMessageBubble`, `ChatBubbleList`, and `ChatTextPart`.

## 0.0.1

- Initial release of `m3x_chat`.
- Isolates `flutter_markdown` and `url_launcher` chat bubble complication for `m3x_ui`.
