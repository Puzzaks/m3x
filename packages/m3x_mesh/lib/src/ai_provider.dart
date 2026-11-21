import 'dart:async';
import 'tool.dart';

/// Abstract contract for AI / LLM inference providers within the M3x mesh.
///
/// Enables seamless swapping between on-device local models (such as Gemini Nano
/// via AICore or MLC LLM) and remote cloud providers (such as Gemini 1.5/2.0 Flash/Pro).
abstract class M3xAiProvider {
  /// Unique identifier or display name of the AI provider (e.g. `'gemini_local'`, `'gemini_cloud'`).
  String get name;

  /// Whether this provider operates completely offline on-device without internet access.
  bool get supportsLocalAi;

  /// Executes a single prompt completion request with optional tool awareness and context.
  Future<String> executePrompt(
    String prompt, {
    List<M3xTool>? tools,
    Map<String, dynamic>? context,
  });

  /// Streams token/chunk responses for real-time UI display.
  Stream<String> streamPrompt(
    String prompt, {
    List<M3xTool>? tools,
    Map<String, dynamic>? context,
  });
}

/// Simulated mock AI provider for headless tests and UI playground previewing.
class MockAiProvider implements M3xAiProvider {
  @override
  final String name;

  @override
  final bool supportsLocalAi;

  /// Optional custom handler for prompt completions.
  final FutureOr<String> Function(String prompt, List<M3xTool>? tools)?
      onExecute;

  MockAiProvider({
    this.name = 'mock_ai',
    this.supportsLocalAi = true,
    this.onExecute,
  });

  @override
  Future<String> executePrompt(
    String prompt, {
    List<M3xTool>? tools,
    Map<String, dynamic>? context,
  }) async {
    if (onExecute != null) {
      return await onExecute!(prompt, tools);
    }
    final toolsDesc = tools != null && tools.isNotEmpty
        ? ' [Tools available: ${tools.map((t) => t.name).join(', ')}]'
        : '';
    return 'Mock response to: "$prompt"$toolsDesc';
  }

  @override
  Stream<String> streamPrompt(
    String prompt, {
    List<M3xTool>? tools,
    Map<String, dynamic>? context,
  }) async* {
    final fullText =
        await executePrompt(prompt, tools: tools, context: context);
    final words = fullText.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield (i == 0 ? '' : ' ') + words[i];
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
}
