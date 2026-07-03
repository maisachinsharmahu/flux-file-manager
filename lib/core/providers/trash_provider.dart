import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bridge/flux_bridge.dart';
import 'file_filter_provider.dart';
import 'platform_monitor_provider.dart';

class TrashNotifier extends StateNotifier<List<TrashFluxFile>> {
  final Ref ref;

  TrashNotifier(this.ref) : super([]) {
    refreshTrash();
  }

  Future<void> refreshTrash() async {
    ref.read(platformMonitorProvider.notifier).logAction(
      'getTombstones',
      'PENDING',
      'Querying logically deleted tombstone records...',
    );
    final rawFiles = await FluxBridge.getTombstones();
    ref.read(platformMonitorProvider.notifier).logAction(
      'getTombstones',
      'SUCCESS',
      'Retrieved ${rawFiles.length} tombstone records.',
    );

    state = rawFiles.map((f) {
      final map = f as Map<dynamic, dynamic>;
      final isDuplicate = map['isDuplicate'] as bool? ?? false;
      final isVault = map['isVault'] as bool? ?? false;
      final category = map['category'] as String? ?? 'Others';

      Color themeColor;
      if (category == 'Photos') themeColor = const Color(0xFFFFD020);
      else if (category == 'Videos') themeColor = const Color(0xFFFF9010);
      else if (category == 'Audio') themeColor = const Color(0xFF4A90E2);
      else if (category == 'Documents') themeColor = const Color(0xFF7ED321);
      else if (category == 'Application') themeColor = const Color(0xFF9013FE);
      else themeColor = const Color(0xFF9E9E9E);

      // Parse modifiedDate safely
      final rawTime = map['modifiedDate'] as int? ?? 0;
      final modDate = DateTime.fromMillisecondsSinceEpoch(rawTime);

      // Extract raw fid safely
      final fid = (map['fid'] as num? ?? 0).toInt();

      return TrashFluxFile(
        fid: fid,
        name: map['name'] as String? ?? '',
        path: map['path'] as String? ?? '',
        category: category,
        sizeString: map['sizeString'] as String? ?? '0 B',
        sizeInMb: (map['sizeInMb'] as num? ?? 0.0).toDouble(),
        modifiedDate: modDate,
        isDuplicate: isDuplicate,
        isVault: isVault,
        location: map['location'] as String? ?? 'Local',
        themeColor: themeColor,
      );
    }).toList();
  }

  Future<bool> restoreFiles(List<int> fids, {void Function(double)? onProgress}) async {
    ref.read(platformMonitorProvider.notifier).logAction(
      'restoreTombstones',
      'PENDING',
      'Restoring ${fids.length} files from trash...',
    );
    final success = onProgress != null
        ? await FluxBridge.restoreTombstonesWithProgress(fids, onProgress)
        : await FluxBridge.restoreTombstones(fids);
    if (success) {
      ref.read(platformMonitorProvider.notifier).logAction(
        'restoreTombstones',
        'SUCCESS',
        'Successfully restored ${fids.length} files.',
      );
      await refreshTrash();
      await ref.read(allFilesProvider.notifier).refreshFiles();
    } else {
      ref.read(platformMonitorProvider.notifier).logAction(
        'restoreTombstones',
        'ERROR',
        'Failed to restore files.',
      );
    }
    return success;
  }

  Future<bool> deletePermanently(List<int> fids, {void Function(double)? onProgress}) async {
    ref.read(platformMonitorProvider.notifier).logAction(
      'deletePermanently',
      'PENDING',
      'Permanently deleting ${fids.length} files from disk...',
    );
    final success = onProgress != null
        ? await FluxBridge.deletePermanentlyWithProgress(fids, onProgress)
        : await FluxBridge.deletePermanently(fids);
    if (success) {
      ref.read(platformMonitorProvider.notifier).logAction(
        'deletePermanently',
        'SUCCESS',
        'Successfully erased ${fids.length} files.',
      );
      await refreshTrash();
    } else {
      ref.read(platformMonitorProvider.notifier).logAction(
        'deletePermanently',
        'ERROR',
        'Failed to permanently delete files.',
      );
    }
    return success;
  }
}

class TrashFluxFile extends FluxFile {
  final int fid;
  TrashFluxFile({
    required this.fid,
    required String name,
    required String path,
    required String category,
    required String sizeString,
    required double sizeInMb,
    required DateTime modifiedDate,
    required bool isDuplicate,
    required bool isVault,
    required String location,
    required Color themeColor,
  }) : super(
          name: name,
          path: path,
          category: category,
          sizeString: sizeString,
          sizeInMb: sizeInMb,
          modifiedDate: modifiedDate,
          isDuplicate: isDuplicate,
          isVault: isVault,
          location: location,
          themeColor: themeColor,
        );
}

final trashProvider = StateNotifierProvider<TrashNotifier, List<TrashFluxFile>>((ref) {
  return TrashNotifier(ref);
});
