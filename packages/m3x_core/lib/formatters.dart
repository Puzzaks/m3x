/// Shared byte, network throughput, and duration formatters used across
/// `PTK`, `geminilocal`, and `Website`.
class PuzzakFormatters {
  const PuzzakFormatters._();

  static const List<String> _byteUnits = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  static const List<String> _bitUnits = <String>[
    'bps',
    'Kbps',
    'Mbps',
    'Gbps',
    'Tbps',
  ];
  static const List<String> _rawBitUnits = <String>[
    'b',
    'Kb',
    'Mb',
    'Gb',
    'Tb',
  ];

  /// Formats [bytes] into a human-readable size or throughput string.
  ///
  /// - When [isThroughput] is `true`, appends `/s` for byte units (e.g. `MB/s`)
  ///   or uses bit-rate units (`bps`, `Kbps`, `Mbps`, `Gbps`) when [useBits]
  ///   is also `true`.
  /// - When [useBits] is `true`, multiplies [bytes] by `8` before scaling.
  /// - [decimals] controls fractional precision for scaled units (`>= 1024`).
  static String formatBytes(
    num bytes, {
    bool isThroughput = false,
    bool useBits = false,
    int decimals = 1,
  }) {
    final bool isNegative = bytes < 0;
    double value = bytes.abs().toDouble();
    if (useBits) {
      value *= 8.0;
    }

    final List<String> units =
        useBits ? (isThroughput ? _bitUnits : _rawBitUnits) : _byteUnits;
    final String suffix = (!useBits && isThroughput) ? '/s' : '';

    if (value == 0) {
      return '0 ${units.first}$suffix';
    }

    int unitIndex = 0;
    while (value >= 1024.0 && unitIndex < units.length - 1) {
      value /= 1024.0;
      unitIndex++;
    }

    final String sign = isNegative ? '-' : '';
    final int safeDecimals = decimals < 0 ? 0 : decimals;

    if (unitIndex == 0 && value == value.roundToDouble()) {
      return '$sign${value.toInt()} ${units[unitIndex]}$suffix';
    }
    return '$sign${value.toStringAsFixed(safeDecimals)} ${units[unitIndex]}$suffix';
  }

  /// Formats [bytesPerSecond] as a network throughput string.
  static String formatNetworkSpeed(
    num bytesPerSecond, {
    bool useBits = false,
    int decimals = 1,
  }) {
    return formatBytes(
      bytesPerSecond,
      isThroughput: true,
      useBits: useBits,
      decimals: decimals,
    );
  }

  /// Formats an integer byte [size] as either a storage size (`isSpeed == false`)
  /// or transfer speed (`isSpeed == true`), matching `geminilocal`'s `convertSize`.
  static String convertSize(int size, bool isSpeed) {
    return formatBytes(size, isThroughput: isSpeed, decimals: 1);
  }

  /// Formats a [Duration] into a compact human-readable uptime/elapsed string
  /// (e.g. `2d 4h 15m 30s`, `1h 05m`, `42s`), matching `PTK` and `Website`.
  static String formatDuration(Duration d, {bool includeSeconds = true}) {
    final Duration absDuration = d.isNegative ? d.abs() : d;
    final int days = absDuration.inDays;
    final int hours = absDuration.inHours.remainder(24);
    final int minutes = absDuration.inMinutes.remainder(60);
    final int seconds = absDuration.inSeconds.remainder(60);

    final List<String> parts = <String>[];
    if (days > 0) {
      parts.add('${days}d');
    }
    if (hours > 0 || days > 0) {
      parts.add('${hours}h');
    }
    if (minutes > 0 || hours > 0 || days > 0 || !includeSeconds) {
      parts.add('${minutes}m');
    }
    if (includeSeconds) {
      parts.add('${seconds}s');
    }

    final String sign = d.isNegative ? '-' : '';
    return '$sign${parts.join(' ')}';
  }
}

/// Top-level convenience wrapper for [PuzzakFormatters.formatBytes].
String formatBytes(
  num bytes, {
  bool isThroughput = false,
  bool useBits = false,
  int decimals = 1,
}) =>
    PuzzakFormatters.formatBytes(
      bytes,
      isThroughput: isThroughput,
      useBits: useBits,
      decimals: decimals,
    );

/// Top-level convenience wrapper for [PuzzakFormatters.formatNetworkSpeed].
String formatNetworkSpeed(
  num bytesPerSecond, {
  bool useBits = false,
  int decimals = 1,
}) =>
    PuzzakFormatters.formatNetworkSpeed(
      bytesPerSecond,
      useBits: useBits,
      decimals: decimals,
    );

/// Top-level convenience wrapper for [PuzzakFormatters.convertSize]
/// (drop-in compatible with `geminilocal`).
String convertSize(int size, bool isSpeed) =>
    PuzzakFormatters.convertSize(size, isSpeed);

/// Top-level convenience wrapper for [PuzzakFormatters.formatDuration]
/// (drop-in compatible with `PTK` and `Website`).
String formatDuration(Duration d, {bool includeSeconds = true}) =>
    PuzzakFormatters.formatDuration(d, includeSeconds: includeSeconds);

/// Modern alias for [PuzzakFormatters] under the M3x brand.
typedef M3xFormatters = PuzzakFormatters;
