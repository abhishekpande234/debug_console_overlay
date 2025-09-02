import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'debug_console.dart';
import 'models.dart';

/// Helper class for manually logging HTTP requests and responses
class DebugHttpLogger {
  static bool _enabled = kDebugMode;
  static bool logHeaders = true;
  static bool logBody = true;
  static int maxBodyLength = 1000;

  /// Enable/disable HTTP logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Configure logging options
  static void configure({
    bool? headers,
    bool? body,
    int? maxBody,
  }) {
    if (headers != null) logHeaders = headers;
    if (body != null) logBody = body;
    if (maxBody != null) maxBodyLength = maxBody;
  }

  /// Log an HTTP request
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Object? body,
    String? tag,
  }) {
    if (!_enabled) return;

    final buffer = StringBuffer();
    buffer.writeln('🔵 $method $url');
    
    if (logHeaders && headers != null && headers.isNotEmpty) {
      buffer.writeln('📋 Headers:');
      headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    if (logBody && body != null) {
      buffer.writeln('📝 Request Body:');
      final bodyStr = _formatBody(body);
      buffer.writeln(bodyStr);
    }
    
    DebugConsoleOverlay.log(
      buffer.toString().trim(),
      level: LogLevel.info,
      tag: tag ?? 'HTTP_REQ',
    );
  }

  /// Log an HTTP response
  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    int? durationMs,
    Map<String, String>? headers,
    Object? body,
    String? tag,
  }) {
    if (!_enabled) return;

    final buffer = StringBuffer();
    final statusColor = statusCode < 400 ? '🟢' : '🔴';
    
    buffer.writeln('$statusColor $statusCode $method $url');
    
    if (durationMs != null) {
      buffer.writeln('⏱️  Duration: ${durationMs}ms');
    }
    
    if (logHeaders && headers != null && headers.isNotEmpty) {
      buffer.writeln('📋 Response Headers:');
      headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    if (logBody && body != null) {
      buffer.writeln('📝 Response Body:');
      final bodyStr = _formatBody(body);
      buffer.writeln(bodyStr);
    }
    
    final logLevel = statusCode < 400 ? LogLevel.info : LogLevel.warn;
    DebugConsoleOverlay.log(
      buffer.toString().trim(),
      level: logLevel,
      tag: tag ?? 'HTTP_RES',
    );
  }

  /// Log an HTTP error
  static void logError({
    required String method,
    required String url,
    required Object error,
    int? durationMs,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!_enabled) return;

    final buffer = StringBuffer();
    buffer.writeln('🔴 ERROR $method $url');
    
    if (durationMs != null) {
      buffer.writeln('⏱️  Duration: ${durationMs}ms');
    }
    
    buffer.writeln('❌ Error: $error');
    
    if (stackTrace != null && kDebugMode) {
      buffer.writeln('📍 Stack Trace:');
      buffer.writeln(stackTrace.toString().split('\n').take(5).join('\n'));
    }
    
    DebugConsoleOverlay.log(
      buffer.toString().trim(),
      level: LogLevel.error,
      tag: tag ?? 'HTTP_ERR',
    );
  }

  /// Format body content for logging
  static String _formatBody(Object body) {
    if (body is String) {
      if (body.isEmpty) return '(empty)';
      
      // Try to format as JSON if possible
      try {
        final jsonObject = jsonDecode(body);
        final prettyJson = JsonEncoder.withIndent('  ').convert(jsonObject);
        return _truncateIfNeeded(prettyJson);
      } catch (_) {
        return _truncateIfNeeded(body);
      }
    } else if (body is Map || body is List) {
      try {
        final prettyJson = JsonEncoder.withIndent('  ').convert(body);
        return _truncateIfNeeded(prettyJson);
      } catch (_) {
        return _truncateIfNeeded(body.toString());
      }
    } else {
      return _truncateIfNeeded(body.toString());
    }
  }

  /// Truncate content if it exceeds maxBodyLength
  static String _truncateIfNeeded(String content) {
    if (content.length <= maxBodyLength) return content;
    return '${content.substring(0, maxBodyLength)}...\n[Content truncated - ${content.length} total characters]';
  }
}

/// Helper class for timing HTTP requests
class HttpStopwatch {
  final Stopwatch _stopwatch = Stopwatch();
  
  void start() => _stopwatch.start();
  void stop() => _stopwatch.stop();
  void reset() => _stopwatch.reset();
  
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
  Duration get elapsed => _stopwatch.elapsed;
}

/// Extension methods for common HTTP packages
extension HttpResponseLogging on Object {
  /// Quick helper to log any response-like object
  void logAsHttpResponse({
    required String method,
    required String url,
    required int statusCode,
    int? durationMs,
    Map<String, String>? headers,
    Object? body,
    String? tag,
  }) {
    DebugHttpLogger.logResponse(
      method: method,
      url: url,
      statusCode: statusCode,
      durationMs: durationMs,
      headers: headers,
      body: body,
      tag: tag,
    );
  }
}
