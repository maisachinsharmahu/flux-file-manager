import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FluxBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.flux.channel/methods');
  static const EventChannel _searchChannel = EventChannel('com.flux.channel/search_stream');
  // Kotlin pushes copy progress (0.0→1.0) via invokeMethod('onProgress', value).
  static const MethodChannel _copyProgressChannel = MethodChannel('com.flux.channel/copy_progress');

  static final _indexChangeController = StreamController<void>.broadcast();
  static Stream<void> get onIndexChanged => _indexChangeController.stream;

  static void initializeMethodCallHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onIndexChanged') {
        _indexChangeController.add(null);
      }
    });
  }

  static Future<bool> initializeIndex({bool force = false}) async {
    try {
      final bool result = await _methodChannel.invokeMethod('initializeIndex', {'force': force});
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: initializeIndex() -> $e');
      return false;
    }
  }

  static Future<bool> requestUsageStatsPermission() async {
    try {
      final bool result = await _methodChannel.invokeMethod('requestUsageStatsPermission');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: requestUsageStatsPermission() -> $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAllFiles() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getAllFiles');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: getAllFiles() -> $e');
      return [];
    }
  }

  static Future<int> getFileCount() async {
    try {
      final int result = await _methodChannel.invokeMethod('getFileCount');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: getFileCount() -> $e');
      return 0;
    }
  }

  static Future<List<dynamic>> getDirectoryContents(String parentPath) async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod(
        'getDirectoryContents',
        {'parentPath': parentPath},
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: getDirectoryContents(parentPath: "$parentPath") -> $e');
      return [];
    }
  }

  static Future<bool> executeBatchDelete(List<int> fids, {bool recursive = true}) async {
    try {
      final bool result = await _methodChannel.invokeMethod(
        'executeBatchDelete',
        {'fids': fids, 'recursive': recursive},
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: executeBatchDelete(fids: $fids) -> $e');
      return false;
    }
  }

  static Future<bool> executeBatchDeleteWithProgress(
    List<int> fids,
    void Function(double progress) onProgress,
  ) async {
    if (fids.isEmpty) return true;
    final expanded = await expandFolderFids(fids);
    // Logical delete is O(1) per file (just a bitset flip + WAL entry).
    // Large chunks minimize MethodChannel round-trip overhead.
    const chunkSize = 1000;
    var deleted = 0;
    var allSuccess = true;
    for (var i = 0; i < expanded.length; i += chunkSize) {
      final end = (i + chunkSize < expanded.length) ? i + chunkSize : expanded.length;
      final chunk = expanded.sublist(i, end);
      final success = await executeBatchDelete(chunk, recursive: false);
      if (success) {
        deleted += chunk.length;
        onProgress(deleted / expanded.length);
      } else {
        allSuccess = false;
      }
      // Yield one microtask so the UI thread can breathe (no artificial delay).
      await Future.microtask(() {});
    }
    return allSuccess;
  }

  static Future<bool> shareFiles(List<String> paths) async {
    try {
      final bool result = await _methodChannel.invokeMethod(
        'shareFiles',
        {'paths': paths},
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: shareFiles(paths: $paths) -> $e');
      return false;
    }
  }

  static Future<bool> restoreTombstones(List<int> fids, {bool recursive = true}) async {
    try {
      final bool result = await _methodChannel.invokeMethod(
        'restoreTombstones',
        {'fids': fids, 'recursive': recursive},
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: restoreTombstones(fids: $fids) -> $e');
      return false;
    }
  }

  static Future<bool> restoreTombstonesWithProgress(
    List<int> fids,
    void Function(double progress) onProgress,
  ) async {
    if (fids.isEmpty) return true;
    final expanded = await expandFolderFids(fids);
    // Restore is also a bitset clear + WAL write — same O(1) logic.
    const chunkSize = 1000;
    var restored = 0;
    var allSuccess = true;
    for (var i = 0; i < expanded.length; i += chunkSize) {
      final end = (i + chunkSize < expanded.length) ? i + chunkSize : expanded.length;
      final chunk = expanded.sublist(i, end);
      final success = await restoreTombstones(chunk, recursive: false);
      if (success) {
        restored += chunk.length;
        onProgress(restored / expanded.length);
      } else {
        allSuccess = false;
      }
      await Future.microtask(() {});
    }
    return allSuccess;
  }

  static Future<List<dynamic>> getTombstones() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getTombstones');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: getTombstones() -> $e');
      return [];
    }
  }

  static Future<bool> deletePermanently(List<int> fids, {bool recursive = true}) async {
    try {
      final bool result = await _methodChannel.invokeMethod(
        'deletePermanently',
        {'fids': fids, 'recursive': recursive},
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: deletePermanently(fids: $fids) -> $e');
      return false;
    }
  }

  static Future<bool> deletePermanentlyWithProgress(
    List<int> fids,
    void Function(double progress) onProgress,
  ) async {
    if (fids.isEmpty) return true;
    // Expand FIDs so we can drive accurate per-file progress.
    final expanded = await expandFolderFids(fids);

    // ── Phase 1: Logical delete (O(N/64) bitset flip) ─────────────────────────
    // This is the user-perceived operation. Runs in <100ms for 14k files.
    // Chunk size 1000 = ~14 MethodChannel round-trips, no artificial delays.
    const chunkSize = 1000;
    var done = 0;
    var allSuccess = true;
    for (var i = 0; i < expanded.length; i += chunkSize) {
      final end = (i + chunkSize < expanded.length) ? i + chunkSize : expanded.length;
      final chunk = expanded.sublist(i, end);
      final success = await executeBatchDelete(chunk, recursive: false);
      if (success) {
        done += chunk.length;
        onProgress(done / expanded.length);
      } else {
        allSuccess = false;
      }
      await Future.microtask(() {});
    }

    // ── Phase 2: Fire-and-forget physical disk deletion ────────────────────────
    // Returns immediately; actual unlink() calls run on a background thread.
    // Storage space reclaimed transparently while the user continues using the app.
    schedulePhysicalDelete(expanded);

    return allSuccess;
  }

  static Future<void> schedulePhysicalDelete(List<int> fids) async {
    if (fids.isEmpty) return;
    try {
      await _methodChannel.invokeMethod('schedulePhysicalDelete', {'fids': fids});
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: schedulePhysicalDelete() -> $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Copy / Move
  // ─────────────────────────────────────────────────────────────────────────

  /// Moves [fids] into [destinationPath]. O(1) per file (rename syscall).
  /// Returns true immediately once the Kotlin rename + index swap completes.
  static Future<bool> moveFiles(List<int> fids, String destinationPath) async {
    if (fids.isEmpty) return true;
    try {
      final bool result = await _methodChannel.invokeMethod(
        'moveFiles',
        {'fids': fids, 'destinationPath': destinationPath},
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: moveFiles() -> $e');
      return false;
    }
  }

  /// Moves [fids] into [destinationPath] in chunks, streaming progress updates.
  static Future<bool> moveFilesWithProgress(
    List<int> fids,
    String destinationPath,
    void Function(double progress) onProgress,
  ) async {
    if (fids.isEmpty) return true;
    
    // Chunking the FIDs list allows driving smooth UI progress bar updates.
    // 250 items chunk size keeps MethodChannel communication low while giving fast updates.
    const chunkSize = 250;
    var done = 0;
    var allSuccess = true;
    
    for (var i = 0; i < fids.length; i += chunkSize) {
      final end = (i + chunkSize < fids.length) ? i + chunkSize : fids.length;
      final chunk = fids.sublist(i, end);
      final success = await moveFiles(chunk, destinationPath);
      if (success) {
        done += chunk.length;
        onProgress(done / fids.length);
      } else {
        allSuccess = false;
      }
      // Yield to let Flutter update the rendering loop
      await Future.delayed(const Duration(milliseconds: 5));
    }
    return allSuccess;
  }

  /// Copies [fids] into [destinationPath], streaming progress to [onProgress].
  /// Registers a MethodChannel handler on the copy_progress channel so Kotlin
  /// can push 0.0→1.0 values from its IO thread, then awaits the final result.
  static Future<bool> copyFilesWithProgress(
    List<int> fids,
    String destinationPath,
    void Function(double progress) onProgress,
  ) async {
    if (fids.isEmpty) return true;

    // Register progress listener before starting the operation.
    _copyProgressChannel.setMethodCallHandler((call) async {
      if (call.method == 'onProgress') {
        final progress = (call.arguments as num?)?.toDouble() ?? 0.0;
        onProgress(progress.clamp(0.0, 1.0));
      }
    });

    try {
      final bool result = await _methodChannel.invokeMethod(
        'copyFilesWithProgress',
        {'fids': fids, 'destinationPath': destinationPath},
      );
      // Ensure 100% is reported even if last chunk was partial.
      onProgress(1.0);
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: copyFilesWithProgress() -> $e');
      return false;
    } finally {
      _copyProgressChannel.setMethodCallHandler(null);
    }
  }

  static Future<Map<dynamic, dynamic>> getStorageStatistics() async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod('getStorageStatistics');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: getStorageStatistics() -> $e');
      return {};
    }
  }

  static Future<List<dynamic>> getAppStorageUsage() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getAppStorageUsage');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: getAppStorageUsage() -> $e');
      return [];
    }
  }

  static Future<List<dynamic>> searchAndFilter({
    required String query,
    required List<String> categories,
    required String location,
    required bool showVaultOnly,
    required bool showDuplicatesOnly,
    required String sizeRange,
    required String dateRange,
    required String nameSort,
    required String dateSort,
    required String sizeSort,
    required int limit,
  }) async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod(
        'searchAndFilter',
        {
          'query': query,
          'categories': categories,
          'location': location,
          'showVaultOnly': showVaultOnly,
          'showDuplicatesOnly': showDuplicatesOnly,
          'sizeRange': sizeRange,
          'dateRange': dateRange,
          'nameSort': nameSort,
          'dateSort': dateSort,
          'sizeSort': sizeSort,
          'limit': limit,
        },
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: searchAndFilter(query: "$query") -> $e');
      return [];
    }
  }

  static Stream<dynamic> searchStream(String query, int limit) {
    return _searchChannel.receiveBroadcastStream({
      'query': query,
      'limit': limit,
    });
  }

  static Future<bool> generateTestFiles({int count = 1000000, double targetSizeGb = 25.0}) async {
    try {
      final bool result = await _methodChannel.invokeMethod('generateTestFiles', {
        'count': count,
        'targetSizeGb': targetSizeGb,
      });
      return result;
    } catch (e) {
      debugPrint('[FluxBridge] Error: generateTestFiles() -> $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getFileGenerationStatus() async {
    try {
      final Map<dynamic, dynamic> res = await _methodChannel.invokeMethod('getFileGenerationStatus');
      return Map<String, dynamic>.from(res);
    } catch (e) {
      debugPrint('[FluxBridge] Error: getFileGenerationStatus() -> $e');
      return {'isGenerating': false, 'progressPercent': 0, 'filesCreated': 0, 'totalCount': 1000000};
    }
  }

  static Future<bool> cancelFileGeneration() async {
    try {
      final bool result = await _methodChannel.invokeMethod('cancelFileGeneration');
      return result;
    } catch (e) {
      debugPrint('[FluxBridge] Error: cancelFileGeneration() -> $e');
      return false;
    }
  }

  static Future<int> clearTestFiles() async {
    try {
      debugPrint('[FluxBridge] Request: clearTestFiles()');
      final int result = await _methodChannel.invokeMethod('clearTestFiles');
      debugPrint('[FluxBridge] Response: clearTestFiles() -> Deleted $result test files');
      return result;
    } catch (e) {
      debugPrint('[FluxBridge] Error: clearTestFiles() -> $e');
      return 0;
    }
  }

  static Future<bool> createDirectory(String parentPath, String name) async {
    try {
      final bool result = await _methodChannel.invokeMethod('createDirectory', {
        'parentPath': parentPath,
        'name': name,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: createDirectory(parentPath: "$parentPath", name: "$name") -> $e');
      return false;
    }
  }

  static Future<List<int>> getAllDirectoryFids(String parentPath) async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getAllDirectoryFids', {
        'parentPath': parentPath,
      });
      return result.cast<int>();
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: getAllDirectoryFids(parentPath: "$parentPath") -> $e');
      return [];
    }
  }

  static Future<List<int>> expandFolderFids(List<int> fids) async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('expandFolderFids', {
        'fids': fids,
      });
      return result.cast<int>();
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: expandFolderFids(fids: $fids) -> $e');
      return fids; // Fallback to original FIDs if method fails
    }
  }

  static Future<int> getTotalBytes(List<int> fids) async {
    try {
      final int result = await _methodChannel.invokeMethod('getTotalBytes', {
        'fids': fids,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('[FluxBridge] Error: getTotalBytes(fids: $fids) -> $e');
      return 0;
    }
  }
}

