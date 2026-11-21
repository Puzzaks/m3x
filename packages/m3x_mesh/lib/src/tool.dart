import 'dart:async';

/// Handler callback signature for tool executions.
typedef M3xToolHandler = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> args,
);

/// Represents an agentic tool in the M3x Mesh ecosystem conforming to
/// Model Context Protocol (MCP) and OpenAPI 3.0 tool calling specifications.
class M3xTool {
  /// The unique name of the tool (e.g. `ping_host`, `get_high_score`).
  final String name;

  /// Human and LLM-facing description explaining what the tool does and when to invoke it.
  final String description;

  /// Standard JSON Schema object defining parameter types, properties, and required fields.
  final Map<String, dynamic> parameters;

  /// The executable implementation callback for this tool.
  final M3xToolHandler? handler;

  /// Optional owning or target application identifier (e.g. `'ptk'`, `'the2k48'`, `'geminilocal'`).
  final String? app;

  /// Optional exact reverse-DNS Android package name (e.g. `'page.puzzak.ptk'`, `'com.example.foo'`).
  final String? packageName;

  const M3xTool({
    required this.name,
    required this.description,
    this.parameters = const <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
    },
    this.handler,
    this.app,
    this.packageName,
  });

  /// Creates a tool from a serialized schema definition.
  factory M3xTool.fromJson(
    Map<String, dynamic> json, {
    M3xToolHandler? handler,
    String? app,
    String? packageName,
  }) {
    final rawParams = json['parameters'] ?? json['inputSchema'] ?? const <String, dynamic>{};
    final Map<String, dynamic> parsedParams;
    if (rawParams is Map<String, dynamic>) {
      parsedParams = rawParams;
    } else if (rawParams is Map) {
      parsedParams = Map<String, dynamic>.from(rawParams);
    } else {
      parsedParams = const <String, dynamic>{'type': 'object', 'properties': <String, dynamic>{}};
    }

    return M3xTool(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      parameters: parsedParams,
      handler: handler,
      app: app ?? json['app']?.toString(),
      packageName: packageName ?? json['packageName']?.toString(),
    );
  }

  /// Serializes tool specification into MCP / OpenAPI JSON format.
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters,
        'inputSchema': parameters, // MCP standard alias
        if (app != null) 'app': app,
        if (packageName != null) 'packageName': packageName,
      };

  /// Validates input arguments against the tool's JSON Schema.
  ///
  /// Returns a list of error strings. If valid, the list is empty.
  List<String> validateArguments(Map<String, dynamic> args) {
    final errors = <String>[];

    // 1. Validate required fields
    final requiredFields = parameters['required'];
    if (requiredFields is List) {
      for (final req in requiredFields) {
        final reqKey = req.toString();
        if (!args.containsKey(reqKey) || args[reqKey] == null) {
          errors.add("Missing required parameter: '$reqKey'");
        }
      }
    }

    // 2. Validate property types if declared
    final properties = parameters['properties'];
    if (properties is Map) {
      for (final entry in properties.entries) {
        final propKey = entry.key.toString();
        final propDef = entry.value;

        if (args.containsKey(propKey) && args[propKey] != null && propDef is Map) {
          final val = args[propKey];
          final expectedType = propDef['type']?.toString().toLowerCase();

          switch (expectedType) {
            case 'string':
              if (val is! String) {
                errors.add("Parameter '$propKey' must be of type string (got ${val.runtimeType})");
              }
              break;
            case 'integer':
              if (val is! int) {
                errors.add("Parameter '$propKey' must be of type integer (got ${val.runtimeType})");
              }
              break;
            case 'number':
              if (val is! num) {
                errors.add("Parameter '$propKey' must be of type number (got ${val.runtimeType})");
              }
              break;
            case 'boolean':
              if (val is! bool) {
                errors.add("Parameter '$propKey' must be of type boolean (got ${val.runtimeType})");
              }
              break;
            case 'array':
              if (val is! List) {
                errors.add("Parameter '$propKey' must be of type array (got ${val.runtimeType})");
              }
              break;
            case 'object':
              if (val is! Map) {
                errors.add("Parameter '$propKey' must be of type object (got ${val.runtimeType})");
              }
              break;
          }
        }
      }
    }

    return errors;
  }

  /// Executes the tool handler with parameter validation.
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> args) async {
    final validationErrors = validateArguments(args);
    if (validationErrors.isNotEmpty) {
      throw ArgumentError('Validation failed: ${validationErrors.join(', ')}');
    }

    if (handler == null) {
      throw StateError("Tool '$name' has no executable handler registered.");
    }

    return await handler!(args);
  }

  @override
  String toString() => 'M3xTool(name: $name, description: $description)';
}
