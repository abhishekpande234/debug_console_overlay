import 'package:dio/dio.dart';
import 'http_logger.dart';
import 'network_request_manager.dart';

/// Dio interceptor that automatically logs HTTP requests and responses to the debug console
/// 
/// Usage:
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(DebugConsoleInterceptor());
/// ```
class DebugConsoleInterceptor extends Interceptor {
  final String? tag;
  final bool logRequestHeaders;
  final bool logRequestBody;
  final bool logResponseHeaders;
  final bool logResponseBody;
  final int maxContentLength;

  const DebugConsoleInterceptor({
    this.tag,
    this.logRequestHeaders = true,
    this.logRequestBody = true,
    this.logResponseHeaders = true,
    this.logResponseBody = true,
    this.maxContentLength = 2000,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final stopwatch = HttpStopwatch()..start();
    options.extra['_debug_stopwatch'] = stopwatch;

    // Start the request in NetworkRequestManager
    NetworkRequestManager.instance.startRequest(
      options.method,
      options.uri.toString(),
      tag: tag ?? 'DIO_REQ',
      requestData: {
        'headers': logRequestHeaders ? _extractHeaders(options.headers) : null,
        'body': logRequestBody ? _extractRequestData(options) : null,
      },
    );

    // Also log using the existing logger for backwards compatibility
    DebugHttpLogger.logRequest(
      method: options.method,
      url: options.uri.toString(),
      headers: logRequestHeaders ? _extractHeaders(options.headers) : null,
      body: logRequestBody ? _extractRequestData(options) : null,
      tag: tag ?? 'DIO_REQ',
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final stopwatch = response.requestOptions.extra['_debug_stopwatch'] as HttpStopwatch?;
    stopwatch?.stop();

    // Complete the request in NetworkRequestManager
    NetworkRequestManager.instance.completeRequest(
      response.requestOptions.method,
      response.requestOptions.uri.toString(),
      response.statusCode ?? 200,
      responseData: {
        'headers': logResponseHeaders ? _extractHeaders(response.headers.map) : null,
        'body': logResponseBody ? _extractResponseData(response) : null,
        'statusMessage': response.statusMessage,
        'duration': stopwatch?.elapsedMilliseconds,
      },
    );

    // Also log using the existing logger for backwards compatibility
    DebugHttpLogger.logResponse(
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      statusCode: response.statusCode ?? 0,
      durationMs: stopwatch?.elapsedMilliseconds,
      headers: logResponseHeaders ? _extractHeaders(response.headers.map) : null,
      body: logResponseBody ? _extractResponseData(response) : null,
      tag: tag ?? 'DIO_RES',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final stopwatch = err.requestOptions.extra['_debug_stopwatch'] as HttpStopwatch?;
    stopwatch?.stop();

    // Fail the request in NetworkRequestManager
    NetworkRequestManager.instance.failRequest(
      err.requestOptions.method,
      err.requestOptions.uri.toString(),
      _formatDioError(err),
      statusCode: err.response?.statusCode,
    );

    // Also log using the existing logger for backwards compatibility
    DebugHttpLogger.logError(
      method: err.requestOptions.method,
      url: err.requestOptions.uri.toString(),
      error: _formatDioError(err),
      durationMs: stopwatch?.elapsedMilliseconds,
      tag: tag ?? 'DIO_ERR',
    );

    handler.next(err);
  }

  Map<String, String> _extractHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) => MapEntry(key, value.toString()));
  }

  Object? _extractRequestData(RequestOptions options) {
    final data = options.data;
    if (data == null) return null;

    if (data is FormData) {
      return _formatFormData(data);
    }

    return _truncateContent(data.toString());
  }

  Object? _extractResponseData(Response response) {
    final data = response.data;
    if (data == null) return null;

    return _truncateContent(data.toString());
  }

  String _formatFormData(FormData formData) {
    final buffer = StringBuffer();
    buffer.writeln('FormData:');
    
    for (final field in formData.fields) {
      buffer.writeln('  ${field.key}: ${field.value}');
    }
    
    for (final file in formData.files) {
      buffer.writeln('  ${file.key}: ${file.value.filename ?? 'file'} (${file.value.length} bytes)');
    }
    
    return buffer.toString().trim();
  }

  String _formatDioError(DioException error) {
    final buffer = StringBuffer();
    
    buffer.writeln('DioException: ${error.type.name}');
    buffer.writeln('Message: ${error.message}');
    
    if (error.response != null) {
      buffer.writeln('Status Code: ${error.response!.statusCode}');
      if (error.response!.data != null) {
        buffer.writeln('Response: ${_truncateContent(error.response!.data.toString())}');
      }
    }
    
    return buffer.toString().trim();
  }

  String _truncateContent(String content) {
    if (content.length <= maxContentLength) return content;
    return '${content.substring(0, maxContentLength)}...\n[Truncated - ${content.length} total chars]';
  }
}

/// Extension to easily add debug console logging to Dio instances
extension DioDebugConsoleExtension on Dio {
  /// Add debug console interceptor with default settings
  void addDebugConsole({
    String? tag,
    bool logRequestHeaders = true,
    bool logRequestBody = true,
    bool logResponseHeaders = true,
    bool logResponseBody = true,
    int maxContentLength = 2000,
  }) {
    interceptors.add(DebugConsoleInterceptor(
      tag: tag,
      logRequestHeaders: logRequestHeaders,
      logRequestBody: logRequestBody,
      logResponseHeaders: logResponseHeaders,
      logResponseBody: logResponseBody,
      maxContentLength: maxContentLength,
    ));
  }
}
