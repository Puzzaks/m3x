import 'package:flutter/foundation.dart';

/// Shared in-memory and optional remote telemetry logger with automatic
/// consecutive log deduplication.
///
/// Backwards-compatible with `AnalyticsService` in `PTK`, `the2k48`, and
/// `geminilocal`.
class AnalyticsService {
  /// Callback invoked whenever [logs] or [analyticsEnabled] changes so the
  /// host engine or UI can rebuild.
  final VoidCallback notifyEngine;

  /// Optional callback invoked when [analyticsEnabled] is `true` to forward
  /// log events to a remote backend (such as Firebase Analytics or Crashlytics).
  final void Function(String thread, String type, String message)? onRemoteLog;

  /// Optional callback invoked when the user toggles [analyticsEnabled].
  final Future<void> Function(bool enabled)? onAnalyticsToggled;

  /// Whether remote telemetry forwarding is currently enabled.
  bool analyticsEnabled;

  /// Chronological list of structured log entries.
  ///
  /// Each entry contains:
  /// - `"thread"`: `String` source/subsystem name
  /// - `"time"`: `int` epoch timestamp in milliseconds
  /// - `"type"`: `String` severity or category (e.g. `"Info"`, `"Warning"`, `"Error"`)
  /// - `"message"`: `String` log payload
  /// - `"count"`: `int` consecutive occurrence count (starts at `1`)
  List<Map<String, dynamic>> logs = [];

  AnalyticsService({
    required this.notifyEngine,
    this.onRemoteLog,
    this.onAnalyticsToggled,
    bool defaultEnabled = false,
  }) : analyticsEnabled = defaultEnabled;

  /// Records a log entry from [name] with category [type] and text [message].
  ///
  /// If the most recent entry in [logs] has the exact same `thread`, `type`,
  /// and `message`, updates its `"time"` timestamp and increments its `"count"`
  /// in-place instead of appending a duplicate row.
  void log(String name, String type, String message) {
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (logs.isNotEmpty &&
        logs.last["thread"] == name &&
        logs.last["type"] == type &&
        logs.last["message"] == message) {
      logs.last["time"] = now;
      final dynamic prevCount = logs.last["count"];
      logs.last["count"] = (prevCount is int ? prevCount : 1) + 1;
    } else {
      logs.add(<String, dynamic>{
        "thread": name,
        "time": now,
        "type": type,
        "message": message,
        "count": 1,
      });
    }

    notifyEngine();

    if (analyticsEnabled && onRemoteLog != null) {
      onRemoteLog!(name, type, message);
    }
  }

  /// Clears all in-memory [logs] and notifies the host engine.
  void clearLogs() {
    logs.clear();
    notifyEngine();
  }

  /// Updates [analyticsEnabled] to [value], optionally persists the setting via
  /// [persist], notifies [onAnalyticsToggled], and logs the state transition.
  Future<void> toggleAnalytics(
    bool value, {
    Future<void> Function(String key, dynamic val)? persist,
  }) async {
    analyticsEnabled = value;
    if (persist != null) {
      await persist("analytics", value);
    }
    if (onAnalyticsToggled != null) {
      await onAnalyticsToggled!(value);
    }
    log(
      "Analytics",
      "Info",
      "Analytics ${value ? 'enabled' : 'disabled'}",
    );
  }
}
