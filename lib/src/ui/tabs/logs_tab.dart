import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../event_bus.dart';
import '../../models.dart';
import '../../network_request_manager.dart';
import '../shared/network_request_widget.dart';

class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  final List<LogEvent> _items = <LogEvent>[];
  final Map<String, NetworkRequestStatus> _networkRequests = {};
  final TextEditingController _search = TextEditingController();
  LogLevel? _levelFilter;
  StreamSubscription<LogEvent>? _sub;
  StreamSubscription<Map<String, NetworkRequestStatus>>? _networkSub;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _items.addAll(DebugBus.instance.logsSnapshot);
    _networkRequests.addAll(NetworkRequestManager.instance.currentRequests);
    
    _sub = DebugBus.instance.logsStream.listen((e) {
      setState(() => _items.add(e));
      if (_autoScroll && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
    
    _networkSub = NetworkRequestManager.instance.requestsStream.listen((requests) {
      setState(() {
        _networkRequests.clear();
        _networkRequests.addAll(requests);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sub?.cancel();
    _networkSub?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter regular logs
    final filteredLogs = _items.where((e) {
      final q = _search.text.trim().toLowerCase();
      final matchesSearch = q.isEmpty || 
          e.message.toLowerCase().contains(q) || 
          (e.tag ?? '').toLowerCase().contains(q);
      final matchesLevel = _levelFilter == null || e.level == _levelFilter;
      return matchesSearch && matchesLevel;
    }).toList();

    // Filter network requests
    final filteredNetworkRequests = _networkRequests.values.where((request) {
      final q = _search.text.trim().toLowerCase();
      final matchesSearch = q.isEmpty || 
          request.method.toLowerCase().contains(q) || 
          request.url.toLowerCase().contains(q);
      return matchesSearch;
    }).toList();

    // Combine and sort by time
    final allItems = <Object>[];
    allItems.addAll(filteredLogs);
    allItems.addAll(filteredNetworkRequests);
    
    // Sort by timestamp (logs have ts, network requests have startTime)
    allItems.sort((a, b) {
      DateTime timeA;
      DateTime timeB;
      
      if (a is LogEvent) {
        timeA = a.ts;
      } else {
        timeA = (a as NetworkRequestStatus).startTime;
      }
      
      if (b is LogEvent) {
        timeB = b.ts;
      } else {
        timeB = (b as NetworkRequestStatus).startTime;
      }
      
      return timeA.compareTo(timeB);
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[900]!, Colors.grey[850]!],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[700],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildLevelChip('All', _levelFilter == null, () => setState(() => _levelFilter = null)),
                    _buildLevelChip('Debug', _levelFilter == LogLevel.debug, () => setState(() => _levelFilter = LogLevel.debug)),
                    _buildLevelChip('Info', _levelFilter == LogLevel.info, () => setState(() => _levelFilter = LogLevel.info)),
                    _buildLevelChip('Warning', _levelFilter == LogLevel.warn, () => setState(() => _levelFilter = LogLevel.warn)),
                    _buildLevelChip('Error', _levelFilter == LogLevel.error, () => setState(() => _levelFilter = LogLevel.error)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: allItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No logs available',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      
                      // Check if this is a network request
                      if (item is NetworkRequestStatus) {
                        return NetworkRequestWidget(
                          request: item,
                          onTap: () {
                            // Can show expanded details in a dialog
                          },
                        );
                      }
                      
                      // Otherwise it's a regular log event
                      final event = item as LogEvent;
                      final isError = event.level == LogLevel.error;
                      final isWarning = event.level == LogLevel.warn;
                      
                      Color levelColor = Colors.grey;
                      if (isError) levelColor = Colors.red;
                      else if (isWarning) levelColor = Colors.orange;
                      else if (event.level == LogLevel.info) levelColor = Colors.blue;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        color: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: levelColor.withOpacity(0.3), width: 1),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: levelColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isError ? Icons.error_outline : 
                              isWarning ? Icons.warning_amber_outlined : 
                              Icons.info_outline,
                              color: levelColor,
                              size: 18,
                            ),
                          ),
                          title: Row(
                            children: [
                              if (event.tag != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[700],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event.tag!,
                                    style: TextStyle(color: Colors.grey[300], fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  event.message.split('\n').first,
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            _formatTimestamp(event.ts),
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey[850]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Enhanced Copy Row
                                  _buildLogCopyRow(event),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: SelectableText(
                                      event.message,
                                      style: TextStyle(
                                        color: Colors.grey[200],
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChip(String label, bool selected, VoidCallback onTap) {
    Color color = _getLevelColor(label);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: selected ? color : Colors.grey[600]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[300],
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'debug': return Colors.blue;
      case 'info': return Colors.green;
      case 'warning': return Colors.orange;
      case 'error': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime ts) {
    final timeString = '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';
    return timeString;
  }

  Widget _buildLogCopyRow(LogEvent event) {
    Color levelColor;
    switch (event.level) {
      case LogLevel.error:
        levelColor = Colors.red[300]!;
        break;
      case LogLevel.warn:
        levelColor = Colors.yellow[600]!;
        break;
      case LogLevel.info:
        levelColor = Colors.blue[300]!;
        break;
      case LogLevel.debug:
        levelColor = Colors.grey[400]!;
        break;
    }

    return Column(
      children: [
        // Level and timestamp info
        Row(
          children: [
            Text(
              'Level: ${event.level.name.toUpperCase()}',
              style: TextStyle(color: levelColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              _formatTimestamp(event.ts),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Copy buttons row
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            // Copy log message only
            ElevatedButton.icon(
              onPressed: () => _copyToClipboard(event.message, 'Log message'),
              icon: Icon(Icons.copy, size: 14),
              label: Text('Copy Message', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size(0, 32),
              ),
            ),
            
            // Copy full log details (with timestamp, level, tag)
            ElevatedButton.icon(
              onPressed: () => _copyFullLogDetails(event),
              icon: Icon(Icons.info_outline, size: 14),
              label: Text('Copy Full', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size(0, 32),
              ),
            ),
            
            // Copy as formatted text for sharing
            if (event.tag != null)
              ElevatedButton.icon(
                onPressed: () => _copyFormattedLog(event),
                icon: Icon(Icons.share, size: 14),
                label: Text('Share Format', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size(0, 32),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _copyFullLogDetails(LogEvent event) {
    StringBuffer fullLog = StringBuffer();
    
    fullLog.writeln('Timestamp: ${event.ts.toIso8601String()}');
    fullLog.writeln('Level: ${event.level.name.toUpperCase()}');
    
    if (event.tag != null && event.tag!.isNotEmpty) {
      fullLog.writeln('Tag: ${event.tag}');
    }
    
    fullLog.writeln('Message:');
    fullLog.write(event.message);
    
    _copyToClipboard(fullLog.toString(), 'Full log details');
  }

  void _copyFormattedLog(LogEvent event) {
    final timestamp = _formatTimestamp(event.ts);
    final level = event.level.name.toUpperCase();
    final tag = event.tag ?? 'LOG';
    
    final formatted = '[$timestamp] [$level] [$tag] ${event.message}';
    _copyToClipboard(formatted, 'Formatted log');
  }

  void _copyToClipboard(String text, [String? label]) {
    if (text.trim().isEmpty) {
      _showSnackBar('Nothing to copy', isError: true);
      return;
    }
    
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      _showSnackBar('${label ?? 'Content'} copied to clipboard');
    }).catchError((error) {
      _showSnackBar('Failed to copy to clipboard', isError: true);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
