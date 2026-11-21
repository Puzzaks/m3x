import 'dart:convert';

/// Represents a standard JSON-RPC 2.0 error payload.
class M3xToolError {
  /// Standard JSON-RPC 2.0 error codes.
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  /// Error code number.
  final int code;

  /// Human-readable short message.
  final String message;

  /// Optional contextual data or stack trace.
  final dynamic data;

  const M3xToolError({
    required this.code,
    required this.message,
    this.data,
  });

  factory M3xToolError.fromJson(Map<String, dynamic> json) {
    return M3xToolError(
      code: json['code'] as int? ?? internalError,
      message: json['message']?.toString() ?? 'Unknown error',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() => 'M3xToolError($code: $message)';
}

/// Represents a JSON-RPC 2.0 tool invocation request.
class M3xToolCall {
  /// Unique invocation ID.
  final String id;

  /// Name of the tool / method being invoked.
  final String name;

  /// Key-value arguments matching tool schema.
  final Map<String, dynamic> arguments;

  /// Optional target sibling app identifier (e.g. 'ptk', 'the2k48', 'geminilocal').
  final String? app;

  /// Optional human-readable description of what the model is doing (e.g. 'Reading documentation').
  final String? description;

  /// Alias for [name] conforming to `{"tool": "..."}` syntax.
  String get tool => name;

  /// JSON-RPC protocol version (always "2.0").
  final String jsonrpc;

  const M3xToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.app,
    this.description,
    this.jsonrpc = '2.0',
  });

  factory M3xToolCall.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'] ?? json['arguments'] ?? json['args'];
    Map<String, dynamic> parsedArguments;
    if (rawParams is Map<String, dynamic>) {
      parsedArguments = rawParams;
    } else if (rawParams is Map) {
      parsedArguments = Map<String, dynamic>.from(rawParams);
    } else if (rawParams is String && rawParams.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawParams);
        parsedArguments = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
      } catch (_) {
        parsedArguments = <String, dynamic>{};
      }
    } else {
      parsedArguments = <String, dynamic>{};
    }

    final rawTool = json['tool'];
    final hasToolKey = rawTool is String && rawTool.trim().isNotEmpty;
    if (parsedArguments.isEmpty && hasToolKey) {
      const protocolKeys = <String>{
        'tool',
        'app',
        'args',
        'arguments',
        'params',
        'action',
        'method',
        'description',
        'id',
        'name',
        'jsonrpc',
      };
      final lifted = <String, dynamic>{};
      for (final entry in json.entries) {
        if (!protocolKeys.contains(entry.key)) {
          lifted[entry.key] = entry.value;
        }
      }
      if (lifted.isNotEmpty) {
        parsedArguments = lifted;
      }
    }

    final toolName = json['method']?.toString() ??
        json['name']?.toString() ??
        json['tool']?.toString() ??
        '';
    final targetApp = json['app']?.toString();
    final desc = json['description']?.toString();
    final idStr = json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString();

    return M3xToolCall(
      id: idStr,
      name: toolName,
      arguments: parsedArguments,
      app: targetApp,
      description: desc,
      jsonrpc: json['jsonrpc']?.toString() ?? '2.0',
    );
  }

  Map<String, dynamic> toJson() => {
        'jsonrpc': jsonrpc,
        'id': id,
        'method': name,
        'params': arguments,
        if (app != null) 'app': app,
        if (description != null) 'description': description,
      };

  @override
  String toString() => 'M3xToolCall(id: $id, app: $app, name: $name, args: $arguments)';
}

/// Represents the structured result of a tool invocation.
class M3xToolResult {
  /// Matching invocation ID.
  final String id;

  /// Result map if invocation succeeded.
  final Map<String, dynamic>? result;

  /// Error if invocation failed.
  final M3xToolError? error;

  /// JSON-RPC protocol version (always "2.0").
  final String jsonrpc;

  const M3xToolResult({
    required this.id,
    this.result,
    this.error,
    this.jsonrpc = '2.0',
  });

  /// Creates a successful tool result.
  factory M3xToolResult.success({
    required String id,
    required Map<String, dynamic> result,
  }) {
    return M3xToolResult(id: id, result: result);
  }

  /// Creates an error tool result.
  factory M3xToolResult.error({
    required String id,
    required int code,
    required String message,
    dynamic data,
  }) {
    return M3xToolResult(
      id: id,
      error: M3xToolError(code: code, message: message, data: data),
    );
  }

  factory M3xToolResult.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final jsonrpc = json['jsonrpc']?.toString() ?? '2.0';

    if (json.containsKey('error') && json['error'] != null) {
      final err = json['error'];
      final errObj = err is Map<String, dynamic>
          ? M3xToolError.fromJson(err)
          : err is Map
              ? M3xToolError.fromJson(Map<String, dynamic>.from(err))
              : M3xToolError(
                  code: M3xToolError.internalError,
                  message: err.toString(),
                );
      return M3xToolResult(id: id, error: errObj, jsonrpc: jsonrpc);
    }

    final rawRes = json['result'];
    Map<String, dynamic>? parsedResult;
    if (rawRes is Map<String, dynamic>) {
      parsedResult = rawRes;
    } else if (rawRes is Map) {
      parsedResult = Map<String, dynamic>.from(rawRes);
    } else if (rawRes != null) {
      parsedResult = {'value': rawRes};
    }

    return M3xToolResult(id: id, result: parsedResult, jsonrpc: jsonrpc);
  }

  bool get isSuccess => error == null;
  bool get isError => error != null;

  Map<String, dynamic> toJson() => {
        'jsonrpc': jsonrpc,
        'id': id,
        if (result != null) 'result': result,
        if (error != null) 'error': error!.toJson(),
      };

  @override
  String toString() {
    if (isSuccess) {
      return 'M3xToolResult.success(id: $id, result: $result)';
    } else {
      return 'M3xToolResult.error(id: $id, error: $error)';
    }
  }
}
