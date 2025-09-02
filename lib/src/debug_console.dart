
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'event_bus.dart';
import 'models.dart';
import 'ui/bubble.dart';
import 'ui/panel.dart';
import 'network_request_manager.dart';

enum DebugTab { logs, network }

class DebugConsoleOverlay extends StatefulWidget {
  const DebugConsoleOverlay({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
    this.showBubble = true,
    this.initialTab = DebugTab.logs,
    this.panelHeightFraction = 0.6,
    this.showNetworkTab = true,
  });

  final Widget child;
  final bool enabled;
  final bool showBubble;
  final DebugTab initialTab;
  final double panelHeightFraction;
  final bool showNetworkTab;

  static void log(String msg, {LogLevel level = LogLevel.debug, String? tag}) {
    if (!kDebugMode) return;
    DebugBus.instance.addLog(LogEvent(DateTime.now(), level, msg, tag));
  }

  /// Track a network request manually
  static void logNetworkRequest(String method, String url, {String? tag}) {
    if (!kDebugMode) return;
    NetworkRequestManager.instance.startRequest(method, url, tag: tag);
  }

  /// Complete a network request manually
  static void logNetworkResponse(String method, String url, int statusCode, {Map<String, dynamic>? responseData}) {
    if (!kDebugMode) return;
    NetworkRequestManager.instance.completeRequest(method, url, statusCode, responseData: responseData);
  }

  /// Fail a network request manually
  static void logNetworkError(String method, String url, String error, {int? statusCode}) {
    if (!kDebugMode) return;
    NetworkRequestManager.instance.failRequest(method, url, error, statusCode: statusCode);
  }

  /// Optional helper to capture print() while running your app.
  static T runWithPrintCapture<T>(T Function() body) {
    return runZoned<T>(
      body,
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          if (kDebugMode) {
            try {
              DebugBus.instance.addLog(LogEvent(DateTime.now(), LogLevel.debug, line));
            } catch (_) {}
          }
          parent.print(zone, line);
        },
      ),
    );
  }

  @override
  State<DebugConsoleOverlay> createState() => _DebugConsoleOverlayState();
}

class _DebugConsoleOverlayState extends State<DebugConsoleOverlay> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      // Capture framework errors
      final prev = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        DebugConsoleOverlay.log(details.exceptionAsString(), level: LogLevel.error, tag: 'FlutterError');
        prev?.call(details);
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      alignment: Alignment.topLeft, // Explicit alignment instead of directional
      children: [
        widget.child,
        if (widget.showBubble)
          DebugBubble(
            onTap: () => setState(() => _open = true),
          ),
        if (_open)
          _BottomSheetPanel(
            onClose: () => setState(() => _open = false),
            heightFraction: widget.panelHeightFraction,
            showNetworkTab: widget.showNetworkTab,
          ),
      ],
    );
  }
}

class _BottomSheetPanel extends StatelessWidget {
  const _BottomSheetPanel({
    required this.onClose, 
    required this.heightFraction,
    required this.showNetworkTab,
  });

  final VoidCallback onClose;
  final double heightFraction;
  final bool showNetworkTab;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final h = media.size.height * heightFraction;
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: h,
          width: media.size.width,
          child: DebugPanel(
            onClose: onClose,
            showNetworkTab: showNetworkTab,
          ),
        ),
      ),
    );
  }
}
