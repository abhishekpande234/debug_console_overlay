import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'event_bus.dart';

/// Manages network requests and provides real-time status updates
class NetworkRequestManager {
  static final NetworkRequestManager _instance = NetworkRequestManager._internal();
  static NetworkRequestManager get instance => _instance;
  NetworkRequestManager._internal();

  final Map<String, NetworkRequestStatus> _activeRequests = {};
  final StreamController<Map<String, NetworkRequestStatus>> _streamController = 
      StreamController<Map<String, NetworkRequestStatus>>.broadcast();
  
  Stream<Map<String, NetworkRequestStatus>> get requestsStream => _streamController.stream;
  Map<String, NetworkRequestStatus> get currentRequests => Map.unmodifiable(_activeRequests);

  /// Start a new network request
  void startRequest(String method, String url, {String? tag, Map<String, dynamic>? requestData}) {
    final key = '$method:$url';
    final requestStatus = NetworkRequestStatus(
      key: key,
      method: method,
      url: url,
      status: NetworkStatus.pending,
      startTime: DateTime.now(),
      tag: tag,
      requestData: requestData,
    );
    
    _activeRequests[key] = requestStatus;
    _notifyListeners();
    
    // Also add to regular logs
    DebugBus.instance.addLog(LogEvent(
      DateTime.now(),
      LogLevel.info,
      '🔄 $method $url - PENDING',
      tag ?? 'NETWORK',
    ));
  }

  /// Complete a network request with success
  void completeRequest(String method, String url, int statusCode, {Map<String, dynamic>? responseData}) {
    final key = '$method:$url';
    final existing = _activeRequests[key];
    if (existing == null) return;

    final duration = DateTime.now().difference(existing.startTime);
    final updatedStatus = existing.copyWith(
      status: statusCode >= 200 && statusCode < 300 ? NetworkStatus.success : NetworkStatus.error,
      statusCode: statusCode,
      endTime: DateTime.now(),
      duration: duration,
      responseData: responseData,
    );
    
    _activeRequests[key] = updatedStatus;
    _notifyListeners();
    
    // Update the log entry
    final statusIcon = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    DebugBus.instance.addLog(LogEvent(
      DateTime.now(),
      statusCode >= 200 && statusCode < 300 ? LogLevel.info : LogLevel.error,
      '$statusIcon $method $url - ${statusCode >= 200 && statusCode < 300 ? 'SUCCESS' : 'ERROR'} $statusCode (${duration.inMilliseconds}ms)',
      existing.tag ?? 'NETWORK',
    ));
  }

  /// Fail a network request with error
  void failRequest(String method, String url, String error, {int? statusCode}) {
    final key = '$method:$url';
    final existing = _activeRequests[key];
    if (existing == null) return;

    final duration = DateTime.now().difference(existing.startTime);
    final updatedStatus = existing.copyWith(
      status: NetworkStatus.error,
      statusCode: statusCode,
      endTime: DateTime.now(),
      duration: duration,
      error: error,
    );
    
    _activeRequests[key] = updatedStatus;
    _notifyListeners();
    
    // Update the log entry
    DebugBus.instance.addLog(LogEvent(
      DateTime.now(),
      LogLevel.error,
      '❌ $method $url - ERROR${statusCode != null ? ' $statusCode' : ''} (${duration.inMilliseconds}ms) - $error',
      existing.tag ?? 'NETWORK',
    ));
  }

  /// Clear completed requests (optional cleanup)
  void clearCompleted() {
    _activeRequests.removeWhere((key, request) => 
        request.status == NetworkStatus.success || request.status == NetworkStatus.error);
    _notifyListeners();
  }

  void _notifyListeners() {
    _streamController.add(currentRequests);
  }

  void dispose() {
    _streamController.close();
  }
}

/// Status of a network request
class NetworkRequestStatus {
  final String key;
  final String method;
  final String url;
  final NetworkStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final int? statusCode;
  final String? error;
  final String? tag;
  final Map<String, dynamic>? requestData;
  final Map<String, dynamic>? responseData;

  const NetworkRequestStatus({
    required this.key,
    required this.method,
    required this.url,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
    this.statusCode,
    this.error,
    this.tag,
    this.requestData,
    this.responseData,
  });

  NetworkRequestStatus copyWith({
    NetworkStatus? status,
    DateTime? endTime,
    Duration? duration,
    int? statusCode,
    String? error,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) {
    return NetworkRequestStatus(
      key: key,
      method: method,
      url: url,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      statusCode: statusCode ?? this.statusCode,
      error: error ?? this.error,
      tag: tag,
      requestData: requestData ?? this.requestData,
      responseData: responseData ?? this.responseData,
    );
  }

  /// Get display string for this request
  String get displayText {
    String statusIcon;
    switch (status) {
      case NetworkStatus.pending:
        statusIcon = '🔄';
        break;
      case NetworkStatus.success:
        statusIcon = '✅';
        break;
      case NetworkStatus.error:
        statusIcon = '❌';
        break;
    }
    
    String statusText;
    switch (status) {
      case NetworkStatus.pending:
        statusText = 'PENDING';
        break;
      case NetworkStatus.success:
        statusText = 'SUCCESS${statusCode != null ? ' $statusCode' : ''}';
        break;
      case NetworkStatus.error:
        statusText = 'ERROR${statusCode != null ? ' $statusCode' : ''}';
        break;
    }
    
    final timeText = duration != null ? ' (${duration!.inMilliseconds}ms)' : '';
    
    return '$statusIcon $method $url - $statusText$timeText';
  }

  /// Get color for status
  Color get statusColor {
    switch (status) {
      case NetworkStatus.pending:
        return Colors.amber[600]!;
      case NetworkStatus.success:
        return Colors.green[600]!;
      case NetworkStatus.error:
        return Colors.red[600]!;
    }
  }
}

enum NetworkStatus { pending, success, error }
