# Changelog

## 1.1.7

- Standardized documentation and metadata to Material 3 eXtended (m3x) branding with independence disclaimer.

## 1.1.6

- Wired `M3xMeshContentProvider.headlessHandler` into `call("call_tool", ...)` when `readyHost == null && !requiresForegroundOverlay`, allowing companion apps (such as `page.puzzak.speech`) to execute native Kotlin headless tools without launching a foreground Flutter Activity or cold-booting a FlutterEngine.
- Added safe `try/catch` error handling, thread-safe `AtomicReference` + 15-second `CountDownLatch` awaiting, and `JSONObject`-escaped JSON-RPC 2.0 error responses (`buildJsonRpcError`).
- Preserved fallthrough behavior when `headlessHandler` is `null`, declines a request (`return false`), or `requiresForegroundOverlay == true`.

## 1.1.5+26111601

- Added Gemma / Gemini Nano v4 control-token tool call parsing in `M3xToolCallParser.extract` (`<ctrl\d+>call:...{...}<ctrl\d+>` and `<|tool_call|>call:...{...}`), including optional `app:tool` prefix splitting and string-aware unquoted key quoting (`_quoteUnquotedObjectKeys`) so URLs and colons inside quotes are preserved untouched.
- Added `M3xToolCallParser.stripControlToolTags(String text)` to strip control-token tool calls and stray `<ctrl\d+>` / `<|tool_call|>` markers from thought displays.
- Updated `M3xToolCallParser.looksLikeIncompleteToolCall` to detect mid-stream `<ctrl\d+>call:` / `<|tool_call|>call:` drafts.
- Added unit tests in `test/tool_call_parser_test.dart`.

## 1.1.4+26111501

- Added string-literal-aware `_repairMissingPropertyValues` pass in `M3xToolCallParser` before `_stripTrailingCommas` to repair Gemini Nano broken tool-call JSON with missing property values (`"args":}`, `"args":,`, etc.), inserting `{}` for `args`/`arguments`/`params` and `null` for other keys.
- Added string-literal-aware `_stripDanglingObjectKeys` pass in `M3xToolCallParser` to strip lone trailing valueless keys inside JSON objects directly before `}` (e.g. `{"tool": "duckduckgo_search", "args": {"query": "Puzzak"}, ""}`) without affecting valid `"key": "val"` entries or array elements `[""]`.
- Updated `M3xToolCall.fromJson` to safely lift non-protocol sibling keys into `arguments` when `"tool"` is present and explicit `args`/`arguments`/`params` is empty or omitted.
- Added unit tests in `test/tool_call_parser_test.dart` covering missing property values, dangling object keys, quoted string edge cases, and `M3xToolCall.fromJson` sibling-key lifting.

## 1.1.2+26111301

- Added `M3xToolCallParser` (`extract` and `looksLikeIncompleteToolCall`) exported from `m3x_mesh.dart` with a balanced-brace JSON scanner, support for unclosed/case-insensitive markdown fences, multiple JSON objects per turn, and small-LLM fallback tolerations (`\_` -> `_`, trailing commas, unescaped string newlines, and single-quoted keys/values).
- Removed verbose `stack.toString()` payloads from JSON-RPC `M3xToolError.data` in `M3xToolRegistry.invokeTool` and `M3xMeshClient._handleNativeMethodCall` (stack traces are now logged locally via `debugPrint`).
- Improved `M3xMeshPlugin.kt` active engine tracking to prefer the foreground `Activity`-attached engine and fall back cleanly to any surviving background engine (e.g., foreground service isolate) when the UI engine detaches.
- Added comprehensive unit tests in `test/tool_call_parser_test.dart`.

## 1.1.1+26111202

- Made `M3xMeshContentProvider` 100% generic by removing all hardcoded PTK/Demo/PAIOS tool schemas from `query_tools` and implementing a 3-tier resolution order:
  1. Live in-memory `M3xMeshPlugin.declaredToolsJson`
  2. Persisted `SharedPreferences` (`m3x_mesh_prefs` / `declared_tools`)
  3. Bundled static app asset (`flutter_assets/assets/mesh_tools.json`) with `"[]"` fallback.
- Persisted `setDeclaredTools` JSON into `SharedPreferences` (`m3x_mesh_prefs`) in `M3xMeshPlugin`.
- Added `getAppLabel` handler to `M3xMeshPlugin` and `M3xMeshClient.getAppLabel(packageName)` to resolve real Android application labels.
- Added optional `packageName` field to `M3xTool` (`toJson` / `fromJson`) and populated it during `M3xMeshClient.queryTools` to preserve exact reverse-DNS package identity.

## 1.1.0+26111201

- Added direct canonical URI mapping for PTK (`page.puzzak.ptk` -> `content://page.puzzak.ptk.mesh`) in `M3xMeshClient.buildContentUri`.
- Added `isPackageInstalled` method to `M3xMeshClient` and native Android `M3xMeshPlugin` for package probing and ContentProvider fallback checks.
- Added fallback declared tools for `page.puzzak.ptk` in `M3xMeshContentProvider` (`ptk_list_statuspages`, `ptk_get_statuspage_details`, `ptk_list_incidents`, `ptk_get_incident_details`, `ptk_ping`, `ptk_list_servers`, `ptk_get_server_telemetry`).
- Probed `page.puzzak.ptk` in `M3xMeshPlugin.listMeshApps` known packages list.

## 0.1.5+26110707

- Added `getAppIcon` method to `M3xMeshPlugin`:
  - Retrieves application icon via `packageManager.getApplicationIcon(packageName)`.
  - Supports BitmapDrawable and Adaptive/Vector drawables rendered to ARGB_8888 bitmap.
  - Compresses to PNG byte array and returns as `Uint8List` over `com.puzzak.m3x_mesh` channel.

## 0.1.0+26110702

- Transformed `m3x_mesh` into a real Flutter Android plugin with native `M3xMeshContentProvider` and `M3xMeshPlugin`.
- Added native Android ContentProvider (`com.puzzak.m3x_mesh.M3xMeshContentProvider`) listening on `${applicationId}.mesh` with exported IPC endpoints: `call_tool` and `query_tools`.
- Added bidirectional IPC between native ContentProvider and Flutter via `com.puzzak.m3x_mesh` platform channel (`onIncomingToolCall`, `callContentProvider`, `queryMeshTools`, `listMeshApps`, `setDeclaredTools`).
- Added comprehensive native (`android.util.Log.d("M3xMesh", ...)`) and Dart (`debugPrint('[M3xMesh] ...')`) request/response telemetry logs with latency benchmarking.
- Enhanced `M3xMeshClient.buildContentUri` with automatic package resolution for `page.puzzak.paios.mesh` and `page.puzzak.demo.mesh`.
- Added local tool hosting (`localRegistry`, `registerLocalTool`, `syncDeclaredTools`) enabling bidirectional agentic tool dispatch.

## 0.0.1+26110701

- Initial release of `m3x_mesh` Inter-App Agentic Mesh Protocol.
- Implements MCP / OpenAPI JSON-Schema tool definitions (`M3xTool`) with argument type validation.
- Implements `M3xToolRegistry` for tool registration, schema export, and execution.
- Implements JSON-RPC 2.0 `M3xToolCall` and `M3xToolResult` models.
- Implements `M3xAiProvider` contract and `MockAiProvider`.
- Implements `M3xMeshClient` for inter-app tool calling via Android ContentProvider URIs (`content://com.puzzak.<app>.mesh`), with built-in simulation fallback and debug signature bypass (`bypassAuthInDebug`).
