import 'package:flutter/material.dart';
import '../../network_request_manager.dart';

/// Shared widget for displaying network requests in both Logs and Network tabs
class NetworkRequestWidget extends StatelessWidget {
  final NetworkRequestStatus request;
  final bool showDetails;
  final VoidCallback? onTap;

  const NetworkRequestWidget({
    super.key,
    required this.request,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow(),
              if (showDetails) ...[
                const SizedBox(height: 8),
                _buildDetailsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        // Status indicator with animation
        SizedBox(
          width: 24,
          height: 24,
          child: _buildStatusIndicator(),
        ),
        const SizedBox(width: 12),
        // Method badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getMethodColor(),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            request.method,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // URL and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.url,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  color: request.statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Time/Duration
        if (request.duration != null || request.status == NetworkStatus.pending)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              request.duration != null 
                ? '${request.duration!.inMilliseconds}ms'
                : 'pending...',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    if (request.status == NetworkStatus.pending) {
      return const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
      );
    } else if (request.status == NetworkStatus.success) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 20,
      );
    } else {
      return const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 20,
      );
    }
  }

  Color _getMethodColor() {
    switch (request.method.toUpperCase()) {
      case 'GET':
        return Colors.blue[600]!;
      case 'POST':
        return Colors.green[600]!;
      case 'PUT':
        return Colors.orange[600]!;
      case 'DELETE':
        return Colors.red[600]!;
      case 'PATCH':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getStatusText() {
    if (request.status == NetworkStatus.pending) {
      return 'PENDING';
    } else if (request.status == NetworkStatus.success) {
      return 'SUCCESS${request.statusCode != null ? ' ${request.statusCode}' : ''}';
    } else {
      return 'ERROR${request.statusCode != null ? ' ${request.statusCode}' : ''}';
    }
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (request.requestData != null) ...[
          const Text('Request:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              request.requestData.toString(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ),
        ],
        if (request.responseData != null) ...[
          const SizedBox(height: 8),
          const Text('Response:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              request.responseData.toString(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ),
        ],
        if (request.error != null) ...[
          const SizedBox(height: 8),
          const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[900]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              request.error!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
