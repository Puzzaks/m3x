import 'dart:async';
import 'package:flutter/foundation.dart';
import 'json_rpc.dart';
import 'tool.dart';

/// Central registry for managing, introspecting, and executing agentic tools.
class M3xToolRegistry {
  final Map<String, M3xTool> _tools = <String, M3xTool>{};

  M3xToolRegistry([Iterable<M3xTool>? initialTools]) {
    if (initialTools != null) {
      registerAll(initialTools);
    }
  }

  /// Registers a tool into the registry, replacing any existing tool with the same name.
  void register(M3xTool tool) {
    _tools[tool.name] = tool;
  }

  /// Registers multiple tools at once.
  void registerAll(Iterable<M3xTool> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  /// Unregisters a tool by name. Returns `true` if a tool was removed.
  bool unregister(String name) {
    return _tools.remove(name) != null;
  }

  /// Looks up a registered tool by name.
  M3xTool? get(String name) => _tools[name];

  /// Checks if a tool with [name] is registered.
  bool contains(String name) => _tools.containsKey(name);

  /// Clears all registered tools.
  void clear() => _tools.clear();

  /// Returns an unmodifiable list of all registered tools.
  List<M3xTool> get tools => List<M3xTool>.unmodifiable(_tools.values);

  /// Returns an unmodifiable list of all registered tools (alias for [tools]).
  List<M3xTool> getAllTools() => tools;

  /// Returns standard MCP / OpenAPI schemas for all registered tools.
  List<Map<String, dynamic>> toSchemaList() =>
      _tools.values.map((t) => t.toJson()).toList();

  /// Invokes a tool by name with parameter validation and returns a JSON-RPC [M3xToolResult].
  Future<M3xToolResult> invokeTool(
    String name,
    Map<String, dynamic> args, {
    String? callId,
  }) async {
    final effectiveId =
        callId ?? DateTime.now().microsecondsSinceEpoch.toString();

    final tool = _tools[name];
    if (tool == null) {
      return M3xToolResult.error(
        id: effectiveId,
        code: M3xToolError.methodNotFound,
        message: "Tool '$name' not found in registry.",
      );
    }

    final validationErrors = tool.validateArguments(args);
    if (validationErrors.isNotEmpty) {
      return M3xToolResult.error(
        id: effectiveId,
        code: M3xToolError.invalidParams,
        message: 'Invalid parameters: ${validationErrors.join(', ')}',
        data: validationErrors,
      );
    }

    if (tool.handler == null) {
      return M3xToolResult.error(
        id: effectiveId,
        code: M3xToolError.internalError,
        message: "Tool '$name' has no executable handler registered.",
      );
    }

    try {
      final result = await tool.handler!(args);
      return M3xToolResult.success(
        id: effectiveId,
        result: result,
      );
    } catch (e, stack) {
      debugPrint('[M3xMesh] ❌ Tool "$name" failed: $e\n$stack');
      return M3xToolResult.error(
        id: effectiveId,
        code: M3xToolError.internalError,
        message: 'Execution error in tool $name: $e',
      );
    }
  }

  /// Dispatches a structured [M3xToolCall] request and returns the resulting [M3xToolResult].
  Future<M3xToolResult> dispatchCall(M3xToolCall call) {
    return invokeTool(call.name, call.arguments, callId: call.id);
  }
}
