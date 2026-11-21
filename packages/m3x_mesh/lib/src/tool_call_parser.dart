import 'dart:convert';

/// Balanced-brace JSON parser for extracting M3x agentic tool calls from
/// small-LLM outputs (including fenced blocks, unclosed fences, embedded JSON,
/// and common formatting quirks).
class M3xToolCallParser {
  M3xToolCallParser._();

  static final RegExp _fenceStartPattern = RegExp(
    r'```(?:json)?\b',
    caseSensitive: false,
  );

  static final RegExp _jsonFenceOpenBracePattern = RegExp(
    r'```json\s*\{',
    caseSensitive: false,
  );

  static final RegExp _toolDraftHintPattern = RegExp(
    r'''(?:["']action["']\s*:\s*["']tool(?:\\?_)?call["']|["'](?:tool|method|function|tool_calls)["']\s*:|\{\s*["'](?:action|tool|method|function|tool_calls)["'])''',
    caseSensitive: false,
  );

  static final RegExp _controlToolCallStartPattern = RegExp(
    r'(?:<ctrl\d+>|<\|tool_call\|>)call:([a-zA-Z0-9_.:-]+)\s*\{',
    caseSensitive: false,
  );

  static final RegExp _controlToolCallTrailingTagPattern = RegExp(
    r'^(?:<ctrl\d+>|<\|tool_call\|>)',
    caseSensitive: false,
  );

  static final RegExp _controlToolCallDraftPattern = RegExp(
    r'(?:<ctrl\d+>|<\|tool_call\|>)call:',
    caseSensitive: false,
  );

  static final RegExp _strayControlTagPattern = RegExp(
    r'<ctrl\d+>|<\|tool_call\|>',
    caseSensitive: false,
  );

  /// Extracts the FIRST valid tool-call JSON object from [text], or returns `null`
  /// if none is found.
  ///
  /// Supports standard JSON / `json_call` envelopes (including fenced blocks) as
  /// well as Gemma / Gemini Nano v4 control-token tool calls such as
  /// `<ctrl42>call:wikipedia_summary{query: "paperclip maximizer"}<ctrl43>` and
  /// `<|tool_call|>call:app:tool{...}`.
  ///
  /// A decoded JSON object is treated as a tool call when:
  /// - `decoded['action'] == 'tool_call'`, OR
  /// - `decoded` contains a non-empty string `'tool'` or `'method'` key.
  static Map<String, dynamic>? extract(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // 1. Prefer fenced code blocks (supports case-insensitive ```json / ``` and missing closing fence)
    for (final blockContent in _extractFenceContents(trimmed)) {
      final found = _scanTextForToolCall(blockContent);
      if (found != null) return found;
    }

    // 2. Check Gemma / Gemini Nano v4 control-token tool calls
    final controlCall = _extractControlToolCall(trimmed);
    if (controlCall != null) return controlCall;

    // 3. Scan raw/embedded text with balanced-brace scanner
    return _scanTextForToolCall(trimmed);
  }

  /// Removes Gemma / Gemini Nano v4 control-token tool call tags
  /// (`<ctrl\d+>call:[a-zA-Z0-9_.:-]+\s*\{...\}(?:<ctrl\d+>)?` and
  /// `<|tool_call|>call:...`) along with stray `<ctrl\d+>` / `<|tool_call|>`
  /// markers so thought displays stay clean.
  static String stripControlToolTags(String text) {
    if (text.isEmpty) return text;
    final out = StringBuffer();
    int cursor = 0;

    for (final match in _controlToolCallStartPattern.allMatches(text)) {
      if (match.start < cursor) continue;
      final braceStart = match.end - 1;
      final braceEnd = _findBalancedBraceEnd(text, braceStart);
      if (braceEnd == -1) continue;

      out.write(text.substring(cursor, match.start));
      cursor = braceEnd + 1;

      final trailing = _controlToolCallTrailingTagPattern.firstMatch(
        text.substring(cursor),
      );
      if (trailing != null) {
        cursor += trailing.end;
      }
    }

    out.write(text.substring(cursor));
    return out.toString().replaceAll(_strayControlTagPattern, '').trim();
  }

  /// Returns `true` when [extract] returns `null` AND [text] appears to contain
  /// an unclosed/truncated tool-call draft (JSON or `<ctrl\d+>call:` cut off
  /// mid-stream).
  static bool looksLikeIncompleteToolCall(String text) {
    if (text.trim().isEmpty) return false;
    if (extract(text) != null) return false;

    if (_controlToolCallDraftPattern.hasMatch(text)) {
      return true;
    }

    // Check unclosed ```json { ... fence without a balanced closing } that contains a tool-call key
    for (final match in _jsonFenceOpenBracePattern.allMatches(text)) {
      final braceStart = text.indexOf('{', match.start);
      if (braceStart != -1 &&
          _findBalancedBraceEnd(text, braceStart) == -1 &&
          _toolDraftHintPattern.hasMatch(text.substring(braceStart))) {
        return true;
      }
    }

    // Scan all '{' positions for an unclosed brace whose tail looks like a tool call
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) != 0x7B /* '{' */) continue;
      final end = _findBalancedBraceEnd(text, i);
      if (end != -1) {
        // Balanced object — skip past it so inner braces don't trigger false positives
        i = end;
        continue;
      }
      final tail = text.substring(i);
      if (_toolDraftHintPattern.hasMatch(tail)) {
        return true;
      }
    }

    return false;
  }

  static List<String> _extractFenceContents(String text) {
    final blocks = <String>[];
    final matches = _fenceStartPattern.allMatches(text).toList();
    int idx = 0;
    while (idx < matches.length) {
      final openMatch = matches[idx];
      final contentStart = openMatch.end;
      // Find the next closing ``` marker (not another ```json)
      final closeIndex = text.indexOf('```', contentStart);
      if (closeIndex != -1) {
        blocks.add(text.substring(contentStart, closeIndex));
        // Advance past closing fence
        idx++;
        while (idx < matches.length && matches[idx].start <= closeIndex) {
          idx++;
        }
      } else {
        // Unclosed fence — take remainder of text
        blocks.add(text.substring(contentStart));
        break;
      }
    }
    return blocks;
  }

  static Map<String, dynamic>? _extractControlToolCall(String text) {
    for (final match in _controlToolCallStartPattern.allMatches(text)) {
      final rawTarget = match.group(1)?.trim() ?? '';
      if (rawTarget.isEmpty) continue;

      final braceStart = match.end - 1;
      final braceEnd = _findBalancedBraceEnd(text, braceStart);
      if (braceEnd == -1) continue;

      final candidateArgs = text.substring(braceStart, braceEnd + 1);
      final parsedArgs = _tryDecodeToolMap(
        candidateArgs,
        quoteUnquotedKeys: true,
      );
      if (parsedArgs == null) continue;

      String? app;
      String tool = rawTarget;
      final colonIdx = rawTarget.indexOf(':');
      if (colonIdx > 0 && colonIdx < rawTarget.length - 1) {
        app = rawTarget.substring(0, colonIdx);
        tool = rawTarget.substring(colonIdx + 1);
      }

      return <String, dynamic>{
        'action': 'tool_call',
        if (app != null) 'app': app,
        'tool': tool,
        'arguments': parsedArgs,
      };
    }
    return null;
  }

  static Map<String, dynamic>? _scanTextForToolCall(String text) {
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) != 0x7B /* '{' */) continue;

      final endIdx = _findBalancedBraceEnd(text, i);
      if (endIdx == -1) {
        // Unbalanced '{' — keep scanning forward in case a valid '{...}' follows
        continue;
      }

      final candidate = text.substring(i, endIdx + 1);
      final parsed = _tryDecodeToolMap(candidate);
      if (parsed != null) {
        if (_isToolCallMap(parsed)) {
          return parsed;
        }
        // Valid non-tool JSON object; skip over it
        i = endIdx;
      }
    }
    return null;
  }

  /// Finds the index of the matching `}` for the `{` at [startIdx], respecting
  /// `"..."` and `'...'` string literals and backslash escapes.
  /// Returns `-1` if unbalanced.
  static int _findBalancedBraceEnd(String text, int startIdx) {
    int depth = 0;
    bool inString = false;
    int stringQuote = 0;
    bool escapeNext = false;

    for (int i = startIdx; i < text.length; i++) {
      final code = text.codeUnitAt(i);

      if (inString) {
        if (escapeNext) {
          escapeNext = false;
          continue;
        }
        if (code == 0x5C /* '\' */) {
          escapeNext = true;
          continue;
        }
        if (code == stringQuote) {
          inString = false;
          stringQuote = 0;
        }
        continue;
      }

      if (code == 0x22 /* '"' */ || code == 0x27 /* "'" */) {
        inString = true;
        stringQuote = code;
      } else if (code == 0x7B /* '{' */) {
        depth++;
      } else if (code == 0x7D /* '}' */) {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }
    return -1;
  }

  static bool _isToolCallMap(Map<String, dynamic> map) {
    final action = map['action']?.toString().trim();
    if (action == 'tool_call') return true;
    final tool = map['tool'];
    if (tool is String && tool.trim().isNotEmpty) return true;
    final method = map['method'];
    if (method is String && method.trim().isNotEmpty) return true;
    return false;
  }

  static const Set<String> _emptyObjectFallbackKeys = <String>{
    'args',
    'arguments',
    'params',
  };

  static Map<String, dynamic>? _tryDecodeToolMap(
    String candidate, {
    bool quoteUnquotedKeys = false,
  }) {
    // 1. Strict JSON decode first
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {}

    if (quoteUnquotedKeys) {
      final quoted = _quoteUnquotedObjectKeys(candidate);
      try {
        final decoded = jsonDecode(quoted);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    // 2. Tolerate markdown-escaped underscores, unescaped control newlines in strings,
    // missing property values, trailing commas, and dangling valueless object keys
    final unescaped = candidate.replaceAll(r'\_', '_');
    final normalized =
        quoteUnquotedKeys ? _quoteUnquotedObjectKeys(unescaped) : unescaped;
    final sanitized = _sanitizeCandidate(normalized);
    try {
      final decoded = jsonDecode(sanitized);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {}

    // 3. Fallback: convert single-quoted JSON keys/values to double-quoted JSON
    final doubleQuoted = _sanitizeCandidate(
      _convertSingleQuotesToDouble(normalized),
    );
    try {
      final decoded = jsonDecode(doubleQuoted);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  /// Quotes unquoted object keys inside `{...}` (e.g. `{query: "abc"}` ->
  /// `{"query": "abc"}`), respecting `"..."` and `'...'` string literals so
  /// URLs and colons inside strings are never altered.
  static String _quoteUnquotedObjectKeys(String input) {
    final out = StringBuffer();
    final containerStack = <String>[];
    String lastSignificant = '';
    bool inString = false;
    String stringQuote = '';
    bool escapeNext = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inString) {
        out.write(ch);
        if (escapeNext) {
          escapeNext = false;
        } else if (ch == r'\') {
          escapeNext = true;
        } else if (ch == stringQuote) {
          inString = false;
          lastSignificant = 'string';
        }
        continue;
      }

      if (ch == '"' || ch == "'") {
        inString = true;
        stringQuote = ch;
        out.write(ch);
        continue;
      }

      if (ch == '{' || ch == '[') {
        containerStack.add(ch);
        lastSignificant = ch;
        out.write(ch);
        continue;
      }

      if (ch == '}' || ch == ']') {
        if (containerStack.isNotEmpty) {
          containerStack.removeLast();
        }
        lastSignificant = ch;
        out.write(ch);
        continue;
      }

      if (ch == ',' || ch == ':') {
        lastSignificant = ch;
        out.write(ch);
        continue;
      }

      final code = input.codeUnitAt(i);
      if (_isWhitespace(code)) {
        out.write(ch);
        continue;
      }

      if (containerStack.isNotEmpty &&
          containerStack.last == '{' &&
          (lastSignificant == '{' || lastSignificant == ',') &&
          _isKeyIdentifierStart(code)) {
        int end = i + 1;
        while (
            end < input.length && _isKeyIdentifierChar(input.codeUnitAt(end))) {
          end++;
        }
        int afterWs = end;
        while (afterWs < input.length &&
            _isWhitespace(input.codeUnitAt(afterWs))) {
          afterWs++;
        }
        if (afterWs < input.length && input[afterWs] == ':') {
          out.write('"');
          out.write(input.substring(i, end));
          out.write('"');
          lastSignificant = 'string';
          i = end - 1;
          continue;
        }
      }

      lastSignificant = ch;
      out.write(ch);
    }

    return out.toString();
  }

  static bool _isKeyIdentifierStart(int code) =>
      (code >= 0x41 && code <= 0x5A) || // A-Z
      (code >= 0x61 && code <= 0x7A) || // a-z
      (code >= 0x30 && code <= 0x39) || // 0-9
      code == 0x5F || // _
      code == 0x24; // $

  static bool _isKeyIdentifierChar(int code) =>
      _isKeyIdentifierStart(code) ||
      code == 0x2D || // -
      code == 0x2E; // .

  static String _sanitizeCandidate(String input) {
    return _stripDanglingObjectKeys(
      _stripTrailingCommas(
        _repairMissingPropertyValues(
          _escapeControlCharsInStrings(input),
        ),
      ),
    );
  }

  /// Repairs properties with missing values (e.g. `"args":}` or `"args":,`)
  /// by inserting `{}` for `"args"`/`"arguments"`/`"params"`, or `null` otherwise.
  static String _repairMissingPropertyValues(String input) {
    final out = StringBuffer();
    bool inString = false;
    String stringQuote = '';
    bool escapeNext = false;
    int? currentStringStart;
    String? lastKey;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inString) {
        out.write(ch);
        if (escapeNext) {
          escapeNext = false;
        } else if (ch == r'\') {
          escapeNext = true;
        } else if (ch == stringQuote) {
          inString = false;
          if (currentStringStart != null) {
            lastKey = input.substring(currentStringStart + 1, i);
            currentStringStart = null;
          }
        }
        continue;
      }

      if (ch == '"' || ch == "'") {
        inString = true;
        stringQuote = ch;
        currentStringStart = i;
        out.write(ch);
        continue;
      }

      if (ch == ':') {
        out.write(ch);
        int j = i + 1;
        while (j < input.length && _isWhitespace(input.codeUnitAt(j))) {
          j++;
        }
        if (j < input.length &&
            (input[j] == ',' || input[j] == '}' || input[j] == ']')) {
          final fallback =
              _emptyObjectFallbackKeys.contains(lastKey) ? '{}' : 'null';
          out.write(fallback);
        }
        lastKey = null;
        continue;
      }

      if (!_isWhitespace(input.codeUnitAt(i))) {
        lastKey = null;
      }
      out.write(ch);
    }
    return out.toString();
  }

  static String _escapeControlCharsInStrings(String input) {
    final out = StringBuffer();
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escapeNext = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inDoubleQuote || inSingleQuote) {
        if (escapeNext) {
          out.write(ch);
          escapeNext = false;
          continue;
        }
        if (ch == r'\') {
          out.write(ch);
          escapeNext = true;
          continue;
        }
        if (inDoubleQuote && ch == '"') {
          inDoubleQuote = false;
          out.write(ch);
          continue;
        }
        if (inSingleQuote && ch == "'") {
          inSingleQuote = false;
          out.write(ch);
          continue;
        }
        if (ch == '\r') {
          if (i + 1 < input.length && input[i + 1] == '\n') {
            i++;
          }
          out.write(r'\n');
          continue;
        }
        if (ch == '\n') {
          out.write(r'\n');
          continue;
        }
        if (ch == '\t') {
          out.write(r'\t');
          continue;
        }
        out.write(ch);
      } else {
        if (ch == '"') {
          inDoubleQuote = true;
        } else if (ch == "'") {
          inSingleQuote = true;
        }
        out.write(ch);
      }
    }
    return out.toString();
  }

  static String _stripTrailingCommas(String input) {
    final out = StringBuffer();
    bool inString = false;
    String stringQuote = '';
    bool escapeNext = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inString) {
        out.write(ch);
        if (escapeNext) {
          escapeNext = false;
        } else if (ch == r'\') {
          escapeNext = true;
        } else if (ch == stringQuote) {
          inString = false;
        }
        continue;
      }

      if (ch == '"' || ch == "'") {
        inString = true;
        stringQuote = ch;
        out.write(ch);
        continue;
      }

      if (ch == ',') {
        int j = i + 1;
        while (j < input.length && _isWhitespace(input.codeUnitAt(j))) {
          j++;
        }
        if (j < input.length && (input[j] == '}' || input[j] == ']')) {
          // Drop trailing comma before closing '}' or ']'
          continue;
        }
      }
      out.write(ch);
    }
    return out.toString();
  }

  /// Strips lone trailing valueless key strings inside JSON objects directly
  /// before `}` (e.g. `{"tool": "x", "args": {}, ""}` or `{"tool": "x", "foo"}`).
  static String _stripDanglingObjectKeys(String input) {
    final out = StringBuffer();
    final containerStack = <String>[];
    String lastSignificant = '';
    bool inString = false;
    String stringQuote = '';
    bool escapeNext = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inString) {
        out.write(ch);
        if (escapeNext) {
          escapeNext = false;
        } else if (ch == r'\') {
          escapeNext = true;
        } else if (ch == stringQuote) {
          inString = false;
          lastSignificant = 'string';
        }
        continue;
      }

      if (ch == ',') {
        if (containerStack.isNotEmpty && containerStack.last == '{') {
          final afterDangling = _findDanglingObjectKeyEnd(input, i + 1);
          if (afterDangling != null) {
            i = afterDangling - 1;
            continue;
          }
        }
        lastSignificant = ',';
        out.write(ch);
        continue;
      }

      if (ch == '"' || ch == "'") {
        if (containerStack.isNotEmpty &&
            containerStack.last == '{' &&
            lastSignificant == '{') {
          final afterDangling = _findDanglingObjectKeyEnd(input, i);
          if (afterDangling != null) {
            i = afterDangling - 1;
            continue;
          }
        }
        inString = true;
        stringQuote = ch;
        out.write(ch);
        continue;
      }

      if (ch == '{' || ch == '[') {
        containerStack.add(ch);
        lastSignificant = ch;
        out.write(ch);
        continue;
      }

      if (ch == '}' || ch == ']') {
        if (containerStack.isNotEmpty) {
          containerStack.removeLast();
        }
        lastSignificant = ch;
        out.write(ch);
        continue;
      }

      if (!_isWhitespace(input.codeUnitAt(i))) {
        lastSignificant = ch;
      }
      out.write(ch);
    }
    return out.toString();
  }

  /// If [input] from [startIndex] contains only optional whitespace, one string
  /// literal, and optional whitespace followed by `}`, returns that `}` index.
  static int? _findDanglingObjectKeyEnd(String input, int startIndex) {
    int j = startIndex;
    while (j < input.length && _isWhitespace(input.codeUnitAt(j))) {
      j++;
    }
    if (j >= input.length) return null;
    final quote = input[j];
    if (quote != '"' && quote != "'") return null;

    j++;
    bool escapeNext = false;
    while (j < input.length) {
      final ch = input[j];
      if (escapeNext) {
        escapeNext = false;
      } else if (ch == r'\') {
        escapeNext = true;
      } else if (ch == quote) {
        break;
      }
      j++;
    }
    if (j >= input.length || input[j] != quote) return null;

    j++;
    while (j < input.length && _isWhitespace(input.codeUnitAt(j))) {
      j++;
    }
    if (j < input.length && input[j] == '}') {
      return j;
    }
    return null;
  }

  static String _convertSingleQuotesToDouble(String input) {
    final out = StringBuffer();
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escapeNext = false;

    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inDoubleQuote) {
        out.write(ch);
        if (escapeNext) {
          escapeNext = false;
        } else if (ch == r'\') {
          escapeNext = true;
        } else if (ch == '"') {
          inDoubleQuote = false;
        }
        continue;
      }

      if (inSingleQuote) {
        if (escapeNext) {
          if (ch == "'") {
            out.write("'");
          } else {
            out.write(r'\');
            out.write(ch);
          }
          escapeNext = false;
          continue;
        }
        if (ch == r'\') {
          escapeNext = true;
          continue;
        }
        if (ch == '"') {
          out.write(r'\"');
          continue;
        }
        if (ch == "'") {
          inSingleQuote = false;
          out.write('"');
          continue;
        }
        out.write(ch);
        continue;
      }

      if (ch == '"') {
        inDoubleQuote = true;
        out.write(ch);
      } else if (ch == "'") {
        inSingleQuote = true;
        out.write('"');
      } else {
        out.write(ch);
      }
    }
    return out.toString();
  }

  static bool _isWhitespace(int code) =>
      code == 0x20 || code == 0x0A || code == 0x0D || code == 0x09;
}
