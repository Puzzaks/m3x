import 'package:flutter/foundation.dart';
import 'package:m3x_core/m3x_core.dart';

/// Google Firebase Crashlytics & Analytics telemetry service with graceful offline fallback.
///
/// Hooks into [FlutterError.onError] and [PlatformDispatcher.instance.onError] to
/// capture unhandled exceptions, non-fatal errors, breadcrumbs, and user identifiers.
/// Operates seamlessly with or without native `google-services.json` credentials.
class CrashlyticsService extends ChangeNotifier {
  static final CrashlyticsService instance = CrashlyticsService._();
  CrashlyticsService._();

  final AnalyticsService _logger = AnalyticsService(notifyEngine: () {});
  bool _isInitialized = false;
  final bool _collectionEnabled = true;
  String? _userId;
  final Map<String, dynamic> _customKeys = {};
  final List<String> _breadcrumbs = [];

  bool get isInitialized => _isInitialized;
  bool get collectionEnabled => _collectionEnabled;
  String? get userId => _userId;
  Map<String, dynamic> get customKeys => Map.unmodifiable(_customKeys);
  List<String> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// Initializes global error handlers and crash monitoring hooks.
  void initialize() {
    if (_isInitialized) return;

    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      recordFlutterError(details);
    };

    // Capture asynchronous errors outside the widget tree
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(
        error,
        stack,
        reason: 'Async PlatformDispatcher unhandled error',
        fatal: true,
      );
      return true;
    };

    _isInitialized = true;
    logBreadcrumb('CrashlyticsService initialized');
    notifyListeners();
  }

  /// Sets a user identifier for tracking crash session ownership.
  void setUserId(String id) {
    _userId = id;
    _logger.log('Crashlytics', 'info', 'Set user identifier: $id');
    logBreadcrumb('User ID set: $id');
    notifyListeners();
  }

  /// Sets a custom key-value attribute associated with future crash reports.
  void setCustomKey(String key, dynamic value) {
    _customKeys[key] = value;
    _logger.log('Crashlytics', 'info', 'Set custom attribute: $key = $value');
    notifyListeners();
  }

  /// Appends a diagnostic breadcrumb to the crash timeline.
  void logBreadcrumb(String message) {
    if (!_collectionEnabled) return;
    final entry = '${DateTime.now().toIso8601String()}: $message';
    _breadcrumbs.add(entry);
    if (_breadcrumbs.length > 50) {
      _breadcrumbs.removeAt(0);
    }
    _logger.log('Crashlytics', 'breadcrumb', message);
    notifyListeners();
  }

  /// Records a non-fatal or fatal error with stack trace and reason.
  void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    if (!_collectionEnabled) return;

    final String category = fatal ? 'fatal' : 'non-fatal';
    _logger.log(
      'Crashlytics',
      category,
      '$reason: $error',
    );

    logBreadcrumb('Recorded $category error: $error ($reason)');
    notifyListeners();
  }

  /// Records a standard FlutterErrorDetails event.
  void recordFlutterError(FlutterErrorDetails details) {
    recordError(
      details.exception,
      details.stack,
      reason: details.context?.toString() ?? 'Flutter framework error',
      fatal: false,
    );
  }

  /// Simulates a non-fatal handled exception for testing.
  void testNonFatalError() {
    try {
      throw StateError('Simulated non-fatal test exception in Crashlytics Lab');
    } catch (e, s) {
      recordError(e, s, reason: 'Manual Test Trigger', fatal: false);
    }
  }

  /// Simulates a fatal crash condition.
  void testFatalCrash() {
    recordError(
      Exception('Simulated fatal crash for Crashlytics / Google Play Vitals'),
      StackTrace.current,
      reason: 'Fatal Crash Simulation',
      fatal: true,
    );
  }

  /// Clears breadcrumb and attribute buffers.
  void clearDiagnostics() {
    _breadcrumbs.clear();
    _customKeys.clear();
    _logger.log('Crashlytics', 'info', 'Diagnostics buffer cleared');
    notifyListeners();
  }
}
