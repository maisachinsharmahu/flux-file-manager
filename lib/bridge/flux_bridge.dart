import 'package:flutter/services.dart';

class FluxBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.flux.channel/methods');
  static const EventChannel _searchChannel = EventChannel('com.flux.channel/search_stream');

  static Future<bool> initializeIndex() async {
    try {
      print('[FluxBridge] Request: initializeIndex()');
      final bool result = await _methodChannel.invokeMethod('initializeIndex');
      print('[FluxBridge] Response: initializeIndex() -> $result');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: initializeIndex() -> $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAllFiles() async {
    try {
      print('[FluxBridge] Request: getAllFiles()');
      final List<dynamic> result = await _methodChannel.invokeMethod('getAllFiles');
      print('[FluxBridge] Response: getAllFiles() -> ${result.length} entries');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: getAllFiles() -> $e');
      return [];
    }
  }

  static Future<List<dynamic>> getDirectoryContents(String parentPath) async {
    try {
      print('[FluxBridge] Request: getDirectoryContents(parentPath: "$parentPath")');
      final List<dynamic> result = await _methodChannel.invokeMethod(
        'getDirectoryContents',
        {'parentPath': parentPath},
      );
      print('[FluxBridge] Response: getDirectoryContents(parentPath: "$parentPath") -> ${result.length} entries');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: getDirectoryContents(parentPath: "$parentPath") -> $e');
      return [];
    }
  }

  static Future<bool> executeBatchDelete(List<int> fids) async {
    try {
      print('[FluxBridge] Request: executeBatchDelete(fids: $fids)');
      final bool result = await _methodChannel.invokeMethod(
        'executeBatchDelete',
        {'fids': fids},
      );
      print('[FluxBridge] Response: executeBatchDelete(fids: $fids) -> $result');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: executeBatchDelete(fids: $fids) -> $e');
      return false;
    }
  }

  static Future<bool> restoreTombstones(List<int> fids) async {
    try {
      print('[FluxBridge] Request: restoreTombstones(fids: $fids)');
      final bool result = await _methodChannel.invokeMethod(
        'restoreTombstones',
        {'fids': fids},
      );
      print('[FluxBridge] Response: restoreTombstones(fids: $fids) -> $result');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: restoreTombstones(fids: $fids) -> $e');
      return false;
    }
  }

  static Future<Map<dynamic, dynamic>> getStorageStatistics() async {
    try {
      print('[FluxBridge] Request: getStorageStatistics()');
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod('getStorageStatistics');
      print('[FluxBridge] Response: getStorageStatistics() -> $result');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: getStorageStatistics() -> $e');
      return {};
    }
  }

  static Future<List<dynamic>> getAppStorageUsage() async {
    try {
      print('[FluxBridge] Request: getAppStorageUsage()');
      final List<dynamic> result = await _methodChannel.invokeMethod('getAppStorageUsage');
      print('[FluxBridge] Response: getAppStorageUsage() -> ${result.length} entries');
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
      print('[FluxBridge] Request: searchAndFilter(query: "$query", categories: $categories, sizeRange: "$sizeRange", dateRange: "$dateRange")');
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
      print('[FluxBridge] Response: searchAndFilter(query: "$query") -> ${result.length} files');
      return result;
    } on PlatformException catch (e) {
      print('[FluxBridge] Error: searchAndFilter(query: "$query") -> $e');
      return [];
    }
  }

  static Stream<dynamic> searchStream(String query, int limit) {
    print('[FluxBridge] Request Stream: searchStream(query: "$query")');
    return _searchChannel.receiveBroadcastStream({
      'query': query,
      'limit': limit,
    });
  }
}
