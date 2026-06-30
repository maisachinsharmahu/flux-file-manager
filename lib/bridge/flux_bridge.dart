import 'package:flutter/services.dart';

class FluxBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.flux.channel/methods');
  static const EventChannel _searchChannel = EventChannel('com.flux.channel/search_stream');

  static Future<bool> initializeIndex() async {
    try {
      final bool result = await _methodChannel.invokeMethod('initializeIndex');
      return result;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getAllFiles() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getAllFiles');
      return result;
    } on PlatformException catch (_) {
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
    } on PlatformException catch (_) {
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
    } on PlatformException catch (_) {
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
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<Map<dynamic, dynamic>> getStorageStatistics() async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod('getStorageStatistics');
      return result;
    } on PlatformException catch (_) {
      return {};
    }
  }

  static Future<List<dynamic>> getAppStorageUsage() async {
    try {
      final List<dynamic> result = await _methodChannel.invokeMethod('getAppStorageUsage');
      return result;
    } on PlatformException catch (_) {
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
    } on PlatformException catch (_) {
      return [];
    }
  }

  static Stream<dynamic> searchStream(String query, int limit) {
    return _searchChannel.receiveBroadcastStream({
      'query': query,
      'limit': limit,
    });
  }
}
