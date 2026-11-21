import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_chat/m3x_chat.dart';
import 'package:m3x_ui/motion_blur.dart';

void main() {
  final Uint8List png1x1 = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  group('ChatMessage Schema & Legacy Serialization', () {
    test('supports standardized metadata, copyWith, toLegacyMap, and toJson', () {
      final now = DateTime.utc(2026, 11, 15, 14, 32, 5);
      final msg = ChatMessage(
        sender: 'Gemini',
        author: 'Gemini Nano v4',
        message: 'Hello world',
        isUser: false,
        timestamp: now,
        thoughts: 'Step 1: analyze prompt.',
        isLoading: true,
        loadingLabel: 'Continuing response…',
        isThinkingStreaming: true,
        avatarIcon: Icons.auto_awesome_rounded,
        avatarText: 'GN',
        avatarBackgroundColor: Colors.teal,
        avatarBytes: png1x1,
      );

      expect(msg.displayAuthor, 'Gemini Nano v4');
      expect(msg.hasThoughts, isTrue);
      expect(msg.hasAvatar, isTrue);
      expect(msg.isLoading, isTrue);
      expect(msg.loadingLabel, 'Continuing response…');
      expect(msg.isThinkingStreaming, isTrue);

      final updated = msg.copyWith(
        isLoading: false,
        clearLoadingLabel: true,
        isThinkingStreaming: false,
      );
      expect(updated.isLoading, isFalse);
      expect(updated.loadingLabel, isNull);
      expect(updated.isThinkingStreaming, isFalse);
      expect(updated.thoughts, 'Step 1: analyze prompt.');

      final Map<String, String> legacy = msg.toLegacyMap();
      expect(legacy['user'], 'Gemini');
      expect(legacy['author'], 'Gemini Nano v4');
      expect(legacy['time'], now.millisecondsSinceEpoch.toString());
      expect(legacy['thoughts'], 'Step 1: analyze prompt.');
      expect(legacy['isLoading'], 'true');
      expect(legacy['loadingLabel'], 'Continuing response…');

      final Map<String, dynamic> json = msg.toJson();
      expect(json['sender'], 'Gemini');
      expect(json['author'], 'Gemini Nano v4');
      expect(json['time'], now.millisecondsSinceEpoch);
      expect(json['isLoading'], isTrue);
    });

    test('fromLegacyMap parses thoughtProcess, thoughts, author, and time formats', () {
      final epochMs = DateTime.utc(2026, 11, 15, 10, 20, 30).millisecondsSinceEpoch;

      final fromInt = ChatMessage.fromLegacyMap({
        'user': 'Gemini',
        'author': 'Gemini Nano v4',
        'message': 'Answer A',
        'thoughtProcess': 'Reasoning via thoughtProcess',
        'time': epochMs,
        'isLoading': true,
        'loadingLabel': 'Generating…',
      });
      expect(fromInt.isUser, isFalse);
      expect(fromInt.displayAuthor, 'Gemini Nano v4');
      expect(fromInt.thoughts, 'Reasoning via thoughtProcess');
      expect(fromInt.timestamp?.millisecondsSinceEpoch, epochMs);
      expect(fromInt.isLoading, isTrue);
      expect(fromInt.loadingLabel, 'Generating…');

      final fromNumericString = ChatMessage.fromLegacyMap({
        'user': 'User',
        'message': 'Hi',
        'time': epochMs.toString(),
      });
      expect(fromNumericString.isUser, isTrue);
      expect(fromNumericString.displayAuthor, 'User');
      expect(fromNumericString.timestamp?.millisecondsSinceEpoch, epochMs);

      final fromIso = ChatMessage.fromLegacyMap({
        'user': 'Gemini',
        'message': 'Answer B',
        'thoughts': 'Reasoning via thoughts',
        'time': '2026-11-15T14:32:05Z',
      });
      expect(fromIso.thoughts, 'Reasoning via thoughts');
      expect(fromIso.timestamp, DateTime.parse('2026-11-15T14:32:05Z'));
    });
  });

  group('ChatAnimatedSkeleton & Loading Transitions', () {
    testWidgets('renders skeleton while loading and animates out when isLoading becomes false', (WidgetTester tester) async {
      ChatMessage currentMsg = const ChatMessage(
        sender: 'Gemini',
        message: '',
        isUser: false,
        isLoading: true,
        loadingLabel: 'Continuing response…',
      );

      late StateSetter outerSetState;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: ChatBubbleList(messages: [currentMsg]),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byType(ChatAnimatedSkeleton), findsOneWidget);
      expect(find.text('Continuing response…'), findsOneWidget);

      // Transition to streaming text + forward skeleton
      outerSetState(() {
        currentMsg = currentMsg.copyWith(
          message: 'Partial response arrived.',
          isLoading: true,
        );
      });
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Partial response arrived.'), findsOneWidget);
      expect(find.byType(ChatAnimatedSkeleton), findsOneWidget);

      // Flip isLoading false -> skeleton animates out cleanly and settles
      outerSetState(() {
        currentMsg = currentMsg.copyWith(
          isLoading: false,
          clearLoadingLabel: true,
        );
      });
      await tester.pumpAndSettle();
      expect(find.byType(ChatAnimatedSkeleton), findsNothing);
      expect(find.text('Partial response arrived.'), findsOneWidget);
    });
  });

  group('ChatMessageBubble Metadata Tap-to-Reveal & Avatars', () {
    testWidgets('tapping bubble reveals and hides author + formatted timestamp', (WidgetTester tester) async {
      final ts = DateTime(2026, 11, 15, 14, 32, 5);
      final expectedFormatted = ChatMessageBubble.formatDefaultTimestamp(
        ts,
        now: ts,
      );
      expect(expectedFormatted, '14:32:05');

      final otherDayFormatted = ChatMessageBubble.formatDefaultTimestamp(
        DateTime(2026, 11, 15, 14, 32, 5),
        now: DateTime(2026, 11, 16, 9, 0, 0),
      );
      expect(otherDayFormatted, 'Nov 15, 14:32:05');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              message: ChatMessage(
                sender: 'Gemini',
                author: 'Gemini Nano v4',
                message: 'Tap to inspect metadata.',
                isUser: false,
                timestamp: ts,
              ),
              formatTimestamp: (dt) =>
                  ChatMessageBubble.formatDefaultTimestamp(dt, now: ts),
            ),
          ),
        ),
      );

      expect(find.text('Gemini Nano v4  •  14:32:05'), findsNothing);

      final Finder bubbleCardFinder = find.descendant(
        of: find.byType(ChatMessageBubble),
        matching: find.byType(Card),
      );
      await tester.tap(bubbleCardFinder);
      await tester.pumpAndSettle();
      expect(find.text('Gemini Nano v4  •  14:32:05'), findsOneWidget);

      await tester.tap(bubbleCardFinder);
      await tester.pumpAndSettle();
      expect(find.text('Gemini Nano v4  •  14:32:05'), findsNothing);
    });

    testWidgets('showAvatar true renders CircleAvatar and showAvatar false omits it', (WidgetTester tester) async {
      final msgs = <ChatMessage>[
        const ChatMessage(
          sender: 'User',
          author: 'Alex Puzzak',
          message: 'Hello!',
          isUser: true,
        ),
        ChatMessage(
          sender: 'Gemini',
          author: 'Gemini Nano v4',
          message: 'Hi Alex!',
          isUser: false,
          avatarBytes: png1x1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubbleList(
              messages: msgs,
              showAvatar: false,
            ),
          ),
        ),
      );
      expect(find.byType(CircleAvatar), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubbleList(
              messages: msgs,
              showAvatar: true,
            ),
          ),
        ),
      );
      expect(find.byType(CircleAvatar), findsNWidgets(2));
      expect(find.text('AP'), findsOneWidget);
    });
  });

  group('ChatThoughtsBlock & Responsive 320x480 Layout', () {
    testWidgets('thoughts auto-expand while streaming, auto-collapse when text arrives, and toggle manually', (WidgetTester tester) async {
      ChatMessage msg = const ChatMessage(
        sender: 'Gemini',
        message: '',
        thoughts: 'Evaluating board state and available moves.',
        isThinkingStreaming: true,
        isUser: false,
      );

      late StateSetter outerSetState;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                outerSetState = setState;
                return ChatMessageBubble(
                  message: msg,
                  thinkingInProgressLabel: 'Thinking…',
                  thoughtProcessLabel: 'Thought Process',
                );
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Thinking…'), findsOneWidget);
      expect(
        find.text('Evaluating board state and available moves.'),
        findsOneWidget,
      );

      // Response text starts -> thoughts auto-collapse smoothly
      outerSetState(() {
        msg = msg.copyWith(
          message: 'Recommended move: **Right**.',
          isThinkingStreaming: false,
        );
      });
      await tester.pumpAndSettle();
      expect(find.text('Thought Process'), findsOneWidget);
      expect(
        find.text('Evaluating board state and available moves.'),
        findsNothing,
      );

      // Manual tap expands thoughts again
      await tester.tap(find.text('Thought Process'));
      await tester.pumpAndSettle();
      expect(
        find.text('Evaluating board state and available moves.'),
        findsOneWidget,
      );
    });

    testWidgets('renders zero overflows at 320x480 with avatars, thoughts, customContent, and loading skeleton', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: ChatBubbleList(
                showAvatar: true,
                initiallyExpandedMetadata: true,
                messages: [
                  ChatMessage(
                    sender: 'User',
                    author: 'Puzzak',
                    message: 'Very long prompt message to verify narrow 320px bubble wrapping.',
                    isUser: true,
                    timestamp: DateTime(2026, 11, 15, 14, 30, 0),
                  ),
                  ChatMessage(
                    sender: 'Gemini',
                    author: 'Gemini Nano v4',
                    message: 'Streaming response on narrow screen.',
                    thoughts: 'Checking constraints on 320x480 viewport.',
                    isLoading: true,
                    loadingLabel: 'Continuing response…',
                    isUser: false,
                    timestamp: DateTime(2026, 11, 15, 14, 30, 5),
                    avatarIcon: Icons.auto_awesome_rounded,
                  ),
                ],
                customContentBuilder: (context, msg, index) {
                  if (msg.isUser) return null;
                  return const Chip(label: Text('Tool Result'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      expect(find.text('Tool Result'), findsOneWidget);
      expect(find.byType(ChatAnimatedSkeleton), findsOneWidget);
    });
  });

  group('Bubble Shrink-Wrapping & Nested Scroll Blur Isolation', () {
    testWidgets('short user ("Hi") and AI ("OK") bubbles shrink-wrap well below maxBubbleWidth', (WidgetTester tester) async {
      const double maxBubbleWidth = 320.0;
      const Key userKey = ValueKey<String>('user-short');
      const Key aiKey = ValueKey<String>('ai-short');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ChatMessageBubble(
                    key: userKey,
                    maxBubbleWidth: maxBubbleWidth,
                    message: ChatMessage(
                      sender: 'User',
                      message: 'Hi',
                      isUser: true,
                    ),
                  ),
                  SizedBox(height: 8),
                  ChatMessageBubble(
                    key: aiKey,
                    maxBubbleWidth: maxBubbleWidth,
                    message: ChatMessage(
                      sender: 'Gemini',
                      message: 'OK',
                      isUser: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final double userCardWidth = tester
          .getSize(find.descendant(of: find.byKey(userKey), matching: find.byType(Card)))
          .width;
      final double aiCardWidth = tester
          .getSize(find.descendant(of: find.byKey(aiKey), matching: find.byType(Card)))
          .width;

      expect(userCardWidth, lessThan(maxBubbleWidth * 0.6));
      expect(aiCardWidth, lessThan(maxBubbleWidth * 0.6));
    });

    testWidgets('isLoading true -> false animates out cleanly and shrinks short bubble back down', (WidgetTester tester) async {
      const double maxBubbleWidth = 320.0;
      const Key aiKey = ValueKey<String>('ai-loading-shrink');
      ChatMessage msg = const ChatMessage(
        sender: 'Gemini',
        message: 'OK',
        isUser: false,
        isLoading: true,
        loadingLabel: 'Thinking…',
      );

      late StateSetter outerSetState;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: StatefulBuilder(
                builder: (context, setState) {
                  outerSetState = setState;
                  return ChatMessageBubble(
                    key: aiKey,
                    maxBubbleWidth: maxBubbleWidth,
                    message: msg,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChatAnimatedSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);

      outerSetState(() {
        msg = msg.copyWith(isLoading: false, clearLoadingLabel: true);
      });
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ChatAnimatedSkeleton), findsNothing);

      final double aiCardWidth = tester
          .getSize(find.descendant(of: find.byKey(aiKey), matching: find.byType(Card)))
          .width;
      expect(aiCardWidth, lessThan(maxBubbleWidth * 0.6));
    });

    testWidgets('scrolling inside ChatThoughtsBlock triggers zero blur on parent MotionBlurContainer', (WidgetTester tester) async {
      const Key parentBlurKey = ValueKey<String>('parent-motion-blur');
      final List<ScrollNotification> leakedNotifications = <ScrollNotification>[];
      final String longThoughts = List<String>.generate(
        40,
        (i) => 'Thought line $i: evaluating token probabilities and tool state.',
      ).join('\n');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                leakedNotifications.add(notification);
                return false;
              },
              child: MotionBlurContainer(
                key: parentBlurKey,
                speedThreshold: 1.0,
                maxBlur: 8.0,
                child: ListView(
                  children: [
                    ChatMessageBubble(
                      thoughtProcessLabel: 'Thought Process',
                      message: ChatMessage(
                        sender: 'Gemini',
                        message: '',
                        thoughts: longThoughts,
                        isThinkingStreaming: false,
                        isUser: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Thought Process'));
      await tester.pumpAndSettle();

      final Finder innerScrollFinder = find.descendant(
        of: find.byType(ChatThoughtsBlock),
        matching: find.byType(SingleChildScrollView),
      );
      expect(innerScrollFinder, findsOneWidget);

      await tester.fling(innerScrollFinder, const Offset(0, -300), 1500);
      await tester.pump(const Duration(milliseconds: 16));

      expect(leakedNotifications, isEmpty);

      final ImageFiltered parentImageFiltered = tester
          .widgetList<ImageFiltered>(
            find.descendant(
              of: find.byKey(parentBlurKey),
              matching: find.byType(ImageFiltered),
            ),
          )
          .first;
      expect(parentImageFiltered.enabled, isFalse);

      await tester.pumpAndSettle();
      expect(leakedNotifications, isEmpty);
    });

    testWidgets('short AI bubble ("Paris") with collapsed ChatThoughtsBlock shrink-wraps < maxBubbleWidth * 0.65 and expands on tap', (WidgetTester tester) async {
      const double maxBubbleWidth = 480.0;
      const Key aiKey = ValueKey<String>('ai-short-with-thoughts');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: ChatMessageBubble(
                key: aiKey,
                maxBubbleWidth: maxBubbleWidth,
                thoughtProcessLabel: 'Thought Process',
                message: ChatMessage(
                  sender: 'Gemini',
                  message: 'Paris',
                  thoughts:
                      'Long internal thought process explaining European capitals and verifying France.',
                  isThinkingStreaming: false,
                  isUser: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final Finder cardFinder = find.descendant(
        of: find.byKey(aiKey),
        matching: find.byType(Card),
      );
      final double collapsedWidth = tester.getSize(cardFinder).width;
      expect(collapsedWidth, lessThan(maxBubbleWidth * 0.65));
      expect(find.text('Paris'), findsOneWidget);
      expect(
        find.text(
          'Long internal thought process explaining European capitals and verifying France.',
        ),
        findsNothing,
      );

      await tester.tap(find.text('Thought Process'));
      await tester.pumpAndSettle();

      final double expandedWidth = tester.getSize(cardFinder).width;
      expect(expandedWidth, greaterThan(collapsedWidth));
      expect(
        find.text(
          'Long internal thought process explaining European capitals and verifying France.',
        ),
        findsOneWidget,
      );
    });
  });

  group('ChatThoughtsBlock Live-Stream Auto-Scroll', () {
    testWidgets(
        'auto-scrolls toward maxScrollExtent as streaming thoughts grow past maxContentHeight',
        (WidgetTester tester) async {
      String thoughts = 'Step 1: Initial reasoning.';
      late StateSetter outerSetState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, setState) {
                  outerSetState = setState;
                  return ChatThoughtsBlock(
                    thoughts: thoughts,
                    isStreaming: true,
                    maxContentHeight: 120.0,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final Finder scrollFinder = find.descendant(
        of: find.byType(ChatThoughtsBlock),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollFinder, findsOneWidget);
      final ScrollController controller =
          tester.widget<SingleChildScrollView>(scrollFinder).controller!;
      expect(controller.offset, 0.0);

      outerSetState(() {
        thoughts = List<String>.generate(
          20,
          (i) => 'Thought line $i: evaluating token probabilities.',
        ).join('\n');
      });
      await tester.pump();

      final double firstMaxExtent = controller.position.maxScrollExtent;
      expect(firstMaxExtent, greaterThan(0.0));
      expect(controller.offset, closeTo(firstMaxExtent, 0.5));

      outerSetState(() {
        thoughts = '$thoughts\n${List<String>.generate(
          10,
          (i) => 'Extra thought line $i: verifying constraints.',
        ).join('\n')}';
      });
      await tester.pump();

      final double secondMaxExtent = controller.position.maxScrollExtent;
      expect(secondMaxExtent, greaterThan(firstMaxExtent));
      expect(controller.offset, closeTo(secondMaxExtent, 0.5));
    });

    testWidgets(
        'scrolling up pauses auto-follow during streaming and scrolling back to bottom resumes it',
        (WidgetTester tester) async {
      String thoughts = List<String>.generate(
        25,
        (i) => 'Thought line $i: evaluating reasoning step.',
      ).join('\n');
      late StateSetter outerSetState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, setState) {
                  outerSetState = setState;
                  return ChatThoughtsBlock(
                    thoughts: thoughts,
                    isStreaming: true,
                    maxContentHeight: 120.0,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final Finder scrollFinder = find.descendant(
        of: find.byType(ChatThoughtsBlock),
        matching: find.byType(SingleChildScrollView),
      );
      final ScrollController controller =
          tester.widget<SingleChildScrollView>(scrollFinder).controller!;
      expect(controller.position.maxScrollExtent, greaterThan(50.0));
      expect(
        controller.offset,
        closeTo(controller.position.maxScrollExtent, 0.5),
      );

      // User drags down (scrolls up away from bottom by > 24 px)
      await tester.drag(scrollFinder, const Offset(0, 120));
      await tester.pump();

      final double pausedOffset = controller.offset;
      expect(
        controller.position.maxScrollExtent - pausedOffset,
        greaterThan(24.0),
      );

      // New streamed thoughts arrive -> offset stays paused for reading
      outerSetState(() {
        thoughts = '$thoughts\nNew line A: should not yank user scroll.\nNew line B: still reading.';
      });
      await tester.pump();

      expect(controller.offset, closeTo(pausedOffset, 0.5));

      // User scrolls back down near the bottom (<= 24 px)
      await tester.drag(scrollFinder, const Offset(0, -300));
      await tester.pump();
      expect(
        controller.position.maxScrollExtent - controller.offset,
        lessThanOrEqualTo(24.0),
      );

      // Next streamed token resumes auto-follow to new maxScrollExtent
      outerSetState(() {
        thoughts = '$thoughts\nNew line C: auto-follow resumed.';
      });
      await tester.pump();

      expect(
        controller.offset,
        closeTo(controller.position.maxScrollExtent, 0.5),
      );
    });
  });
}
