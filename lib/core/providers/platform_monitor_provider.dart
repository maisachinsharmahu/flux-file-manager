import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogEntry {
  final String timestamp;
  final String channel;
  final String status; // 'SUCCESS', 'PENDING', 'ERROR'
  final String details;

  LogEntry({
    required this.timestamp,
    required this.channel,
    required this.status,
    required this.details,
  });
}

class PlatformMonitorState {
  final Map<String, String> channelStatuses;
  final List<LogEntry> logs;

  PlatformMonitorState({
    required this.channelStatuses,
    required this.logs,
  });

  PlatformMonitorState copyWith({
    Map<String, String>? channelStatuses,
    List<LogEntry>? logs,
  }) {
    return PlatformMonitorState(
      channelStatuses: channelStatuses ?? this.channelStatuses,
      logs: logs ?? this.logs,
    );
  }
}

class PlatformMonitorNotifier extends StateNotifier<PlatformMonitorState> {
  PlatformMonitorNotifier()
      : super(PlatformMonitorState(
          channelStatuses: {
            'initializeIndex': 'PENDING',
            'getAllFiles': 'PENDING',
            'getStorageStatistics': 'PENDING',
            'searchStream': 'READY',
            'executeBatchDelete': 'READY',
            'restoreTombstones': 'READY',
            'getAppStorageUsage': 'PENDING',
          },
          logs: [],
        )) {
    logAction('initializeIndex', 'PENDING', 'Starting native composite indices...');
  }

  void logAction(String channel, String status, String details) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${(now.millisecond / 10).round().toString().padLeft(2, '0')}';

    final updatedStatuses = Map<String, String>.from(state.channelStatuses);
    updatedStatuses[channel] = status;

    final updatedLogs = List<LogEntry>.from(state.logs);
    updatedLogs.insert(
      0,
      LogEntry(
        timestamp: timeStr,
        channel: channel,
        status: status,
        details: details,
      ),
    );

    Future.microtask(() {
      state = PlatformMonitorState(
        channelStatuses: updatedStatuses,
        logs: updatedLogs,
      );
    });
  }
}

final platformMonitorProvider =
    StateNotifierProvider<PlatformMonitorNotifier, PlatformMonitorState>((ref) {
  return PlatformMonitorNotifier();
});
 