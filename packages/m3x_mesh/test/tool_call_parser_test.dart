import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_mesh/m3x_mesh.dart';

void main() {
  group('M3xToolCallParser.extract', () {
    test('extracts standard fenced json block with nested arguments', () {
      const input = '''
Sure, let me check that for you.
```json
{
  "action": "tool_call",
  "app": "ptk",
  "tool": "ptk_list_incidents",
  "description": "Checking incidents",
  "arguments": {
    "statuspage_id": "cloudflare",
    "filters": {"status": "active", "nested": [1, 2, 3]}
  }
}
```
''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['action'], equals('tool_call'));
      expect(parsed['app'], equals('ptk'));
      expect(parsed['tool'], equals('ptk_list_incidents'));
      expect((parsed['arguments'] as Map)['statuspage_id'], equals('cloudflare'));
      expect(((parsed['arguments'] as Map)['filters'] as Map)['status'], equals('active'));
    });

    test('handles uppercase JSON fence and unclosed fence', () {
      const input = '''
```JSON
{
  "action": "tool_call",
  "app": "ptk",
  "tool": "ptk_ping",
  "arguments": {"host": "1.1.1.1", "count": 3}
}''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['tool'], equals('ptk_ping'));
      expect((parsed['arguments'] as Map)['host'], equals('1.1.1.1'));
    });

    test('extracts tool call without "action" envelope (tool or method key)', () {
      const toolOnly = '{"tool": "ptk_list_statuspages", "app": "ptk", "arguments": {}}';
      final parsedTool = M3xToolCallParser.extract(toolOnly);
      expect(parsedTool, isNotNull);
      expect(parsedTool!['tool'], equals('ptk_list_statuspages'));

      const methodOnly = '{"method": "get_ai_status", "params": {"verbose": true}}';
      final parsedMethod = M3xToolCallParser.extract(methodOnly);
      expect(parsedMethod, isNotNull);
      expect(parsedMethod!['method'], equals('get_ai_status'));
    });

    test('handles multiple JSON objects in one turn and picks first valid tool call', () {
      const input = '''
Context info: {"user": "Alice", "note": "not a tool"}
First call:
{"action": "tool_call", "app": "ptk", "tool": "ptk_list_statuspages", "arguments": {"page": 1}}
Second call:
{"action": "tool_call", "app": "ptk", "tool": "ptk_list_servers", "arguments": {}}
''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['tool'], equals('ptk_list_statuspages'));
      expect((parsed['arguments'] as Map)['page'], equals(1));
    });

    test('handles braces and apostrophes inside string literals cleanly', () {
      const input = '''
It's calling the tool now:
{"action": "tool_call", "app": "paios", "tool": "query_aicore_documentation", "description": "Reading e.g. 'docs' with {braces} inside", "arguments": {"query": "token {limit} } {"}}
''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['tool'], equals('query_aicore_documentation'));
      expect((parsed['arguments'] as Map)['query'], equals('token {limit} } {'));
    });

    test('tolerates markdown-escaped underscores, trailing commas, and unescaped newlines', () {
      const input = '''
```json
{
  "action": "tool\\_call",
  "app": "ptk",
  "tool": "ptk\\_list\\_incidents",
  "description": "Line 1
Line 2",
  "arguments": {
    "status": "active",
  },
}
```
''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['action'], equals('tool_call'));
      expect(parsed['tool'], equals('ptk_list_incidents'));
      expect(parsed['description'], equals('Line 1\nLine 2'));
      expect((parsed['arguments'] as Map)['status'], equals('active'));
    });

    test('falls back to single-quoted keys and values when strict jsonDecode fails', () {
      const input = '''
{'action': 'tool_call', 'app': 'ptk', 'tool': 'ptk_ping', 'description': 'It\\'s "fine"', 'arguments': {'host': '8.8.8.8', 'count': 2,}}
''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['tool'], equals('ptk_ping'));
      expect(parsed['description'], equals('It\'s "fine"'));
      expect((parsed['arguments'] as Map)['host'], equals('8.8.8.8'));
      expect((parsed['arguments'] as Map)['count'], equals(2));
    });

    test('returns null for normal non-tool JSON prose', () {
      const prose1 = 'Here is a sample config:\n```json\n{"theme": "dark", "retries": 3}\n```';
      expect(M3xToolCallParser.extract(prose1), isNull);

      const prose2 = 'Just normal conversational text with {some braces} and no JSON.';
      expect(M3xToolCallParser.extract(prose2), isNull);

      const prose3 = '{"status": "ok", "items": [{"id": 1}, {"id": 2}]}';
      expect(M3xToolCallParser.extract(prose3), isNull);
    });

    test('recovers when stray unclosed brace precedes valid tool call', () {
      const input = 'Oops { broken prefix {"action": "tool_call", "app": "ptk", "tool": "ptk_list_servers", "arguments": {}}';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['tool'], equals('ptk_list_servers'));
    });

    test('repairs missing property value before closing brace ("args":})', () {
      const input = '''
{
  "tool": "ptk_list_statuspages",
  "app": "ptk",
  "args":}
''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['tool'], equals('ptk_list_statuspages'));
      expect(parsed['app'], equals('ptk'));
      expect(parsed['args'], equals(<String, dynamic>{}));

      final call = M3xToolCall.fromJson(parsed);
      expect(call.name, equals('ptk_list_statuspages'));
      expect(call.app, equals('ptk'));
      expect(call.arguments, isEmpty);
    });

    test('repairs missing property value before comma ("args":,) and lifts sibling keys in M3xToolCall.fromJson', () {
      const input = '''
{
  "tool": "ptk_list_statuspages",
  "app": "ptk",
  "args":,
  "sort": "name",
  "order": "asc",
  "limit": 10
}
''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['tool'], equals('ptk_list_statuspages'));
      expect(parsed['app'], equals('ptk'));
      expect(parsed['args'], equals(<String, dynamic>{}));
      expect(parsed['sort'], equals('name'));
      expect(parsed['order'], equals('asc'));
      expect(parsed['limit'], equals(10));

      final call = M3xToolCall.fromJson(parsed);
      expect(call.name, equals('ptk_list_statuspages'));
      expect(call.app, equals('ptk'));
      expect(call.arguments, equals(<String, dynamic>{
        'sort': 'name',
        'order': 'asc',
        'limit': 10,
      }));
    });

    test('inserts null for non-args keys with missing values and {} for arguments/params', () {
      const input1 = '{"tool": "test_tool", "arguments":, "filter":, "tag":}';
      final parsed1 = M3xToolCallParser.extract(input1);
      expect(parsed1, isNotNull);
      expect(parsed1!['arguments'], equals(<String, dynamic>{}));
      expect(parsed1['filter'], isNull);
      expect(parsed1.containsKey('tag'), isTrue);
      expect(parsed1['tag'], isNull);

      const input2 = '{"tool": "test_tool", "params":}';
      final parsed2 = M3xToolCallParser.extract(input2);
      expect(parsed2, isNotNull);
      expect(parsed2!['params'], equals(<String, dynamic>{}));
    });

    test('does not corrupt :} or :, or , ""} patterns inside quoted strings', () {
      const input = r'''
{
  "tool": "ptk_echo",
  "app": "ptk",
  "description": "keep :} and :, and :] and \"foo\" :} and , \"\"} intact",
  "args": {"query": "literal :} and :, inside", "items": ["", "keep"]},
  "extra":}
''';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(
        parsed!['description'],
        equals('keep :} and :, and :] and "foo" :} and , ""} intact'),
      );
      expect(
        (parsed['args'] as Map)['query'],
        equals('literal :} and :, inside'),
      );
      expect((parsed['args'] as Map)['items'], equals(['', 'keep']));
      expect(parsed['extra'], isNull);
    });

    test('strips trailing dangling valueless object keys before }', () {
      const emptyDangling = '{"tool": "duckduckgo_search", "app": "paios", "args": {"query": "Puzzak"}, ""}';
      final parsedEmpty = M3xToolCallParser.extract(emptyDangling);
      expect(parsedEmpty, isNotNull);
      expect(parsedEmpty!['tool'], equals('duckduckgo_search'));
      expect(parsedEmpty['app'], equals('paios'));
      expect(parsedEmpty['args'], equals(<String, dynamic>{'query': 'Puzzak'}));

      const namedDangling = '{"tool": "duckduckgo_search", "app": "paios", "args": {"query": "Puzzak", "foo"}}';
      final parsedNamed = M3xToolCallParser.extract(namedDangling);
      expect(parsedNamed, isNotNull);
      expect(parsedNamed!['args'], equals(<String, dynamic>{'query': 'Puzzak'}));
    });

    test('M3xToolCall.fromJson preserves explicit non-empty args and ignores sibling keys on method calls', () {
      final explicitCall = M3xToolCall.fromJson(<String, dynamic>{
        'tool': 'ptk_ping',
        'app': 'ptk',
        'args': <String, dynamic>{'host': '1.1.1.1'},
        'extra': 'ignored',
      });
      expect(explicitCall.arguments, equals(<String, dynamic>{'host': '1.1.1.1'}));

      final methodCall = M3xToolCall.fromJson(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 'call_1',
        'method': 'get_demo_state',
        'params': <String, dynamic>{},
        'extra': 'not_lifted',
      });
      expect(methodCall.arguments, isEmpty);
    });

    test('extracts Gemma / Gemini Nano v4 control-token tool call with unquoted keys', () {
      const input = '<ctrl42>call:wikipedia_summary{query: "paperclip maximizer"}<ctrl43>';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['action'], equals('tool_call'));
      expect(parsed['tool'], equals('wikipedia_summary'));
      expect(parsed.containsKey('app'), isFalse);
      expect(
        parsed['arguments'],
        equals(<String, dynamic>{'query': 'paperclip maximizer'}),
      );

      final call = M3xToolCall.fromJson(parsed);
      expect(call.tool, equals('wikipedia_summary'));
      expect(call.app, isNull);
      expect(call.arguments, equals(<String, dynamic>{'query': 'paperclip maximizer'}));
    });

    test('extracts control-token tool call with app:tool prefix and multiple args', () {
      const input = '<ctrl42>call:paios:weather_forecast{location: "Kyiv", days: 2}<ctrl43>';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['app'], equals('paios'));
      expect(parsed['tool'], equals('weather_forecast'));
      expect(
        parsed['arguments'],
        equals(<String, dynamic>{'location': 'Kyiv', 'days': 2}),
      );

      final call = M3xToolCall.fromJson(parsed);
      expect(call.app, equals('paios'));
      expect(call.tool, equals('weather_forecast'));
      expect(call.arguments, equals(<String, dynamic>{'location': 'Kyiv', 'days': 2}));
    });

    test('does not mangle URLs, colons, or nested objects inside quoted strings for control-token calls', () {
      const input =
          '<ctrl42>call:fetch_page{url: "https://example.com:8080/wiki/AI:Test?a=1:2", note: "key: value", nested: {flag: true, tags: ["x:y", "z"]}}<ctrl43>';
      final parsed = M3xToolCallParser.extract(input);
      expect(parsed, isNotNull);
      expect(parsed!['tool'], equals('fetch_page'));
      final args = parsed['arguments'] as Map<String, dynamic>;
      expect(args['url'], equals('https://example.com:8080/wiki/AI:Test?a=1:2'));
      expect(args['note'], equals('key: value'));
      expect(args['nested'], equals(<String, dynamic>{
        'flag': true,
        'tags': <String>['x:y', 'z'],
      }));
    });

    test('extracts <|tool_call|>call:... and end-of-string control-token tool calls', () {
      const pipeInput = '<|tool_call|>call:ptk:ptk_ping{host: "1.1.1.1", count: 3}';
      final parsedPipe = M3xToolCallParser.extract(pipeInput);
      expect(parsedPipe, isNotNull);
      expect(parsedPipe!['app'], equals('ptk'));
      expect(parsedPipe['tool'], equals('ptk_ping'));
      expect(
        parsedPipe['arguments'],
        equals(<String, dynamic>{'host': '1.1.1.1', 'count': 3}),
      );

      const eofInput = '<ctrl42>call:get_status{}';
      final parsedEof = M3xToolCallParser.extract(eofInput);
      expect(parsedEof, isNotNull);
      expect(parsedEof!['tool'], equals('get_status'));
      expect(parsedEof['arguments'], isEmpty);
    });
  });

  group('M3xToolCallParser.stripControlToolTags', () {
    test('removes control-token tool calls and stray <ctrl> markers cleanly', () {
      const withThought =
          '<ctrl94>thought\nLet me look that up.<ctrl95><ctrl42>call:wikipedia_summary{query: "paperclip maximizer"}<ctrl43>';
      expect(
        M3xToolCallParser.stripControlToolTags(withThought),
        equals('thought\nLet me look that up.'),
      );

      const withNested =
          'Checking weather...\n<ctrl42>call:paios:weather_forecast{location: "Kyiv", opts: {units: "metric"}}<ctrl43>';
      expect(
        M3xToolCallParser.stripControlToolTags(withNested),
        equals('Checking weather...'),
      );

      const onlyTag = '<ctrl42>call:wikipedia_summary{query: "paperclip maximizer"}<ctrl43>';
      expect(M3xToolCallParser.stripControlToolTags(onlyTag), isEmpty);

      const strayOnly = 'Hello <ctrl42> world <ctrl99>';
      expect(
        M3xToolCallParser.stripControlToolTags(strayOnly),
        equals('Hello  world'),
      );
    });
  });

  group('M3xToolCallParser.looksLikeIncompleteToolCall', () {
    test('detects incomplete mid-stream tool calls', () {
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '<ctrl42>call:wikipedia_summary{query: "paperclip',
        ),
        isTrue,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '<ctrl42>call:wikipedia_',
        ),
        isTrue,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '<|tool_call|>call:ptk_ping{host: "1.1',
        ),
        isTrue,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '<ctrl42>call:wikipedia_summary{query: "paperclip maximizer"}<ctrl43>',
        ),
        isFalse,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '<ctrl94>thought\nJust reasoning without calling a tool.',
        ),
        isFalse,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '{"action": "tool_call", "app": "ptk", "tool":',
        ),
        isTrue,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '```json\n{"action": "tool_call", "app": "ptk"',
        ),
        isTrue,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '```JSON\n{"tool": "ptk_list_incidents", "arguments": {"status": "act',
        ),
        isTrue,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          'Sure! {"tool": "ptk_ping", "arguments": {"host": "1.1.1.1"',
        ),
        isTrue,
      );
    });

    test('returns false when tool call is complete or text is normal prose', () {
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '{"action": "tool_call", "app": "ptk", "tool": "ptk_ping", "arguments": {"host": "1.1.1.1"}}',
        ),
        isFalse,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          'Hello! Everything is operational.',
        ),
        isFalse,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          'Here is a partial non-tool object: {"name": "Alice", "age": 30',
        ),
        isFalse,
      );
      expect(
        M3xToolCallParser.looksLikeIncompleteToolCall(
          '```json\n{"name": "Alice"}\n```',
        ),
        isFalse,
      );
    });
  });

  group('JSON-RPC Error Hygiene', () {
    test('M3xToolRegistry.invokeTool omits stack trace from error.data', () async {
      final registry = M3xToolRegistry([
        M3xTool(
          name: 'boom_tool',
          description: 'Always throws',
          handler: (_) async => throw StateError('Something went wrong'),
        ),
      ]);

      final result = await registry.invokeTool('boom_tool', {}, callId: 'err_1');
      expect(result.isError, isTrue);
      expect(result.error?.message, contains('Something went wrong'));
      expect(result.error?.data, isNull);
    });
  });
}
