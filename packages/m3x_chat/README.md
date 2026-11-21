# m3x_chat

Optional chat bubble, reasoning block, loading skeleton, and Markdown conversation UI complication for **Material 3 eXtended** ([`m3x_ui`](https://github.com/Puzzaks/m3x/tree/main/packages/m3x_ui)).

Isolates `flutter_markdown_plus` and `url_launcher` so apps using `m3x_ui` only pull in Markdown chat dependencies when rendering AI or assistant conversations.

## Features

- **`ChatMessage`**: Standardized immutable message model with `author`, `timestamp`, `thoughts`, `isLoading`, `loadingLabel`, `isThinkingStreaming`, `avatar*`, `imagePath`/`imageBytes`, `copyWith()`, `fromLegacyMap()`, `toLegacyMap()`, and `toJson()`.
- **`ChatAnimatedSkeleton`**: Pure-Flutter Material 3 shimmer bars with optional `loadingLabel` and smooth enter/exit transitions during loading and streaming continuation.
- **`ChatThoughtsBlock`**: Collapsible Material 3 reasoning sub-card with pulsing header while streaming, smart auto-scroll that respects manual user scrolling, auto-collapse on response start, and bounded `SelectableText`.
- **`ChatMessageBubble`**: Responsive Material 3 chat bubble with selectable `MarkdownBody`, safe `url_launcher` link handling, tap-to-reveal author & formatted timestamp metadata, optional `CircleAvatar` (`showAvatar`), `customContent` slot, and tap-to-zoom image thumbnails.
- **`ChatBubbleList`** & **`ChatTextPart`**: Renders conversation lists with optional `pendingUserMessage`, `streamingAiChunk`, and drop-in backwards-compatible `chatlog(...)`.

## Usage

```dart
import 'package:m3x_chat/m3x_chat.dart';

ChatBubbleList(
  messages: [
    const ChatMessage(
      isUser: false,
      text: 'Hello! How can I help you today?',
      thoughts: 'Greeting the user concisely.',
    ),
  ],
);
```

## License

Released into the public domain under [The Unlicense](LICENSE).
