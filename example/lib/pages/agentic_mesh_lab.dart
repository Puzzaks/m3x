import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3x_mesh/m3x_mesh.dart';
import 'package:m3x_ui/m3x_ui.dart';
import '../main.dart';

/// Simulated AI Provider execution mode.
enum MeshAiProviderMode {
  geminiNanoSheet,
  cloudAiStudio,
}

/// An interactive lab allowing users to inspect registered inter-app agentic tools,
/// execute simulated headless tool calls via [M3xMeshClient], inspect live JSON-RPC
/// input/output payloads, test multimodal vision + floating assistant bubbles,
/// and toggle AI Provider & Mesh enablement modes.
class AgenticMeshLabSection extends StatefulWidget {
  final bool? enableSimulation;
  const AgenticMeshLabSection({super.key, this.enableSimulation});

  @override
  State<AgenticMeshLabSection> createState() => _AgenticMeshLabSectionState();
}

class _AgenticMeshLabSectionState extends State<AgenticMeshLabSection> {
  late final M3xMeshClient _meshClient;
  MeshAiProviderMode _providerMode = MeshAiProviderMode.geminiNanoSheet;
  bool _isSimulationMode = false;
  bool _meshEnabled = true;
  bool _visionDownsample = true;
  Uint8List? _previewPngBytes;

  String _selectedApp = 'the2k48';
  String _selectedToolName = 'the2k48_get_board';

  final TextEditingController _paramsCtrl = TextEditingController(text: '{}');
  String _lastInputJson = '';
  String _lastOutputJson = '';
  bool _isExecuting = false;
  int _lastExecutionMs = 0;

  static const List<List<int>> _sample2048Grid = [
    [2048, 1024, 512, 256],
    [16, 32, 64, 128],
    [8, 4, 2, 2],
    [0, 0, 0, 0],
  ];

  static const Map<String, String> _defaultEn = {
    'mesh_lab_title': 'Inter-App Agentic Mesh Lab',
    'mesh_provider_mode': 'Simulated AI Provider Mode',
    'mesh_provider_nano': 'PAIOS Gemini Nano',
    'mesh_provider_cloud': 'Cloud AI Studio',
    'mesh_provider_nano_badge': 'Offline • AICore On-Device (~85ms)',
    'mesh_provider_cloud_badge': 'Online • Gemini 2.0 Flash (~320ms)',
    'mesh_floating_sheet_btn': 'Floating Sheet',
    'mesh_paios_sheet_title': 'PAIOS Gemini Nano Sheet',
    'mesh_paios_sheet_subtitle': 'On-Device AICore • IPC Mesh Active',
    'mesh_headless_dispatcher': 'Headless Intent Dispatcher',
    'mesh_target_tool_prefix': 'Target Tool',
    'mesh_uri_prefix': 'URI',
    'mesh_execute_and_close': 'Execute via Mesh & Close',
    'mesh_enable_title': 'Inter-App Agentic Mesh (enableMesh)',
    'mesh_enable_active_sub':
        'Mesh client active • Discovery & IPC tool calls allowed',
    'mesh_enable_disabled_sub':
        'Mesh disabled • All cross-app calls & discovery blocked',
    'mesh_sim_active_title': 'Simulation Fallback Active',
    'mesh_ipc_live_title': 'Live Android ContentProvider IPC',
    'mesh_sim_active_sub': 'Calls execute in-process via local mock tables',
    'mesh_ipc_live_sub': 'Real IPC via content://*.mesh ContentProvider',
    'mesh_vision_title': 'Multimodal Vision & Assistant Bubble',
    'mesh_vision_canvas_badge': '512×512 PNG Canvas',
    'mesh_vision_desc':
        'Synthesizes an in-memory 512×512 PNG 2048 game board (tiles 2048, 1024, 512, 256) and sends it over M3x Mesh to PAIOS Gemini Nano Vision.',
    'mesh_vision_downsample_title': 'Fast 768px Vision Downsampling',
    'mesh_vision_downsample_on': 'ON: Fast EdgeTPU prefill (~2-3s)',
    'mesh_vision_downsample_off':
        'OFF: Full native resolution for small text/OCR',
    'mesh_vision_oneshot_btn':
        '📸 One-Shot Vision Inference (query_local_ai + Image)',
    'mesh_vision_bubble_btn':
        '💬 Summon PAIOS Assistant Bubble (openAssistantBubble)',
    'mesh_registered_tools_title': 'Registered Ecosystem Tools',
    'mesh_registered_tools_sub':
        'Select an agentic tool declared by a Puzzak sibling app:',
    'mesh_input_args_label': 'Input Arguments (JSON):',
    'mesh_executing_btn': 'Executing via IPC Mesh...',
    'mesh_execute_btn': 'Execute Headless Tool Call',
    'mesh_invalid_json': 'Invalid JSON in parameters',
    'mesh_live_payloads_title': 'Live JSON-RPC 2.0 Payloads',
    'mesh_request_payload': 'Request Payload:',
    'mesh_copy_request_tooltip': 'Copy Request JSON',
    'mesh_request_copied': 'Request JSON copied!',
    'mesh_response_result': 'Response Result:',
    'mesh_copy_response_tooltip': 'Copy Response JSON',
    'mesh_response_copied': 'Response JSON copied!',
    'mesh_tool_2048_board_desc':
        'Fetches the live 4x4 matrix, score, and moves count.',
    'mesh_tool_2048_restart_desc':
        'Restarts game session with fresh initial tiles.',
    'mesh_tool_ptk_incidents_desc':
        'Queries active server outages and maintenance alerts.',
    'mesh_tool_ptk_ping_desc':
        'Simulates ICMP ping packet transmissions and latency.',
    'mesh_tool_paios_query_desc':
        'Direct on-device Gemini Nano inference request via AICore.',
    'mesh_tool_demo_env_desc':
        'Inspects local demo host environment over mesh.',
    'mesh_tool_demo_comp_desc':
        'Returns the list of registered M3x UI components.',
    'mesh_tool_mcplayer_status_desc':
        'Retrieves current audio player status and track info.',
  };

  /// Resolves localized UI string via `playgroundEngine.dict.value(key)`,
  /// falling back to [_defaultEn] if the dictionary has not yet been initialized
  /// (e.g., when pumped standalone in widget tests).
  String _tr(String key) {
    final val = playgroundEngine.dict.value(key);
    if (val == 'Loading...' || val == key || val == '!!! $key') {
      return _defaultEn[key] ?? key;
    }
    return val;
  }

  final List<Map<String, String>> _availableTools = const [
    {
      'app': 'the2k48',
      'name': 'the2k48_get_board',
      'title': 'the2k48: get_board',
      'descKey': 'mesh_tool_2048_board_desc',
    },
    {
      'app': 'the2k48',
      'name': 'the2k48_restart_game',
      'title': 'the2k48: restart_game',
      'descKey': 'mesh_tool_2048_restart_desc',
    },
    {
      'app': 'ptk',
      'name': 'ptk_get_incidents',
      'title': 'PTK: get_incidents',
      'descKey': 'mesh_tool_ptk_incidents_desc',
    },
    {
      'app': 'ptk',
      'name': 'ptk_ping_host',
      'title': 'PTK: ping_host',
      'descKey': 'mesh_tool_ptk_ping_desc',
    },
    {
      'app': 'paios',
      'name': 'query_local_ai',
      'title': 'PAIOS (geminilocal): query_local_ai',
      'descKey': 'mesh_tool_paios_query_desc',
    },
    {
      'app': 'demo',
      'name': 'demo_get_environment',
      'title': 'demo: get_environment',
      'descKey': 'mesh_tool_demo_env_desc',
    },
    {
      'app': 'demo',
      'name': 'demo_get_components',
      'title': 'demo: get_components',
      'descKey': 'mesh_tool_demo_comp_desc',
    },
    {
      'app': 'mcplayer',
      'name': 'get_playback_status',
      'title': 'mcplayer: playback_status',
      'descKey': 'mesh_tool_mcplayer_status_desc',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initMeshClient();
    _updateParamsForSelectedTool();
  }

  void _initMeshClient() {
    try {
      _meshClient = playgroundEngine.meshClient;
      _meshEnabled = _meshClient.enabled;
    } catch (_) {
      final isNativeAndroid = !kIsWeb && Platform.isAndroid;
      _meshClient = M3xMeshClient(
        localAppId: 'demo',
        enableSimulation: widget.enableSimulation ?? !isNativeAndroid,
      );
      _meshEnabled = _meshClient.enabled;
    }
    if (widget.enableSimulation != null) {
      _meshClient.setSimulationMode(widget.enableSimulation!);
    }
    _isSimulationMode = _meshClient.isSimulationMode;

    // Register 2k48 tools
    _meshClient.registerSimulatedApp(
      'the2k48',
      M3xToolRegistry([
        M3xTool(
          name: 'the2k48_get_board',
          description:
              'Retrieves current 4x4 matrix, score, and moves count from the active game session.',
          parameters: const {
            'type': 'object',
            'properties': {},
          },
          handler: (args) async => {
            'grid': [
              [2, 4, 8, 16],
              [0, 2, 4, 8],
              [0, 0, 2, 4],
              [0, 0, 0, 2],
            ],
            'score': 1024,
            'moves': 88,
            'status': 'in_progress',
          },
        ),
        M3xTool(
          name: 'the2k48_restart_game',
          description: 'Restarts the current game board with fresh 2 and 4 tiles.',
          parameters: const {
            'type': 'object',
            'properties': {},
          },
          handler: (args) async => {
            'status': 'restarted',
            'new_score': 0,
            'initial_tiles': [2, 2],
          },
        ),
      ]),
    );

    // Register PTK tools
    _meshClient.registerSimulatedApp(
      'ptk',
      M3xToolRegistry([
        M3xTool(
          name: 'ptk_get_incidents',
          description:
              'Queries active server incidents, outages, and maintenance alerts across monitored nodes.',
          parameters: const {
            'type': 'object',
            'properties': {
              'status_filter': {
                'type': 'string',
                'description': 'Filter by status: "all", "investigating", "resolved"',
              },
            },
          },
          handler: (args) async => {
            'incidents': [
              {
                'id': 'inc-101',
                'service': 'Kyiv Edge Node',
                'severity': 'minor',
                'status': 'investigating',
                'message': 'Upstream packet loss detected (BGP flap)',
                'timestamp': '2026-11-06T22:15:00Z',
              },
              {
                'id': 'inc-102',
                'service': 'Frankfurt Relay',
                'severity': 'info',
                'status': 'scheduled',
                'message': 'Routine kernel upgrade in progress',
                'timestamp': '2026-11-06T22:00:00Z',
              },
            ],
            'count': 2,
          },
        ),
        M3xTool(
          name: 'ptk_ping_host',
          description: 'Simulates sending ICMP ping packets to a remote host.',
          parameters: const {
            'type': 'object',
            'properties': {
              'host': {'type': 'string', 'description': 'Destination hostname or IP'},
              'count': {'type': 'integer', 'description': 'Number of packets to send'},
            },
            'required': ['host'],
          },
          handler: (args) async {
            final host = args['host']?.toString() ?? 'kyiv.puzzak.page';
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
      ]),
    );

    // Register simulated PAIOS vision tool for desktop/test environments
    _meshClient.registerSimulatedApp(
      'paios',
      M3xToolRegistry([
        M3xTool(
          name: 'query_local_ai',
          description: 'Executes on-device Gemini Nano text or multimodal vision inference.',
          parameters: const {
            'type': 'object',
            'properties': {
              'prompt': {'type': 'string'},
              'image_base64': {'type': 'string'},
              'downsample': {'type': 'boolean'},
            },
          },
          handler: (args) async {
            final hasImg = args['image_base64'] != null &&
                args['image_base64'].toString().isNotEmpty;
            return {
              'prompt': args['prompt']?.toString() ?? '',
              'vision_attached': hasImg,
              'downsample': args['downsample'] ?? true,
              'response': hasImg
                  ? 'Gemini Nano Vision: The top row forms a perfect snake chain (2048 -> 1024 -> 512 -> 256) with 16..128 aligned underneath and two 2-tiles ready to merge on row 3. Best move: Swipe RIGHT to merge the two 2-tiles into 4, then chain-merge up to 4096!'
                  : 'Cluster status nominal: 2 active nodes online.',
              'status': 'success',
            };
          },
        ),
      ]),
    );
  }

  /// Renders a crisp 512×512 PNG image of a 2048 board + system telemetry in memory
  /// using `dart:ui` [ui.PictureRecorder] and [Canvas] (zero external assets required).
  Future<Uint8List> _generateSynthetic2048BoardPng() async {
    const double size = 512.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    _paint2048BoardOnCanvas(canvas, const Size(size, size));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    if (mounted) {
      setState(() {
        _previewPngBytes = bytes;
      });
    }
    return bytes;
  }

  static void _paint2048BoardOnCanvas(Canvas canvas, Size size) {
    final double scale = size.width / 512.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Background card
    final bgPaint = Paint()..color = const Color(0xFFFAF8EF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 512, 512),
        const Radius.circular(24),
      ),
      bgPaint,
    );

    // Top header banner
    final headerPaint = Paint()..color = const Color(0xFF776E65);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 20, 464, 56),
        const Radius.circular(14),
      ),
      headerPaint,
    );

    _drawCanvasText(
      canvas,
      '2048 • SCORE: 28,440 • MOVES: 142',
      const Offset(256, 48),
      fontSize: 20,
      color: Colors.white,
    );

    // Board container
    final boardPaint = Paint()..color = const Color(0xFFBBADA0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 90, 464, 364),
        const Radius.circular(16),
      ),
      boardPaint,
    );

    const double pad = 12.0;
    const double cellW = (464 - pad * 5) / 4;
    const double cellH = (364 - pad * 5) / 4;

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final int val = _sample2048Grid[r][c];
        final double x = 24 + pad + c * (cellW + pad);
        final double y = 90 + pad + r * (cellH + pad);

        final tilePaint = Paint()..color = _tileColor(val);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cellW, cellH),
            const Radius.circular(10),
          ),
          tilePaint,
        );

        if (val > 0) {
          _drawCanvasText(
            canvas,
            val.toString(),
            Offset(x + cellW / 2, y + cellH / 2),
            fontSize: val >= 1024 ? 24 : 28,
            color: val <= 4 ? const Color(0xFF776E65) : Colors.white,
          );
        }
      }
    }

    // Footer telemetry pill
    _drawCanvasText(
      canvas,
      'PAIOS NPU VISION TEST • TENSOR G4 AICORE',
      const Offset(256, 482),
      fontSize: 15,
      color: const Color(0xFF776E65),
    );

    canvas.restore();
  }

  static Color _tileColor(int val) {
    switch (val) {
      case 0:
        return const Color(0xFFCDC1B4);
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      default:
        return const Color(0xFF3C3A32);
    }
  }

  static void _drawCanvasText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  Future<void> _executeOneShotVisionInference() async {
    setState(() {
      _isExecuting = true;
    });
    final stopwatch = Stopwatch()..start();
    final pngBytes = await _generateSynthetic2048BoardPng();
    final base64Png = base64Encode(pngBytes);

    final callId = 'vision-${DateTime.now().millisecondsSinceEpoch}';
    final toolCall = M3xToolCall(
      id: callId,
      name: 'query_local_ai',
      arguments: {
        'prompt':
            'Describe this 2048 game board image and recommend the best next move!',
        'image_base64': base64Png,
        'downsample': _visionDownsample,
      },
    );

    const encoder = JsonEncoder.withIndent('  ');
    // Show truncated base64 preview in the UI inspector so it remains readable
    final displayCallJson = {
      'jsonrpc': '2.0',
      'id': callId,
      'method': 'query_local_ai',
      'params': {
        'prompt':
            'Describe this 2048 game board image and recommend the best next move!',
        'image_base64':
            '${base64Png.substring(0, base64Png.length.clamp(0, 48))}... (${pngBytes.length} bytes PNG)',
        'downsample': _visionDownsample,
      },
    };
    _lastInputJson = encoder.convert(displayCallJson);

    final result = await _meshClient.execute('paios', toolCall);
    stopwatch.stop();

    if (mounted) {
      setState(() {
        _isExecuting = false;
        _lastExecutionMs = stopwatch.elapsedMilliseconds;
        _lastOutputJson = encoder.convert(result.toJson());
      });
    }
  }

  Future<void> _summonPaiosAssistantBubble() async {
    setState(() {
      _isExecuting = true;
    });
    final stopwatch = Stopwatch()..start();
    final pngBytes = await _generateSynthetic2048BoardPng();
    final base64Png = base64Encode(pngBytes);

    final opened = await _meshClient.openAssistantBubble(
      targetApp: 'paios',
      prompt: 'Hey! I reached the 2048 tile on this board. Give me advice!',
      contextData: '2048 Game: Score 28,440, Moves: 142',
      imageBase64: base64Png,
      downsample: _visionDownsample,
    );
    stopwatch.stop();

    const encoder = JsonEncoder.withIndent('  ');
    if (mounted) {
      setState(() {
        _isExecuting = false;
        _lastExecutionMs = stopwatch.elapsedMilliseconds;
        _lastInputJson = encoder.convert({
          'action': 'openAssistantBubble',
          'targetApp': 'paios',
          'prompt': 'Hey! I reached the 2048 tile on this board. Give me advice!',
          'contextData': '2048 Game: Score 28,440, Moves: 142',
          'imageBytesCount': pngBytes.length,
          'downsample': _visionDownsample,
        });
        _lastOutputJson = encoder.convert({
          'opened': opened,
          'status': opened
              ? 'summoned_floating_assistant_bubble'
              : 'mesh_disabled_or_unavailable',
        });
      });
    }
  }

  void _updateParamsForSelectedTool() {
    if (_selectedToolName == 'ptk_ping_host') {
      _paramsCtrl.text = '{\n  "host": "kyiv.puzzak.page",\n  "count": 4\n}';
    } else if (_selectedToolName == 'ptk_get_incidents') {
      _paramsCtrl.text = '{\n  "status_filter": "all"\n}';
    } else if (_selectedToolName == 'query_local_ai') {
      _paramsCtrl.text = '{\n  "prompt": "Summarize node cluster status"\n}';
    } else {
      _paramsCtrl.text = '{}';
    }
  }

  @override
  void dispose() {
    _paramsCtrl.dispose();
    super.dispose();
  }

  Future<void> _executeToolCall() async {
    setState(() {
      _isExecuting = true;
    });

    final stopwatch = Stopwatch()..start();
    Map<String, dynamic> parsedArgs = {};
    try {
      if (_paramsCtrl.text.trim().isNotEmpty) {
        final decoded = jsonDecode(_paramsCtrl.text.trim());
        if (decoded is Map) {
          parsedArgs = Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_tr('mesh_invalid_json')}: $e')),
        );
        setState(() {
          _isExecuting = false;
        });
      }
      return;
    }

    final callId = 'call-${DateTime.now().millisecondsSinceEpoch}';
    final toolCall = M3xToolCall(
      id: callId,
      name: _selectedToolName,
      arguments: parsedArgs,
    );

    const encoder = JsonEncoder.withIndent('  ');
    _lastInputJson = encoder.convert(toolCall.toJson());

    // Execute via M3xMeshClient
    final result = await _meshClient.execute(_selectedApp, toolCall);
    stopwatch.stop();

    if (mounted) {
      setState(() {
        _isExecuting = false;
        _lastExecutionMs = stopwatch.elapsedMilliseconds;
        _lastOutputJson = encoder.convert(result.toJson());
      });
    }
  }

  void _showPaiosFloatingSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: scheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (sheetCtx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.smart_toy_rounded,
                      size: 22,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('mesh_paios_sheet_title'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _tr('mesh_paios_sheet_subtitle'),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            size: 18, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          _tr('mesh_headless_dispatcher'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_tr('mesh_target_tool_prefix')}: $_selectedToolName\n${_tr('mesh_uri_prefix')}: ${M3xMeshClient.buildContentUri(_selectedApp)}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        await _executeToolCall();
                        if (context.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(_tr('mesh_execute_and_close')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Category.settings(
          title: _tr('mesh_lab_title'),
          context: context,
        ),

        // 1. AI Provider Mode & Mesh Enablement Switcher Card
        CardGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _providerMode == MeshAiProviderMode.geminiNanoSheet
                            ? Icons.phone_android_rounded
                            : Icons.cloud_done_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tr('mesh_provider_mode'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<MeshAiProviderMode>(
                    segments: [
                      ButtonSegment(
                        value: MeshAiProviderMode.geminiNanoSheet,
                        label: Text(_tr('mesh_provider_nano')),
                        icon: const Icon(Icons.memory_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: MeshAiProviderMode.cloudAiStudio,
                        label: Text(_tr('mesh_provider_cloud')),
                        icon: const Icon(Icons.cloud_queue_rounded, size: 16),
                      ),
                    ],
                    selected: {_providerMode},
                    onSelectionChanged: (val) {
                      setState(() {
                        _providerMode = val.first;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _providerMode ==
                                  MeshAiProviderMode.geminiNanoSheet
                              ? scheme.primaryContainer
                              : scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _providerMode == MeshAiProviderMode.geminiNanoSheet
                              ? _tr('mesh_provider_nano_badge')
                              : _tr('mesh_provider_cloud_badge'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _providerMode ==
                                    MeshAiProviderMode.geminiNanoSheet
                                ? scheme.onPrimaryContainer
                                : scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_providerMode == MeshAiProviderMode.geminiNanoSheet)
                        TextButton.icon(
                          onPressed: () => _showPaiosFloatingSheet(context),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: Text(
                            _tr('mesh_floating_sheet_btn'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _meshEnabled
                            ? Icons.lan_rounded
                            : Icons.portable_wifi_off_rounded,
                        color: _meshEnabled ? scheme.primary : scheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr('mesh_enable_title'),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              _meshEnabled
                                  ? _tr('mesh_enable_active_sub')
                                  : _tr('mesh_enable_disabled_sub'),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _meshEnabled,
                        onChanged: (val) {
                          setState(() {
                            _meshEnabled = val;
                            _meshClient.enabled = val;
                          });
                          try {
                            playgroundEngine.toggleMeshEnabled(val);
                          } catch (_) {}
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _isSimulationMode
                            ? Icons.science_outlined
                            : Icons.hub_rounded,
                        color: _isSimulationMode
                            ? scheme.secondary
                            : scheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isSimulationMode
                                  ? _tr('mesh_sim_active_title')
                                  : _tr('mesh_ipc_live_title'),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              _isSimulationMode
                                  ? _tr('mesh_sim_active_sub')
                                  : _tr('mesh_ipc_live_sub'),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: !_isSimulationMode,
                        onChanged: (val) {
                          setState(() {
                            _isSimulationMode = !val;
                            _meshClient.setSimulationMode(!val);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 2. Multimodal Vision & Assistant Bubble Showcase Card
        CardGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _tr('mesh_vision_title'),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _tr('mesh_vision_canvas_badge'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tr('mesh_vision_desc'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: _previewPngBytes != null
                              ? Image.memory(
                                  _previewPngBytes!,
                                  fit: BoxFit.cover,
                                )
                              : const CustomPaint(
                                  painter: _Synthetic2048PreviewPainter(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr('mesh_vision_downsample_title'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              _visionDownsample
                                  ? _tr('mesh_vision_downsample_on')
                                  : _tr('mesh_vision_downsample_off'),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Switch(
                              value: _visionDownsample,
                              onChanged: (v) =>
                                  setState(() => _visionDownsample = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed:
                          _isExecuting ? null : _executeOneShotVisionInference,
                      icon: const Icon(Icons.photo_camera_back_rounded, size: 18),
                      label: Text(_tr('mesh_vision_oneshot_btn')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _isExecuting ? null : _summonPaiosAssistantBubble,
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: Text(_tr('mesh_vision_bubble_btn')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 3. Registered Tools Selector & Headless Execution Card
        CardGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('mesh_registered_tools_title'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tr('mesh_registered_tools_sub'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedToolName,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: _availableTools.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['name']!,
                        child: Text(
                          t['title']!,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      final match = _availableTools
                          .firstWhere((element) => element['name'] == val);
                      setState(() {
                        _selectedToolName = val;
                        _selectedApp = match['app']!;
                        _updateParamsForSelectedTool();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tr(
                      _availableTools.firstWhere(
                              (e) => e['name'] == _selectedToolName)['descKey'] ??
                          '',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _tr('mesh_input_args_label'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _paramsCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isExecuting ? null : _executeToolCall,
                      icon: _isExecuting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _isExecuting
                            ? _tr('mesh_executing_btn')
                            : _tr('mesh_execute_btn'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 4. Live Payloads Inspector (Input / Output JSON)
        if (_lastInputJson.isNotEmpty || _lastOutputJson.isNotEmpty)
          CardGroup(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code_rounded,
                            size: 18, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _tr('mesh_live_payloads_title'),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Spacer(),
                        if (_lastExecutionMs > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_lastExecutionMs}ms',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: scheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_lastInputJson.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            _tr('mesh_request_payload'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                            tooltip: _tr('mesh_copy_request_tooltip'),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _lastInputJson));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_tr('mesh_request_copied')),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: SelectableText(
                          _lastInputJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_lastOutputJson.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            _tr('mesh_response_result'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            visualDensity: VisualDensity.compact,
                            tooltip: _tr('mesh_copy_response_tooltip'),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _lastOutputJson));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_tr('mesh_response_copied')),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: SelectableText(
                          _lastOutputJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Synthetic2048PreviewPainter extends CustomPainter {
  const _Synthetic2048PreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _AgenticMeshLabSectionState._paint2048BoardOnCanvas(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
