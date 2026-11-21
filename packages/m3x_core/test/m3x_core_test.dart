import 'package:flutter_test/flutter_test.dart';
import 'package:m3x_core/m3x_core.dart';

void main() {
  group('M3xFormatters / PuzzakFormatters', () {
    test('formatBytes formats byte sizes across units with configurable decimals', () {
      expect(M3xFormatters.formatBytes(0), equals('0 B'));
      expect(M3xFormatters.formatBytes(512), equals('512 B'));
      expect(M3xFormatters.formatBytes(1024), equals('1.0 KB'));
      expect(M3xFormatters.formatBytes(1536, decimals: 2), equals('1.50 KB'));
      expect(M3xFormatters.formatBytes(1048576), equals('1.0 MB'));
      expect(M3xFormatters.formatBytes(1073741824), equals('1.0 GB'));
      expect(M3xFormatters.formatBytes(1099511627776), equals('1.0 TB'));
      expect(M3xFormatters.formatBytes(-2048), equals('-2.0 KB'));
    });

    test('formatBytes and formatNetworkSpeed support throughput and bit-rate scaling', () {
      expect(
        M3xFormatters.formatBytes(0, isThroughput: true),
        equals('0 B/s'),
      );
      expect(
        M3xFormatters.formatBytes(0, isThroughput: true, useBits: true),
        equals('0 bps'),
      );
      expect(
        M3xFormatters.formatBytes(2048, isThroughput: true),
        equals('2.0 KB/s'),
      );
      expect(
        M3xFormatters.formatBytes(1024, useBits: true),
        equals('8.0 Kb'),
      );
      expect(
        M3xFormatters.formatNetworkSpeed(1024, useBits: true),
        equals('8.0 Kbps'),
      );
      expect(
        formatNetworkSpeed(131072, useBits: true),
        equals('1.0 Mbps'),
      );
    });

    test('convertSize formats storage sizes and transfer speeds', () {
      expect(M3xFormatters.convertSize(4096, false), equals('4.0 KB'));
      expect(convertSize(4096, true), equals('4.0 KB/s'));
    });

    test('formatDuration formats elapsed durations with and without seconds', () {
      expect(
        M3xFormatters.formatDuration(const Duration(seconds: 42)),
        equals('42s'),
      );
      expect(
        M3xFormatters.formatDuration(const Duration(minutes: 5, seconds: 9)),
        equals('5m 9s'),
      );
      expect(
        M3xFormatters.formatDuration(
          const Duration(days: 14, hours: 6, minutes: 23, seconds: 15),
        ),
        equals('14d 6h 23m 15s'),
      );
      expect(
        formatDuration(
          const Duration(days: 14, hours: 6, minutes: 23, seconds: 15),
          includeSeconds: false,
        ),
        equals('14d 6h 23m'),
      );
      expect(
        M3xFormatters.formatDuration(
          const Duration(seconds: 30),
          includeSeconds: false,
        ),
        equals('0m'),
      );
      expect(
        M3xFormatters.formatDuration(const Duration(minutes: -3, seconds: -10)),
        equals('-3m 10s'),
      );
    });
  });

  group('AnalyticsService', () {
    test('records events, notifies listeners, and deduplicates consecutive identical logs', () {
      int notifyCount = 0;
      final remoteEvents = <String>[];

      final service = AnalyticsService(
        notifyEngine: () => notifyCount++,
        defaultEnabled: true,
        onRemoteLog: (thread, type, message) {
          remoteEvents.add('$thread|$type|$message');
        },
      );

      service.log('MeshClient', 'Info', 'Heartbeat OK');
      expect(service.logs.length, equals(1));
      expect(service.logs.first['thread'], equals('MeshClient'));
      expect(service.logs.first['type'], equals('Info'));
      expect(service.logs.first['message'], equals('Heartbeat OK'));
      expect(service.logs.first['count'], equals(1));
      expect(service.logs.first['time'], isA<int>());
      expect(notifyCount, equals(1));
      expect(remoteEvents.length, equals(1));

      // Logging identical (thread, type, message) increments count in-place
      service.log('MeshClient', 'Info', 'Heartbeat OK');
      service.log('MeshClient', 'Info', 'Heartbeat OK');
      expect(service.logs.length, equals(1));
      expect(service.logs.first['count'], equals(3));
      expect(notifyCount, equals(3));
      expect(remoteEvents.length, equals(3));

      // Logging a different message appends a new entry
      service.log('MeshClient', 'Warning', 'Timeout on node');
      expect(service.logs.length, equals(2));
      expect(service.logs.last['count'], equals(1));
      expect(service.logs.last['type'], equals('Warning'));
    });

    test('supports filtering/exporting log entries and clearing logs', () {
      int notifyCount = 0;
      final service = AnalyticsService(notifyEngine: () => notifyCount++);

      service.log('Auth', 'Info', 'Token refreshed');
      service.log('Network', 'Error', 'Socket closed');
      service.log('Auth', 'Warning', 'Slow response');

      final errorLogs =
          service.logs.where((entry) => entry['type'] == 'Error').toList();
      expect(errorLogs.length, equals(1));
      expect(errorLogs.first['message'], equals('Socket closed'));

      final authLogs =
          service.logs.where((entry) => entry['thread'] == 'Auth').toList();
      expect(authLogs.length, equals(2));

      service.clearLogs();
      expect(service.logs, isEmpty);
      expect(notifyCount, equals(4));
    });

    test('toggleAnalytics persists state, triggers callback, and gates onRemoteLog', () async {
      final remoteEvents = <String>[];
      final persisted = <String, dynamic>{};
      bool? toggledState;

      final service = AnalyticsService(
        notifyEngine: () {},
        defaultEnabled: false,
        onRemoteLog: (thread, type, message) {
          remoteEvents.add('$thread:$message');
        },
        onAnalyticsToggled: (enabled) async {
          toggledState = enabled;
        },
      );

      // Remote logging is suppressed when analyticsEnabled is false
      service.log('Boot', 'Info', 'Started offline');
      expect(remoteEvents, isEmpty);

      await service.toggleAnalytics(
        true,
        persist: (k, v) async => persisted[k] = v,
      );
      expect(service.analyticsEnabled, isTrue);
      expect(persisted['analytics'], isTrue);
      expect(toggledState, isTrue);
      expect(remoteEvents, contains('Analytics:Analytics enabled'));

      await service.toggleAnalytics(
        false,
        persist: (k, v) async => persisted[k] = v,
      );
      expect(service.analyticsEnabled, isFalse);
      expect(persisted['analytics'], isFalse);
      expect(toggledState, isFalse);
    });
  });
}
