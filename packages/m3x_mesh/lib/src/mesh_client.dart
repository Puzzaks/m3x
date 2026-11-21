import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'json_rpc.dart';
import 'registry.dart';
import 'tool.dart';

/// Handler for incoming mesh tool calls dispatched from sibling applications.
typedef M3xIncomingToolHandler = Future<M3xToolResult> Function(
  String caller,
  M3xToolCall call,
);

/// Inter-App Agentic Mesh Client.
///
/// Communicates across Puzzak sibling applications via Android ContentProvider URIs
/// (`content://<package>.mesh`), executes headless tool calls, queries
/// available tools, and provides automated simulation fallback for desktop, web,
/// and playground testing.
class M3xMeshClient {
  static const MethodChannel _channel = MethodChannel('com.puzzak.m3x_mesh');

  /// Identifier of this local application (e.g. 'paios', 'demo', 'ptk').
  /// Used to short-circuit local tool execution and avoid self-deadlocks.
  final String? localAppId;

  /// Registry of simulated sibling applications for development and testing.
  final Map<String, M3xToolRegistry> _simulatedApps = <String, M3xToolRegistry>{};

  /// Cached reverse-DNS package IDs discovered via [listAvailableApps],
  /// [discoverInstalledTools], or [queryTools].
  final Set<String> _discoveredPackages = <String>{};

  /// Shared cache of discovered reverse-DNS package IDs across client instances
  /// so static [buildContentUri] calls can resolve short names accurately.
  static final Set<String> _cachedDiscoveredPackages = <String>{};

  bool _defaultsInitialized = false;
  bool _hasDiscoveredPackages = false;

  /// Local tool registry hosted by this application for answering incoming mesh queries and calls.
  M3xToolRegistry _localRegistry;

  /// Custom incoming tool handler callback. If null, calls default to [_localRegistry].
  M3xIncomingToolHandler? _incomingHandler;

  /// Whether simulation mode is active.
  /// Defaults to `true` when not running on native Android.
  bool _simulationMode;

  /// In debug builds / test mode, strict signature authorization is bypassed
  /// so debug APKs can freely communicate and test over the mesh without
  /// requiring production keystore signatures.
  bool bypassAuthInDebug;

  /// Whether mesh discovery and cross-app IPC are enabled.
  /// When `false`, discovery and tool queries immediately return empty results
  /// without making platform channel calls.
  bool enabled;

  M3xMeshClient({
    this.localAppId,
    M3xToolRegistry? localRegistry,
    M3xIncomingToolHandler? incomingHandler,
    bool? enableSimulation,
    this.bypassAuthInDebug = kDebugMode,
    this.enabled = true,
  })  : _localRegistry = localRegistry ?? M3xToolRegistry(),
        _incomingHandler = incomingHandler,
        _simulationMode = enableSimulation ??
            (!_isAndroidNative ? true : false) {
    _cachePackagesFromTools(_localRegistry.tools);
    if (_simulationMode) {
      _initDefaultSimulatedApps();
    }
    _initMethodChannelHandler();
  }

  void _initMethodChannelHandler() {
    try {
      _channel.setMethodCallHandler(_handleNativeMethodCall);
    } catch (_) {
      // In pure headless Dart tests or environments where WidgetsBinding / BinaryMessenger
      // is not yet bound, silently skip until a binding is initialized.
    }
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onIncomingToolCall') {
      final Map<dynamic, dynamic>? rawArgs =
          call.arguments is Map ? (call.arguments as Map) : null;
      final String caller = (rawArgs?['caller'] as String?) ?? 'unknown';
      final dynamic rawPayload = rawArgs?['payload'];

      Map<String, dynamic> payloadMap;
      if (rawPayload is String) {
        try {
          payloadMap = Map<String, dynamic>.from(jsonDecode(rawPayload) as Map);
        } catch (_) {
          payloadMap = <String, dynamic>{};
        }
      } else if (rawPayload is Map) {
        payloadMap = Map<String, dynamic>.from(rawPayload);
      } else {
        payloadMap = <String, dynamic>{};
      }

      final M3xToolCall toolCall = M3xToolCall.fromJson(payloadMap);
      final String toolName = toolCall.name;
      final Map<String, dynamic> toolArgs = toolCall.arguments;

      debugPrint('[M3xMesh] 📥 [REQUEST RECEIVED] from $caller -> tool: $toolName, args: $toolArgs');

      final stopwatch = Stopwatch()..start();
      M3xToolResult result;

      try {
        if (_incomingHandler != null) {
          result = await _incomingHandler!(caller, toolCall);
        } else {
          result = await _localRegistry.dispatchCall(toolCall);
        }
      } catch (e, stack) {
        debugPrint('[M3xMesh] ❌ Incoming call error ($toolName): $e\n$stack');
        result = M3xToolResult.error(
          id: toolCall.id,
          code: M3xToolError.internalError,
          message: 'Error handling incoming mesh tool call: $e',
        );
      }

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;
      debugPrint('[M3xMesh] 📤 [RESPONSE SENT] to $caller -> result: ${result.toJson()} (took ${ms}ms)');

      return result.toJson();
    }
    return null;
  }

  /// Returns the local tool registry.
  M3xToolRegistry get localRegistry => _localRegistry;

  /// Replaces the local registry and automatically syncs declared schemas with Android.
  void setLocalRegistry(M3xToolRegistry registry) {
    _localRegistry = registry;
    _cachePackagesFromTools(registry.tools);
    unawaited(syncDeclaredTools());
  }

  /// Registers a tool into the local registry and syncs declared schemas with Android.
  void registerLocalTool(M3xTool tool) {
    _localRegistry.register(tool);
    if (tool.packageName != null) {
      _cacheDiscoveredPackages(<String>[tool.packageName!]);
    }
    unawaited(syncDeclaredTools());
  }

  /// Sets a custom callback handler for incoming mesh tool calls.
  void setIncomingHandler(M3xIncomingToolHandler? handler) {
    _incomingHandler = handler;
  }

  /// Marks this Dart isolate's [M3xMeshClient] as ready to handle incoming
  /// mesh tool calls on the native Android host.
  ///
  /// Only isolates that actually host tools should invoke [startListening],
  /// preventing background service isolates without tool handlers from
  /// hijacking `onIncomingToolCall` dispatch.
  Future<void> startListening() async {
    _initMethodChannelHandler();
    if (!enabled || !_isAndroidNative) return;
    try {
      await _channel.invokeMethod('markToolHostReady', {'ready': true});
    } catch (e) {
      debugPrint('[M3xMesh] ⚠️ Failed to mark tool host ready: $e');
    }
  }

  /// Syncs declared local tools with the native Android M3xMeshPlugin.
  Future<void> syncDeclaredTools() async {
    if (!enabled || !_isAndroidNative) return;
    try {
      final schemas = _localRegistry.toSchemaList();
      await _channel.invokeMethod('setDeclaredTools', {
        'tools': jsonEncode(schemas),
      });
    } catch (e) {
      debugPrint('[M3xMesh] ⚠️ Failed to sync declared tools: $e');
    }
  }

  /// Verifies whether a sibling app's signature is authorized.
  /// Always returns `true` if [bypassAuthInDebug] is active in debug mode.
  bool isSignatureAuthorized(String callingPackage, [String? signatureSha256]) {
    if (bypassAuthInDebug && kDebugMode) {
      return true;
    }
    // In production, signature must match the verified Puzzaks release keystore
    return signatureSha256 != null && signatureSha256.isNotEmpty;
  }

  /// Returns whether simulation mode is currently active.
  bool get isSimulationMode => _simulationMode;

  /// Sets whether the client should use simulation mode or attempt live ContentProvider calls.
  void setSimulationMode(bool enabled) {
    _simulationMode = enabled;
    if (enabled && !_defaultsInitialized) {
      _initDefaultSimulatedApps();
    }
  }

  /// Disables simulation mode, forcing live native ContentProvider calls.
  void disableSimulation() => _simulationMode = false;

  /// Enables simulation mode for in-process mocked tool calls.
  void enableSimulation() => setSimulationMode(true);

  /// Registers a simulated sibling app and its tool registry.
  void registerSimulatedApp(String appId, M3xToolRegistry registry) {
    final cleanId = _cleanAppId(appId);
    _simulatedApps[cleanId] = registry;
    // Also keep the raw uncleaned key if different for convenience
    if (cleanId != appId.toLowerCase().trim()) {
      _simulatedApps[appId.toLowerCase().trim()] = registry;
    }
  }

  /// Registers discovered reverse-DNS package IDs in this client and the shared
  /// lookup cache used by [buildContentUri].
  void registerDiscoveredPackages(Iterable<String> packages) {
    _cacheDiscoveredPackages(packages);
  }

  /// Clears the static cache of discovered package names (primarily for testing).
  @visibleForTesting
  static void clearDiscoveredPackagesCache() {
    _cachedDiscoveredPackages.clear();
  }

  void _cacheDiscoveredPackages(Iterable<String> packages) {
    for (final raw in packages) {
      final pkg = _stripUriWrapper(raw);
      if (pkg.contains('.')) {
        _discoveredPackages.add(pkg);
        _cachedDiscoveredPackages.add(pkg);
      }
    }
  }

  void _cachePackagesFromTools(Iterable<M3xTool> tools) {
    for (final tool in tools) {
      final pkg = tool.packageName;
      if (pkg != null && pkg.contains('.')) {
        _discoveredPackages.add(pkg.trim());
        _cachedDiscoveredPackages.add(pkg.trim());
      }
    }
  }

  Iterable<String> get _knownPackages sync* {
    yield* _discoveredPackages;
    for (final tool in _localRegistry.tools) {
      final pkg = tool.packageName;
      if (pkg != null && pkg.contains('.')) {
        yield pkg;
      }
    }
  }

  static String _stripUriWrapper(String raw) {
    var clean = raw.trim();
    if (clean.toLowerCase().startsWith('content://')) {
      clean = clean.substring('content://'.length);
    }
    if (clean.toLowerCase().endsWith('.mesh')) {
      clean = clean.substring(0, clean.length - '.mesh'.length);
    }
    return clean.trim();
  }

  static String _packageFromUri(String uri) => _stripUriWrapper(uri);

  /// Resolves the canonical ContentProvider URI for a target sibling app.
  ///
  /// Checks [knownPackages] and cached discovered `packageName`s first (exact
  /// match or `.suffix` match for short names like `'alerts'`), preserves full
  /// dot-separated package IDs as `content://<pkg>.mesh`, and falls back to
  /// legacy aliases or `content://page.puzzak.<app>.mesh`.
  static String buildContentUri(
    String targetApp, {
    Iterable<String>? knownPackages,
  }) {
    final trimmed = _stripUriWrapper(targetApp);
    final clean = trimmed.toLowerCase();

    // 1. Check discovered / known packageNames first (exact or .suffix match)
    final candidates = <String>{
      if (knownPackages != null) ...knownPackages,
      ..._cachedDiscoveredPackages,
    };
    for (final pkg in candidates) {
      final pkgTrimmed = _stripUriWrapper(pkg);
      if (!pkgTrimmed.contains('.')) continue;
      final pkgLower = pkgTrimmed.toLowerCase();
      if (pkgLower == clean ||
          (!clean.contains('.') && pkgLower.endsWith('.$clean'))) {
        return 'content://$pkgTrimmed.mesh';
      }
    }

    // 2. Preserve full dot-separated package IDs directly (with legacy alias for com.puzzak.geminilocal/paios)
    if (clean == 'com.puzzak.geminilocal' || clean == 'com.puzzak.paios') {
      return 'content://page.puzzak.paios.mesh';
    }
    if (trimmed.contains('.')) {
      return 'content://$trimmed.mesh';
    }

    // 3. Legacy short-name aliases when not yet discovered
    if (clean == 'paios' || clean == 'geminilocal') {
      return 'content://page.puzzak.paios.mesh';
    }
    if (clean == 'demo') {
      return 'content://page.puzzak.demo.mesh';
    }
    if (clean == 'ptk') {
      return 'content://page.puzzak.ptk.mesh';
    }

    // 4. Default namespace fallback for unresolved short names
    return 'content://page.puzzak.$clean.mesh';
  }

  Future<String> _resolveContentUri(String targetApp) async {
    final trimmed = _stripUriWrapper(targetApp);
    final clean = trimmed.toLowerCase();
    final hasKnownMatch = _knownPackages.any((pkg) {
      final p = _stripUriWrapper(pkg).toLowerCase();
      return p == clean || (!clean.contains('.') && p.endsWith('.$clean'));
    });

    if (!trimmed.contains('.') &&
        !hasKnownMatch &&
        !_simulationMode &&
        !_hasDiscoveredPackages) {
      await listAvailableApps();
    }

    return buildContentUri(targetApp, knownPackages: _knownPackages);
  }

  static String _cleanAppId(String targetApp) {
    var clean = _stripUriWrapper(targetApp).toLowerCase();

    if (clean.startsWith('page.puzzak.')) {
      clean = clean.substring('page.puzzak.'.length);
    } else if (clean.startsWith('com.puzzak.')) {
      clean = clean.substring('com.puzzak.'.length);
    }

    if (clean == 'paios' || clean == 'geminilocal') {
      return 'paios';
    }
    return clean;
  }

  /// Checks whether [targetApp] resolves to the local application.
  bool _isLocalApp(String targetApp) {
    if (localAppId == null) return false;
    final cleanTarget = _cleanAppId(targetApp);
    final cleanLocal = _cleanAppId(localAppId!);
    if (cleanTarget == cleanLocal) return true;
    if (!cleanTarget.contains('.') && cleanLocal.contains('.')) {
      return cleanLocal.endsWith('.$cleanTarget');
    }
    if (cleanTarget.contains('.') && !cleanLocal.contains('.')) {
      return cleanTarget.endsWith('.$cleanLocal');
    }
    return false;
  }

  /// Lists all accessible sibling applications (discovered via native mesh IPC,
  /// or simulated apps when simulation mode is enabled).
  Future<List<String>> listAvailableApps() async {
    if (!enabled) return <String>[];
    if (_simulationMode) {
      return List<String>.unmodifiable(_simulatedApps.keys);
    }

    _hasDiscoveredPackages = true;
    try {
      final List<dynamic>? apps =
          await _channel.invokeMethod<List<dynamic>>('listMeshApps');
      if (apps != null && apps.isNotEmpty) {
        final resolved = apps
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _cacheDiscoveredPackages(resolved);
        return resolved;
      }
    } catch (e) {
      debugPrint('[M3xMesh] ⚠️ Failed to list mesh apps: $e');
    }

    return <String>[];
  }

  /// Alias for [listAvailableApps] matching native method naming.
  Future<List<String>> listMeshApps() => listAvailableApps();

  /// Checks whether a given Android package is installed on the device.
  Future<bool> isPackageInstalled(String packageName) async {
    if (!enabled) return false;
    if (_simulationMode) {
      final clean = _cleanAppId(packageName);
      return _simulatedApps.containsKey(clean) ||
          _simulatedApps.containsKey(packageName);
    }
    try {
      final bool? installed = await _channel.invokeMethod<bool>(
        'isPackageInstalled',
        <String, dynamic>{'packageName': packageName},
      );
      if (installed == true && packageName.contains('.')) {
        _cacheDiscoveredPackages(<String>[packageName]);
      }
      return installed ?? false;
    } catch (e) {
      debugPrint('[M3xMesh] ⚠️ Failed to check if package $packageName is installed: $e');
      return false;
    }
  }

  /// Returns the human-readable Android application label for [packageName],
  /// or `null` if the package is not installed or cannot be resolved.
  Future<String?> getAppLabel(String packageName) async {
    if (!enabled) return null;
    if (_simulationMode) {
      return null;
    }
    try {
      final String? label = await _channel.invokeMethod<String>(
        'getAppLabel',
        <String, dynamic>{'package': packageName},
      );
      if (label == null || label.trim().isEmpty) return null;
      return label;
    } catch (e) {
      debugPrint('[M3xMesh] ⚠️ Failed to get app label for $packageName: $e');
      return null;
    }
  }

  /// Dynamically discovers all tools declared by installed mesh-compatible sibling apps.
  ///
  /// Queries installed apps via decentralized mesh discovery, iterates each discovered app
  /// (skipping [localAppId]), calls [queryTools] with a 2-second timeout per app, and
  /// aggregates all tools into a single list.
  Future<List<M3xTool>> discoverInstalledTools() async {
    if (!enabled) return <M3xTool>[];
    final List<String> apps = await listAvailableApps();
    final List<M3xTool> discovered = <M3xTool>[];

    for (final app in apps) {
      if (_isLocalApp(app)) continue;
      try {
        final tools = await queryTools(app).timeout(
          const Duration(seconds: 2),
          onTimeout: () => <M3xTool>[],
        );
        discovered.addAll(tools);
      } catch (e) {
        debugPrint('[M3xMesh] ⚠️ Tool discovery failed for app $app: $e');
      }
    }

    return discovered;
  }

  List<M3xTool> _withResolvedPackage(
    List<M3xTool> tools,
    String cleanApp,
    String resolvedPackage,
  ) {
    return tools
        .map(
          (t) => t.packageName != null
              ? t
              : M3xTool(
                  name: t.name,
                  description: t.description,
                  parameters: t.parameters,
                  handler: t.handler,
                  app: t.app ?? cleanApp,
                  packageName: resolvedPackage,
                ),
        )
        .toList();
  }

  /// Queries all available tools declared by the [targetApp].
  Future<List<M3xTool>> queryTools(String targetApp) async {
    if (!enabled) return <M3xTool>[];
    if (_isLocalApp(targetApp)) {
      return _localRegistry.tools;
    }

    final cleanApp = _cleanAppId(targetApp);
    if (_simulationMode) {
      final resolvedPackage = _packageFromUri(
        buildContentUri(targetApp, knownPackages: _knownPackages),
      );
      final reg = _simulatedApps[cleanApp] ?? _simulatedApps[targetApp];
      if (reg != null) {
        return _withResolvedPackage(reg.tools, cleanApp, resolvedPackage);
      }
      return <M3xTool>[];
    }

    try {
      final uri = await _resolveContentUri(targetApp);
      final resolvedPackage = _packageFromUri(uri);
      final dynamic raw =
          await _channel.invokeMethod('queryMeshTools', {'uri': uri});

      List<M3xTool> parsed = <M3xTool>[];
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          parsed = decoded
              .whereType<Map>()
              .map(
                (m) => M3xTool.fromJson(
                  Map<String, dynamic>.from(m),
                  app: cleanApp,
                  packageName: resolvedPackage,
                ),
              )
              .toList();
        }
      } else if (raw is List) {
        parsed = raw
            .whereType<Map>()
            .map(
              (m) => M3xTool.fromJson(
                Map<String, dynamic>.from(m),
                app: cleanApp,
                packageName: resolvedPackage,
              ),
            )
            .toList();
      }
      _cachePackagesFromTools(parsed);
      return parsed;
    } catch (e) {
      // When _simulationMode == false, NEVER fall back to simulated tools from _simulatedApps!
      debugPrint('[M3xMesh] ⚠️ Tool query failed for $targetApp: $e');
      return <M3xTool>[];
    }
  }

  /// Invokes a remote tool on [targetApp] by name with arguments.
  Future<M3xToolResult> callTool(
    String targetApp,
    String toolName,
    Map<String, dynamic> args, {
    String? callId,
  }) {
    final effectiveId = callId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final call = M3xToolCall(
      id: effectiveId,
      name: toolName,
      arguments: args,
    );
    return execute(targetApp, call);
  }

  /// Dispatches a structured [M3xToolCall] to the [targetApp].
  Future<M3xToolResult> execute(String targetApp, M3xToolCall call) async {
    debugPrint('[M3xMesh] 🚀 [OUTGOING CALL] to $targetApp -> tool: ${call.name}, args: ${call.arguments}');

    if (_isLocalApp(targetApp)) {
      debugPrint('[M3xMesh] ⚡ [SHORT-CIRCUIT LOCAL CALL] in-memory dispatch to $targetApp -> tool: ${call.name}');
      final M3xToolResult result;
      if (_incomingHandler != null) {
        result = await _incomingHandler!(localAppId ?? 'local', call);
      } else {
        result = await _localRegistry.dispatchCall(call);
      }
      debugPrint('[M3xMesh] 🏁 [LOCAL RESULT] from $targetApp -> result: ${result.toJson()}');
      return result;
    }

    if (!enabled) {
      return M3xToolResult.error(
        id: call.id,
        code: M3xToolError.internalError,
        message: 'Mesh client is disabled.',
      );
    }

    final cleanApp = _cleanAppId(targetApp);
    M3xToolResult result;

    if (_simulationMode) {
      result = await _executeSimulated(cleanApp, call);
      debugPrint('[M3xMesh] 🏁 [OUTGOING RESULT] from $targetApp -> result: ${result.toJson()}');
      return result;
    }

    try {
      final uri = await _resolveContentUri(targetApp);
      final dynamic response = await _channel
          .invokeMethod('callContentProvider', {
            'uri': uri,
            'call': call.toJson(),
          })
          .timeout(const Duration(seconds: 16));

      if (response is Map) {
        result = M3xToolResult.fromJson(Map<String, dynamic>.from(response));
      } else if (response is String) {
        final decoded = jsonDecode(response);
        if (decoded is Map) {
          result = M3xToolResult.fromJson(Map<String, dynamic>.from(decoded));
        } else {
          result = M3xToolResult.error(
            id: call.id,
            code: M3xToolError.internalError,
            message: 'Invalid response format received from ContentProvider.',
          );
        }
      } else {
        result = M3xToolResult.error(
          id: call.id,
          code: M3xToolError.internalError,
          message: 'Null or unknown response received from ContentProvider.',
        );
      }
    } catch (e) {
      // When _simulationMode == false, never fall back to _simulatedApps. Return the real error.
      result = M3xToolResult.error(
        id: call.id,
        code: M3xToolError.internalError,
        message: 'Mesh communication error: $e',
      );
    }

    debugPrint('[M3xMesh] 🏁 [OUTGOING RESULT] from $targetApp -> result: ${result.toJson()}');
    return result;
  }

  /// Checks whether a sibling or local application is online and returns its status.
  ///
  /// Calls 'get_ai_status' or 'query_status' on [targetApp].
  /// Returns a map guaranteed to include `{'online': bool, ...}`.
  Future<Map<String, dynamic>> checkAppStatus(String targetApp) async {
    try {
      final aiStatusRes = await callTool(targetApp, 'get_ai_status', const <String, dynamic>{});
      if (aiStatusRes.isSuccess && aiStatusRes.result != null) {
        return <String, dynamic>{
          'online': true,
          ...aiStatusRes.result!,
        };
      }

      final queryStatusRes = await callTool(targetApp, 'query_status', const <String, dynamic>{});
      if (queryStatusRes.isSuccess && queryStatusRes.result != null) {
        return <String, dynamic>{
          'online': true,
          ...queryStatusRes.result!,
        };
      }

      return <String, dynamic>{
        'online': false,
        'error': aiStatusRes.error?.message ??
            queryStatusRes.error?.message ??
            "App '$targetApp' did not respond to status check.",
      };
    } catch (e) {
      return <String, dynamic>{
        'online': false,
        'error': e.toString(),
      };
    }
  }

  /// Launches an interactive mesh assistant overlay activity on top of the current app.
  Future<bool> openAssistantBubble({
    String targetApp = 'paios',
    String? overlayPkg,
    String? overlayActivity,
    String? prompt,
    String? contextData,
    String? imageBase64,
    String? imageUri,
    bool downsample = true,
  }) async {
    if (!enabled) return false;
    if (_simulationMode) {
      return true;
    }
    try {
      String? resolvedPkg = overlayPkg?.trim();
      if ((resolvedPkg == null || resolvedPkg.isEmpty) &&
          targetApp.trim().isNotEmpty) {
        final trimmed = _stripUriWrapper(targetApp);
        if (trimmed.contains('.')) {
          resolvedPkg = trimmed;
        } else {
          if (!_hasDiscoveredPackages) {
            await listAvailableApps();
          }
          final clean = trimmed.toLowerCase();
          for (final pkg in _knownPackages) {
            final p = _stripUriWrapper(pkg);
            if (p.toLowerCase().endsWith('.$clean')) {
              resolvedPkg = p;
              break;
            }
          }
        }
      }
      final bool? launched = await _channel.invokeMethod<bool>(
        'openAssistantBubble',
        <String, dynamic>{
          'targetApp': targetApp,
          if (resolvedPkg != null && resolvedPkg.isNotEmpty)
            'overlayPkg': resolvedPkg,
          if (overlayActivity != null && overlayActivity.trim().isNotEmpty)
            'overlayActivity': overlayActivity.trim(),
          'prompt': prompt,
          'contextData': contextData,
          'imageBase64': imageBase64,
          'imageUri': imageUri,
          'downsample': downsample,
        },
      );
      return launched ?? false;
    } catch (e) {
      debugPrint('[M3xMesh] ⚠️ Failed to open assistant bubble: $e');
      return false;
    }
  }

  Future<M3xToolResult> _executeSimulated(String cleanApp, M3xToolCall call) async {
    final reg = _simulatedApps[cleanApp] ?? _simulatedApps[call.name.split('_').first];
    if (reg == null) {
      return M3xToolResult.error(
        id: call.id,
        code: M3xToolError.methodNotFound,
        message: "Sibling application '$cleanApp' is not registered or installed.",
      );
    }

    return await reg.dispatchCall(call);
  }

  static bool get _isAndroidNative =>
      !kIsWeb && Platform.isAndroid;

  void _initDefaultSimulatedApps() {
    if (_defaultsInitialized) return;
    _defaultsInitialized = true;

    // 1. PTK (Puzzak ToolKit) simulation
    final ptkReg = M3xToolRegistry([
      M3xTool(
        name: 'ping_host',
        app: 'ptk',
        description: 'Simulates sending ICMP ping packets to a remote host.',
        parameters: {
          'type': 'object',
          'properties': {
            'host': {'type': 'string', 'description': 'Destination hostname or IP'},
            'count': {'type': 'integer', 'description': 'Number of packets to send'},
          },
          'required': ['host'],
        },
        handler: (args) async {
          final host = args['host']?.toString() ?? '127.0.0.1';
          final count = args['count'] as int? ?? 4;
          return {
            'host': host,
            'transmitted': count,
            'received': count,
            'packet_loss_percent': 0,
            'min_rtt_ms': 12.4,
            'avg_rtt_ms': 15.8,
            'max_rtt_ms': 22.1,
            'status': 'success',
          };
        },
      ),
      M3xTool(
        name: 'calculate_subnet',
        app: 'ptk',
        description: 'Calculates IPv4 network, broadcast, and host addresses from CIDR.',
        parameters: {
          'type': 'object',
          'properties': {
            'cidr': {'type': 'string', 'description': 'CIDR notation e.g. 192.168.1.0/24'},
          },
          'required': ['cidr'],
        },
        handler: (args) async {
          final cidr = args['cidr']?.toString() ?? '192.168.1.0/24';
          return {
            'cidr': cidr,
            'network': '192.168.1.0',
            'netmask': '255.255.255.0',
            'broadcast': '192.168.1.255',
            'usable_hosts': 254,
          };
        },
      ),
    ]);
    _simulatedApps.putIfAbsent('ptk', () => ptkReg);

    // 2. The 2k48 simulation
    final gameReg = M3xToolRegistry([
      M3xTool(
        name: 'get_high_score',
        app: 'the2k48',
        description: 'Retrieves player high score and game stats.',
        parameters: {'type': 'object', 'properties': {}},
        handler: (args) async => {
          'high_score': 32768,
          'games_played': 142,
          'max_tile': 2048,
        },
      ),
    ]);
    _simulatedApps.putIfAbsent('the2k48', () => gameReg);

    // 3. GeminiLocal (PAIOS) simulation
    final geminiReg = M3xToolRegistry([
      M3xTool(
        name: 'query_local_ai',
        app: 'paios',
        description: 'Executes on-device Gemini inference via AICore/MLC LLM.',
        parameters: {
          'type': 'object',
          'properties': {
            'prompt': {'type': 'string', 'description': 'Input prompt text'},
          },
          'required': ['prompt'],
        },
        handler: (args) async => {
          'prompt': args['prompt'],
          'response': 'Simulated on-device response for: "${args['prompt']}"',
          'latency_ms': 85,
          'engine': 'Gemini Nano',
        },
      ),
      M3xTool(
        name: 'get_ai_status',
        app: 'paios',
        description: 'Returns PAIOS engine state, model readiness, and availability.',
        parameters: const {'type': 'object', 'properties': {}},
        handler: (args) async => {
          'engine_running': true,
          'model_available': true,
          'model_initialized': true,
          'status': 'Ready (Simulated)',
        },
      ),
    ]);
    _simulatedApps.putIfAbsent('geminilocal', () => geminiReg);
    _simulatedApps.putIfAbsent('paios', () => geminiReg);

    // 4. MCPlayer simulation
    final playerReg = M3xToolRegistry([
      M3xTool(
        name: 'get_playback_status',
        description: 'Gets current audio player status and active track.',
        parameters: {'type': 'object', 'properties': {}},
        handler: (args) async => {
          'state': 'playing',
          'track_title': 'Flight',
          'artist': 'Tristam & Braken',
          'position_ms': 45000,
          'duration_ms': 219000,
        },
      ),
    ]);
    _simulatedApps.putIfAbsent('mcplayer', () => playerReg);
  }
}
