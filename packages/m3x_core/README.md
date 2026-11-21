# m3x_core

Shared core utilities, deduplicating `AnalyticsService` logger, and byte/throughput/duration formatters (`M3xFormatters`) for the [M3x](https://github.com/Puzzaks/m3x) Flutter ecosystem — with **zero third-party dependencies**.

## Features

### 1. `AnalyticsService` (`analytics_service.dart`)
In-memory and optional remote telemetry logger with automatic consecutive event deduplication:
- Consecutive identical `(thread, type, message)` entries update `time` in-place and increment `count` rather than flooding the log list.
- Preserves `"thread"`, `"time"`, `"type"`, `"message"`, and `"count"` keys on every entry in `logs`.
- Supports `clearLogs()` and `toggleAnalytics(value, persist: ...)`.

```dart
import 'package:m3x_core/m3x_core.dart';

final analytics = AnalyticsService(
  notifyEngine: () => setState(() {}),
  onRemoteLog: (thread, type, message) {
    // Forward to your remote telemetry sink when analyticsEnabled is true
  },
);

analytics.log('Network', 'Info', 'Polling status');
analytics.log('Network', 'Info', 'Polling status'); // Increments count to 2
```

### 2. `M3xFormatters` (`formatters.dart`)
Provides static methods on `M3xFormatters` (and `PuzzakFormatters` alias) plus top-level helpers:
- `formatBytes(num bytes, {bool isThroughput = false, bool useBits = false, int decimals = 1})`
- `formatNetworkSpeed(num bytesPerSecond, {bool useBits = false, int decimals = 1})`
- `convertSize(int size, bool isSpeed)`
- `formatDuration(Duration d, {bool includeSeconds = true})`

## License

Released into the public domain under [The Unlicense](LICENSE).
