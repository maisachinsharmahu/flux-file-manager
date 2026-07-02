import 'package:flutter/services.dart';

class FluxBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.flux.channel/methods');
  static const EventChannel _searchChannel = EventChannel('com.flux.channel/search_stream');

  static Future<bool> initializeIndex({bool force = false}) async {
    try {
      final bool result = await _methodChannel.invokeMethod('initializeIndex', {'force': force});
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: initializeIndex() -> $e');
      return false;
    }
  }

  static Future<bool> requestUsageStatsPermission() async {
    try {
      final bool result = await _methodChannel.invokeMethod('requestUsageStatsPermission');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: requestUsageStatsPermission() -> $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAllFiles() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getAllFiles');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: getAllFiles() -> $e');
      return [];
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
      print('[FluxBridge] Error: getDirectoryContents(parentPath: "$parentPath") -> $e');
      return [];
    }
  }

  static Future<bool> executeBatchDelete(List<int> fids) async {
    try {
      final bool result = await _methodChannel.invokeMethod(
        'executeBatchDelete',
        {'fids': fids},
      );
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: executeBatchDelete(fids: $fids) -> $e');
      return false;
    }
  }
  static Future<bool> shareFiles(List<String> paths) async {
    try {
      final bool result = await _methodChannel.invokeMethod(
        'shareFiles',
        {'paths': paths},
      );
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: shareFiles(paths: $paths) -> $e');
      return false;
    }
  }
  static Future<bool> restoreTombstones(List<int> fids) async {
    try {
      final bool result = await _methodChannel.invokeMethod(
        'restoreTombstones',
        {'fids': fids},
      );
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: restoreTombstones(fids: $fids) -> $e');
      return false;
    }
  }

  static Future<List<dynamic>> getTombstones() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getTombstones');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: getTombstones() -> $e');
      return [];
    }
  }

  static Future<bool> deletePermanently(List<int> fids) async {
    try {
      final bool result = await _methodChannel.invokeMethod(
        'deletePermanently',
        {'fids': fids},
      );
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: deletePermanently(fids: $fids) -> $e');
      return false;
    }
  }

  static Future<Map<dynamic, dynamic>> getStorageStatistics() async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod('getStorageStatistics');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: getStorageStatistics() -> $e');
      return {};
    }
  }

  static Future<List<dynamic>> getAppStorageUsage() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getAppStorageUsage');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: getAppStorageUsage() -> $e');
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
      print('[FluxBridge] Error: searchAndFilter(query: "$query") -> $e');
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
      print('[FluxBridge] Error: generateTestFiles() -> $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getFileGenerationStatus() async {
    try {
      final Map<dynamic, dynamic> res = await _methodChannel.invokeMethod('getFileGenerationStatus');
      return Map<String, dynamic>.from(res);
    } catch (e) {
      print('[FluxBridge] Error: getFileGenerationStatus() -> $e');
      return {'isGenerating': false, 'progressPercent': 0, 'filesCreated': 0, 'totalCount': 1000000};
    }
  }

  static Future<bool> cancelFileGeneration() async {
    try {
      final bool result = await _methodChannel.invokeMethod('cancelFileGeneration');
      return result;
    } catch (e) {
      print('[FluxBridge] Error: cancelFileGeneration() -> $e');
      return false;
    }
  }

  static Future<int> clearTestFiles() async {
    try {
      print('[FluxBridge] Request: clearTestFiles()');
      final int result = await _methodChannel.invokeMethod('clearTestFiles');
      print('[FluxBridge] Response: clearTestFiles() -> Deleted $result test files');
      return result;
    } catch (e) {
      print('[FluxBridge] Error: clearTestFiles() -> $e');
      return 0;
    }
  }
}
