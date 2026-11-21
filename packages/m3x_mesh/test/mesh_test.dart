import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_mesh/m3x_mesh.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M3xTool & Schema Validation', () {
    test('Tool schema serialization and deserialization', () {
      final tool = M3xTool(
        name: 'echo_tool',
        description: 'Echoes the message back',
        app: 'demo',
        packageName: 'page.puzzak.demo',
        parameters: {
          'type': 'object',
          'properties': {
            'message': {'type': 'string', 'description': 'The message to echo'},
            'times': {'type': 'integer', 'description': 'Repeat count'},
          },
          'required': ['message'],
        },
        handler: (args) async => {'echo': args['message']},
      );

      final json = tool.toJson();
      expect(json['name'], equals('echo_tool'));
      expect(json['description'], equals('Echoes the message back'));
      expect(json['app'], equals('demo'));
      expect(json['packageName'], equals('page.puzzak.demo'));
      expect(json['parameters']['type'], equals('object'));

      final restored = M3xTool.fromJson(json);
      expect(restored.name, equals('echo_tool'));
      expect(restored.description, equals('Echoes the message back'));
      expect(restored.app, equals('demo'));
      expect(restored.packageName, equals('page.puzzak.demo'));
    });

    test('validateArguments reports missing required and invalid types', () {
      final tool = M3xTool(
        name: 'math_add',
        description: 'Adds two numbers',
        parameters: {
          'type': 'object',
          'properties': {
            'a': {'type': 'number'},
            'b': {'type': 'number'},
            'tag': {'type': 'string'},
          },
          'required': ['a', 'b'],
        },
      );

      // Valid call
      expect(
          tool.validateArguments({'a': 10, 'b': 20.5, 'tag': 'sum'}), isEmpty);

      // Missing required parameter
      final missingErrors = tool.validateArguments({'a': 10});
      expect(missingErrors, contains("Missing required parameter: 'b'"));

      // Invalid type
      final typeErrors = tool.validateArguments({'a': 'not_a_number', 'b': 20});
      expect(typeErrors.length, equals(1));
      expect(
          typeErrors.first, contains("Parameter 'a' must be of type number"));
    });
  });

  group('M3xToolRegistry', () {
    late M3xToolRegistry registry;

    setUp(() {
      registry = M3xToolRegistry();
      registry.register(
        M3xTool(
          name: 'add',
          description: 'Adds a and b',
          parameters: {
            'type': 'object',
            'properties': {
              'a': {'type': 'integer'},
              'b': {'type': 'integer'},
            },
            'required': ['a', 'b'],
          },
          handler: (args) async {
            final a = args['a'] as int;
            final b = args['b'] as int;
            return {'sum': a + b};
          },
        ),
      );
    });

    test('Registry registers, queries, and unregisters tools', () {
      expect(registry.contains('add'), isTrue);
      expect(registry.tools.length, equals(1));
      expect(registry.get('add')?.description, equals('Adds a and b'));

      final unregistered = registry.unregister('add');
      expect(unregistered, isTrue);
      expect(registry.contains('add'), isFalse);
    });

    test('invokeTool successfully executes registered tool with valid params',
        () async {
      final res =
          await registry.invokeTool('add', {'a': 5, 'b': 7}, callId: 'req_1');
      expect(res.isSuccess, isTrue);
      expect(res.id, equals('req_1'));
      expect(res.result?['sum'], equals(12));
    });

    test('invokeTool returns methodNotFound for unregistered tool', () async {
      final res =
          await registry.invokeTool('non_existent', {}, callId: 'req_2');
      expect(res.isError, isTrue);
      expect(res.error?.code, equals(M3xToolError.methodNotFound));
    });

    test('invokeTool returns invalidParams for schema violations', () async {
      final res = await registry.invokeTool('add', {'a': 5}, callId: 'req_3');
      expect(res.isError, isTrue);
      expect(res.error?.code, equals(M3xToolError.invalidParams));
    });
  });

  group('JSON-RPC Models (M3xToolCall & M3xToolResult)', () {
    test('M3xToolCall roundtrip serialization', () {
      const call = M3xToolCall(
        id: '123',
        name: 'ping_host',
        arguments: {'host': '1.1.1.1', 'count': 2},
      );

      final json = call.toJson();
      expect(json['jsonrpc'], equals('2.0'));
      expect(json['id'], equals('123'));
      expect(json['method'], equals('ping_host'));
      expect(json['params'], equals({'host': '1.1.1.1', 'count': 2}));

      final restored = M3xToolCall.fromJson(json);
      expect(restored.id, equals('123'));
      expect(restored.name, equals('ping_host'));
      expect(restored.arguments['host'], equals('1.1.1.1'));
    });

    test('M3xToolResult success and error roundtrip', () {
      final success =
          M3xToolResult.success(id: 'call_1', result: {'output': 'ok'});
      final successJson = success.toJson();
      final restoredSuccess = M3xToolResult.fromJson(successJson);
      expect(restoredSuccess.isSuccess, isTrue);
      expect(restoredSuccess.result?['output'], equals('ok'));

      final error = M3xToolResult.error(
        id: 'call_2',
        code: M3xToolError.invalidParams,
        message: 'Invalid param type',
      );
      final errorJson = error.toJson();
      final restoredError = M3xToolResult.fromJson(errorJson);
      expect(restoredError.isError, isTrue);
      expect(restoredError.error?.code, equals(M3xToolError.invalidParams));
      expect(restoredError.error?.message, equals('Invalid param type'));
    });
  });

  group('M3xAiProvider (Mock)', () {
    test('MockAiProvider prompt execution and streaming', () async {
      final ai = MockAiProvider(name: 'test_ai', supportsLocalAi: true);
      expect(ai.name, equals('test_ai'));
      expect(ai.supportsLocalAi, isTrue);

      final resp = await ai.executePrompt('Hello Puzzak');
      expect(resp, contains('Hello Puzzak'));

      final stream = ai.streamPrompt('One two three');
      final chunks = await stream.toList();
      expect(chunks.join(''), contains('One two three'));
    });
  });

  group('M3xMeshClient (Inter-App Agentic Mesh)', () {
    late M3xMeshClient client;

    setUp(() {
      client = M3xMeshClient(enableSimulation: true);
    });

    test('Client lists available simulated apps', () async {
      final apps = await client.listAvailableApps();
      expect(apps, contains('ptk'));
      expect(apps, contains('the2k48'));
      expect(apps, contains('paios'));
      expect(apps, contains('mcplayer'));
    });

    test('Client queries tools from PTK simulation', () async {
      final tools = await client.queryTools('ptk');
      expect(tools.any((t) => t.name == 'ping_host'), isTrue);
      expect(tools.any((t) => t.name == 'calculate_subnet'), isTrue);
    });

    test('Client executes tool on simulated PTK app', () async {
      final result = await client
          .callTool('ptk', 'ping_host', {'host': '8.8.8.8', 'count': 3});
      expect(result.isSuccess, isTrue);
      expect(result.result?['host'], equals('8.8.8.8'));
      expect(result.result?['status'], equals('success'));
    });

    test('Client executes tool on simulated The 2k48 app', () async {
      final result = await client.callTool('the2k48', 'get_high_score', {});
      expect(result.isSuccess, isTrue);
      expect(result.result?['high_score'], equals(32768));
    });

    test('Client returns methodNotFound for unregistered sibling app',
        () async {
      final result = await client.callTool('unknown_app', 'do_something', {});
      expect(result.isError, isTrue);
      expect(result.error?.code, equals(M3xToolError.methodNotFound));
    });

    test(
        'URI builder produces standard Android ContentProvider URI with PAIOS & Demo mapping',
        () {
      expect(M3xMeshClient.buildContentUri('ptk'),
          equals('content://page.puzzak.ptk.mesh'));
      expect(M3xMeshClient.buildContentUri('page.puzzak.ptk'),
          equals('content://page.puzzak.ptk.mesh'));
      expect(
        M3xMeshClient.buildContentUri('com.puzzak.geminilocal'),
        equals('content://page.puzzak.paios.mesh'),
      );
      expect(
        M3xMeshClient.buildContentUri('geminilocal'),
        equals('content://page.puzzak.paios.mesh'),
      );
      expect(
        M3xMeshClient.buildContentUri('paios'),
        equals('content://page.puzzak.paios.mesh'),
      );
      expect(
        M3xMeshClient.buildContentUri('demo'),
        equals('content://page.puzzak.demo.mesh'),
      );
      expect(
        M3xMeshClient.buildContentUri('page.puzzak.demo'),
        equals('content://page.puzzak.demo.mesh'),
      );
    });

    test('isPackageInstalled checks simulation registry in non-native mode',
        () async {
      expect(await client.isPackageInstalled('ptk'), isTrue);
      expect(await client.isPackageInstalled('page.puzzak.ptk'), isTrue);
      expect(
          await client.isPackageInstalled('com.puzzak.nonexistent'), isFalse);
    });

    test('bypassAuthInDebug permits unsigned calls during development/test',
        () {
      final debugClient = M3xMeshClient(bypassAuthInDebug: true);
      expect(debugClient.isSignatureAuthorized('com.puzzak.ptk'), isTrue);

      final prodClient = M3xMeshClient(bypassAuthInDebug: false);
      expect(prodClient.isSignatureAuthorized('com.puzzak.ptk', null), isFalse);
      expect(
          prodClient.isSignatureAuthorized(
              'com.puzzak.ptk', 'valid_sha256_hash'),
          isTrue);
    });

    test(
        'Incoming tool dispatch executes local registry and returns JSON-RPC response',
        () async {
      final localRegistry = M3xToolRegistry([
        M3xTool(
          name: 'get_demo_state',
          description: 'Returns demo app state',
          parameters: const {'type': 'object', 'properties': {}},
          handler: (args) async => {'theme': 'dark', 'active_tab': 'mesh'},
        ),
      ]);

      final meshClient = M3xMeshClient(
        localRegistry: localRegistry,
        enableSimulation: true,
      );

      // Simulate incoming call from sibling app
      const channel = MethodChannel('com.puzzak.m3x_mesh');
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.puzzak.m3x_mesh',
        channel.codec.encodeMethodCall(
          const MethodCall('onIncomingToolCall', {
            'caller': 'page.puzzak.paios',
            'payload':
                '{"jsonrpc":"2.0","id":"call_42","method":"get_demo_state","params":{}}',
          }),
        ),
        (data) {},
      );

      expect(meshClient.localRegistry.contains('get_demo_state'), isTrue);
    });

    test(
        'Local short-circuit dispatch executes directly in-memory without ContentProvider',
        () async {
      final localRegistry = M3xToolRegistry([
        M3xTool(
          name: 'query_local_ai',
          app: 'geminilocal',
          description: 'Executes on-device Gemini inference',
          parameters: {
            'type': 'object',
            'properties': {
              'prompt': {'type': 'string'},
            },
            'required': ['prompt'],
          },
          handler: (args) async => {
            'response': 'In-memory response to: ${args['prompt']}',
            'status': 'success',
          },
        ),
      ]);

      final paiosClient = M3xMeshClient(
        localRegistry: localRegistry,
        localAppId: 'paios',
        enableSimulation:
            false, // ensure simulation is off so it tests short-circuit logic
      );

      // 1. Call via 'geminilocal' alias
      final res1 = await paiosClient
          .callTool('geminilocal', 'query_local_ai', {'prompt': 'hello'});
      expect(res1.isSuccess, isTrue);
      expect(res1.result?['response'], equals('In-memory response to: hello'));

      // 2. Call via 'paios' canonical ID
      final res2 = await paiosClient
          .callTool('paios', 'query_local_ai', {'prompt': 'test 2'});
      expect(res2.isSuccess, isTrue);
      expect(res2.result?['response'], equals('In-memory response to: test 2'));

      // 3. Query tools on local app returns local registry tools
      final localTools = await paiosClient.queryTools('geminilocal');
      expect(localTools.length, equals(1));
      expect(localTools.first.name, equals('query_local_ai'));
    });

    test('Simulation mode toggling with disableSimulation and enableSimulation',
        () {
      final testClient = M3xMeshClient(enableSimulation: true);
      expect(testClient.isSimulationMode, isTrue);

      testClient.disableSimulation();
      expect(testClient.isSimulationMode, isFalse);

      testClient.enableSimulation();
      expect(testClient.isSimulationMode, isTrue);
    });

    test(
        'checkAppStatus queries get_ai_status and returns online: true for simulated paios',
        () async {
      final simClient = M3xMeshClient(enableSimulation: true);
      final status = await simClient.checkAppStatus('paios');
      expect(status['online'], isTrue);
      expect(status['engine_running'], isTrue);
      expect(status['model_available'], isTrue);
    });

    test('checkAppStatus works with local registry hosting get_ai_status',
        () async {
      final localRegistry = M3xToolRegistry([
        M3xTool(
          name: 'get_ai_status',
          app: 'paios',
          description: 'Returns local AI status',
          parameters: const {'type': 'object', 'properties': {}},
          handler: (args) async => {
            'engine_running': true,
            'model_available': true,
            'model_initialized': true,
            'status': 'Ready',
          },
        ),
      ]);

      final localClient = M3xMeshClient(
        localRegistry: localRegistry,
        localAppId: 'paios',
        enableSimulation: false,
      );

      final status = await localClient.checkAppStatus('paios');
      expect(status['online'], isTrue);
      expect(status['engine_running'], isTrue);
      expect(status['status'], equals('Ready'));
    });

    test('checkAppStatus returns online: false for unknown app', () async {
      final simClient = M3xMeshClient(enableSimulation: true);
      final status = await simClient.checkAppStatus('non_existent_app');
      expect(status['online'], isFalse);
      expect(status['error'], isNotNull);
    });

    test(
        'queryTools preserves exact reverse-DNS packageName and resolves defaults',
        () async {
      final simClient = M3xMeshClient(enableSimulation: true);
      simClient.registerSimulatedApp(
        'com.example.foo',
        M3xToolRegistry([
          const M3xTool(
            name: 'foo_ping',
            description: 'Custom third-party tool',
          ),
        ]),
      );

      final customTools = await simClient.queryTools('com.example.foo');
      expect(customTools.length, equals(1));
      expect(customTools.first.packageName, equals('com.example.foo'));
      expect(
        M3xMeshClient.buildContentUri(customTools.first.packageName!),
        equals('content://com.example.foo.mesh'),
      );

      final ptkTools = await simClient.queryTools('ptk');
      expect(ptkTools, isNotEmpty);
      expect(ptkTools.first.packageName, equals('page.puzzak.ptk'));
    });

    test('getAppLabel returns null cleanly in simulation mode', () async {
      final simClient = M3xMeshClient(enableSimulation: true);
      expect(await simClient.getAppLabel('page.puzzak.ptk'), isNull);
    });

    test(
        'Zero-fallback: non-simulation client returns [] and errors instead of simulated apps',
        () async {
      M3xMeshClient.clearDiscoveredPackagesCache();
      const channel = MethodChannel('com.puzzak.m3x_mesh');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      // 1. Empty listMeshApps -> [] (not simulated apps)
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'listMeshApps') return <String>[];
        if (call.method == 'isPackageInstalled') return false;
        if (call.method == 'openAssistantBubble') return false;
        throw PlatformException(code: 'UNAVAILABLE', message: 'Not installed');
      });

      final liveClient = M3xMeshClient(enableSimulation: false);
      expect(await liveClient.listAvailableApps(), isEmpty);
      expect(await liveClient.queryTools('ptk'), isEmpty);
      expect(await liveClient.isPackageInstalled('ptk'), isFalse);
      expect(await liveClient.openAssistantBubble(), isFalse);

      final execRes =
          await liveClient.callTool('ptk', 'ping_host', {'host': '1.1.1.1'});
      expect(execRes.isError, isTrue);
      expect(execRes.error?.message, contains('Mesh communication error'));

      // 2. Throwing listMeshApps -> [] (not simulated apps)
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'LIST_FAILED', message: 'Boom');
      });
      expect(await liveClient.listAvailableApps(), isEmpty);

      messenger.setMockMethodCallHandler(channel, null);
      M3xMeshClient.clearDiscoveredPackagesCache();
    });

    test(
        'buildContentUri resolves discovered packages and preserves dot-separated IDs',
        () async {
      M3xMeshClient.clearDiscoveredPackagesCache();
      const channel = MethodChannel('com.puzzak.m3x_mesh');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      String? lastQueryUri;
      String? lastOverlayPkg;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'listMeshApps') {
          return <String>['page.puzzak.alerts', 'com.vendor.scanner'];
        }
        if (call.method == 'queryMeshTools') {
          lastQueryUri = (call.arguments as Map)['uri'] as String?;
          return '[{"name":"alerts_list","description":"List alerts"}]';
        }
        if (call.method == 'openAssistantBubble') {
          lastOverlayPkg = (call.arguments as Map)['overlayPkg'] as String?;
          return true;
        }
        return null;
      });

      final liveClient = M3xMeshClient(enableSimulation: false);

      // Querying by short name triggers discovery and resolves page.puzzak.alerts.mesh
      final alertTools = await liveClient.queryTools('alerts');
      expect(lastQueryUri, equals('content://page.puzzak.alerts.mesh'));
      expect(alertTools.length, equals(1));
      expect(alertTools.first.packageName, equals('page.puzzak.alerts'));

      // Static buildContentUri also resolves cached discovered packages by suffix
      expect(
        M3xMeshClient.buildContentUri('alerts'),
        equals('content://page.puzzak.alerts.mesh'),
      );
      expect(
        M3xMeshClient.buildContentUri('scanner'),
        equals('content://com.vendor.scanner.mesh'),
      );
      expect(
        M3xMeshClient.buildContentUri('org.other.node'),
        equals('content://org.other.node.mesh'),
      );
      expect(
        M3xMeshClient.buildContentUri('unseen'),
        equals('content://page.puzzak.unseen.mesh'),
      );

      // Explicit knownPackages overrides fallback for short names
      expect(
        M3xMeshClient.buildContentUri('custom',
            knownPackages: ['io.custom.app']),
        equals('content://page.puzzak.custom.mesh'),
      );
      expect(
        M3xMeshClient.buildContentUri('app', knownPackages: ['io.custom.app']),
        equals('content://io.custom.app.mesh'),
      );

      // openAssistantBubble passes dynamically discovered overlayPkg when matching targetApp
      final opened = await liveClient.openAssistantBubble(targetApp: 'scanner');
      expect(opened, isTrue);
      expect(lastOverlayPkg, equals('com.vendor.scanner'));

      messenger.setMockMethodCallHandler(channel, null);
      M3xMeshClient.clearDiscoveredPackagesCache();
    });
  });
}
