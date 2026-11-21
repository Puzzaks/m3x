import 'package:flutter/foundation.dart';
import 'package:m3x_core/m3x_core.dart';

void main() {
  final analytics = AnalyticsService(
    notifyEngine: () {},
    onRemoteLog: (thread, type, message) {
      debugPrint('[$thread][$type] $message');
    },
  );

  analytics.log('Network', 'Info', 'Polling status');
  analytics.log('Network', 'Info', 'Polling status'); // Deduplicated (count: 2)

  debugPrint('Entries: ${analytics.logs.length}');
  debugPrint('Count: ${analytics.logs.first['count']}');
  debugPrint('Size: ${M3xFormatters.formatBytes(1572864)}');
  debugPrint('Speed: ${M3xFormatters.formatNetworkSpeed(12500000)}');
  debugPrint(
      'Duration: ${M3xFormatters.formatDuration(const Duration(minutes: 4, seconds: 12))}');
}
