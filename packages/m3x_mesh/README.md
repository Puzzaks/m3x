# m3x_mesh

Inter-App **Agentic Mesh Protocol**, headless Android tool calling, and MCP-compatible tool schemas for the [Material 3 eXtended (`m3x`)](https://github.com/Puzzaks/m3x) ecosystem.

Allows Flutter and native Kotlin Android apps on the same device to discover each other, advertise JSON-Schema tools, and execute JSON-RPC 2.0 tool calls over Android `ContentProvider` IPC — including headless native execution without cold-booting a foreground Flutter UI.

## Features

- **MCP-Compatible Tool Registry (`M3xTool`, `M3xMeshRegistry`)**: Declare strongly-typed tool schemas (`name`, `description`, `inputSchema`, `requiresForegroundOverlay`) and bind Dart handlers.
- **Android Inter-App Mesh IPC (`M3xMeshClient`, `M3xMeshContentProvider`)**:
  - Automatic peer discovery across installed M3x-enabled apps via Android `PackageManager` provider queries.
  - Native `M3xMeshContentProvider.headlessHandler` support so companion apps can answer `call_tool` requests in pure Kotlin without launching a foreground Activity.
  - Thread-safe JSON-RPC 2.0 request/response serialization (`M3xJsonRpcRequest`, `M3xJsonRpcResponse`).
- **Multi-Format LLM Tool-Call Parser (`M3xToolCallParser`)**:
  - Parses standard JSON tool calls as well as Gemma / Gemini Nano v4 control-token tool calls (`<ctrl...>call:...{...}<ctrl...>` and `<|tool_call|>call:...{...}`), with string-aware unquoted key quoting and mid-stream incomplete detection.
- **AI Provider Contracts (`M3xAiProvider`)**: Standardized interface for plugging local or remote inference backends into the mesh.

## Usage

```dart
import 'package:m3x_mesh/m3x_mesh.dart';

final mesh = M3xMeshClient();
final peers = await mesh.discoverPeers();
final result = await mesh.callTool(
  authority: peers.first.authority,
  toolName: 'ping',
  arguments: {'echo': 'hello'},
);
```

## License

Released into the public domain under [The Unlicense](LICENSE).
