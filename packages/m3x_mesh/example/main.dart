import 'package:flutter/foundation.dart';
import 'package:m3x_mesh/m3x_mesh.dart';

Future<void> main() async {
  final client = M3xMeshClient(localAppId: 'example');

  final apps = await client.listAvailableApps();
  debugPrint('Available mesh peers: $apps');

  final result = await client.callTool(
    'ptk',
    'ping_host',
    {'host': '8.8.8.8', 'count': 3},
  );
  debugPrint('Tool call result: ${result.toJson()}');
}
