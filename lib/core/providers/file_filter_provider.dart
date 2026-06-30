import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/flux_icon.dart';
import '../../bridge/flux_bridge.dart';
import 'platform_monitor_provider.dart';

class FluxFile {
  final String name;
  final String path;
  final String
  category; // 'Photos', 'Videos', 'Documents', 'Audio', 'Application', 'Others'
  final String sizeString;
  final double sizeInMb;
  final DateTime modifiedDate;
  final bool isDuplicate;
  final bool isVault;
  final String location; // 'Local', 'Cloud', 'SD Card'
  final Color themeColor;

  FluxFile({
    required this.name,
    required this.path,
    required this.category,
    required this.sizeString,
    required this.sizeInMb,
    required this.modifiedDate,
    required this.isDuplicate,
    required this.isVault,
    required this.location,
    required this.themeColor,
  });

  IconData get fallbackIcon {
    if (category == 'Photos') return Icons.image_outlined;
    if (category == 'Videos') return Icons.play_circle_outline;
    if (category == 'Documents') return Icons.description_outlined;
    if (category == 'Audio') return Icons.music_note_outlined;
    if (category == 'Application') return Icons.android_outlined;
    return Icons.insert_drive_file_outlined;
  }

  /// The file extension derived from [name], lowercase, without the dot.
  /// e.g.  "report.pdf" → "pdf"
  String get fileExtension {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) {
      // Fallback by category
      if (category == 'Photos') return 'jpg';
      if (category == 'Videos') return 'mp4';
      if (category == 'Audio') return 'mp3';
      if (category == 'Application') return 'apk';
      return 'txt';
    }
    return name.substring(dot + 1).toLowerCase();
  }

  // Keep for backwards-compat with widgets that still use FluxIconType
  FluxIconType? get fluxIcon {
    if (name.endsWith('.pdf')) return FluxIconType.adobeReader;
    if (category == 'Documents') return FluxIconType.documentColor;
    if (category == 'Videos') return FluxIconType.videoFileColor;
    if (category == 'Audio') return FluxIconType.audioColor;
    if (category == 'Photos') return FluxIconType.imageFileColor;
    if (category == 'Application') return FluxIconType.apk;
    return null;
  }
}

class FileFilterState {
  final Set<String> categories;
  final String sizeRange; // 'All', 'Small (<1MB)', 'Medium (1-10MB)', 'Large (10-100MB)', 'Huge (>100MB)'
  final String dateRange; // 'All', 'Today', 'This Week', 'This Month', 'Older'
  final String nameSort; // 'Off', 'Ascending', 'Descending'
  final String dateSort; // 'Off', 'Ascending', 'Descending'
  final String sizeSort; // 'Off', 'Ascending', 'Descending'
  final String location; // 'All', 'Local', 'Cloud', 'SD Card'
  final bool showVaultOnly;
  final bool showDuplicatesOnly;

  FileFilterState({
    required this.categories,
    required this.sizeRange,
    required this.dateRange,
    required this.nameSort,
    required this.dateSort,
    required this.sizeSort,
    required this.location,
    required this.showVaultOnly,
    required this.showDuplicatesOnly,
  });

  FileFilterState copyWith({
    Set<String>? categories,
    String? sizeRange,
    String? dateRange,
    String? nameSort,
    String? dateSort,
    String? sizeSort,
    String? location,
    bool? showVaultOnly,
    bool? showDuplicatesOnly,
  }) {
    return FileFilterState(
      categories: categories ?? this.categories,
      sizeRange: sizeRange ?? this.sizeRange,
      dateRange: dateRange ?? this.dateRange,
      nameSort: nameSort ?? this.nameSort,
      dateSort: dateSort ?? this.dateSort,
      sizeSort: sizeSort ?? this.sizeSort,
      location: location ?? this.location,
      showVaultOnly: showVaultOnly ?? this.showVaultOnly,
      showDuplicatesOnly: showDuplicatesOnly ?? this.showDuplicatesOnly,
    );
  }

  int get activeFiltersCount {
    int count = 0;
    if (categories.isNotEmpty) count += 1;
    if (sizeRange != 'All') count += 1;
    if (dateRange != 'All') count += 1;
    if (location != 'All') count += 1;
    if (showVaultOnly) count += 1;
    if (showDuplicatesOnly) count += 1;
    if (nameSort != 'Off') count += 1;
    if (dateSort != 'Off') count += 1;
    if (sizeSort != 'Off') count += 1;
    return count;
  }
}

// Default filter state notifier
class FileFilterNotifier extends StateNotifier<FileFilterState> {
  FileFilterNotifier()
      : super(
          FileFilterState(
            categories: {},
            sizeRange: 'All',
            dateRange: 'All',
            nameSort: 'Off',
            dateSort: 'Descending', // Default date descending (newest first)
            sizeSort: 'Off',
            location: 'All',
            showVaultOnly: false,
            showDuplicatesOnly: false,
          ),
        );

  void toggleCategory(String category) {
    final updated = Set<String>.from(state.categories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(categories: updated);
  }

  void setCategories(Set<String> categories) {
    state = state.copyWith(categories: categories);
  }

  void setSizeRange(String range) {
    state = state.copyWith(sizeRange: range);
  }

  void setDateRange(String range) {
    state = state.copyWith(dateRange: range);
  }

  void setNameSort(String sort) {
    state = state.copyWith(nameSort: sort);
  }

  void setDateSort(String sort) {
    state = state.copyWith(dateSort: sort);
  }

  void setSizeSort(String sort) {
    state = state.copyWith(sizeSort: sort);
  }

  void setLocation(String loc) {
    state = state.copyWith(location: loc);
  }

  void toggleVault(bool value) {
    state = state.copyWith(showVaultOnly: value);
  }

  void toggleDuplicates(bool value) {
    state = state.copyWith(showDuplicatesOnly: value);
  }

  void reset() {
    state = FileFilterState(
      categories: {},
      sizeRange: 'All',
      dateRange: 'All',
      nameSort: 'Off',
      dateSort: 'Descending',
      sizeSort: 'Off',
      location: 'All',
      showVaultOnly: false,
      showDuplicatesOnly: false,
    );
  }
}

final fileFilterProvider =
    StateNotifierProvider<FileFilterNotifier, FileFilterState>((ref) {
      return FileFilterNotifier();
    });

class AllFilesNotifier extends StateNotifier<List<FluxFile>> {
  final Ref ref;

  AllFilesNotifier(this.ref) : super([]) {
    initAndLoad();
  }

  Future<void> initAndLoad() async {
    ref.read(platformMonitorProvider.notifier).logAction(
      'initializeIndex',
      'PENDING',
      'Scanning device storage and pre-seeding mockup files...',
    );
    final ok = await FluxBridge.initializeIndex();
    if (ok) {
      ref.read(platformMonitorProvider.notifier).logAction(
        'initializeIndex',
        'SUCCESS',
        '9 composite indexes fully initialized and WAL parsed.',
      );
    } else {
      ref.read(platformMonitorProvider.notifier).logAction(
        'initializeIndex',
        'ERROR',
        'Failed to initialize native indexing engine.',
      );
    }
    await refreshFiles();
  }

  Future<void> refreshFiles() async {
    ref.read(platformMonitorProvider.notifier).logAction(
      'getAllFiles',
      'PENDING',
      'Querying file records from native O(1) master array...',
    );
    final rawFiles = await FluxBridge.getAllFiles();
    ref.read(platformMonitorProvider.notifier).logAction(
      'getAllFiles',
      'SUCCESS',
      'Retrieved ${rawFiles.length} file records from native master array.',
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

      return FluxFile(
        name: map['name'] as String? ?? '',
        path: map['path'] as String? ?? '',
        category: category,
        sizeString: map['sizeString'] as String? ?? '0 B',
        sizeInMb: (map['sizeInMb'] as num? ?? 0.0).toDouble(),
        modifiedDate: DateTime.fromMillisecondsSinceEpoch(map['modifiedDate'] as int? ?? 0),
        isDuplicate: isDuplicate,
        isVault: isVault,
        location: map['location'] as String? ?? 'Local',
        themeColor: themeColor,
      );
    }).toList();
  }
}

// All files source database provider
final allFilesProvider = StateNotifierProvider<AllFilesNotifier, List<FluxFile>>((ref) {
  return AllFilesNotifier(ref);
});

// Helper selector to apply both query and active filters to the files database
final filteredFilesProvider = Provider.family<List<FluxFile>, String>((
  ref,
  query,
) {
  final allFiles = ref.watch(allFilesProvider);
  final filter = ref.watch(fileFilterProvider);

  List<FluxFile> list = List.from(allFiles);

  // 1. Text Search Filter
  if (query.isNotEmpty) {
    final lower = query.toLowerCase();
    list = list
        .where((file) => file.name.toLowerCase().contains(lower))
        .toList();
  }

  // 2. Categories Filter
  if (filter.categories.isNotEmpty) {
    list = list
        .where((file) => filter.categories.contains(file.category))
        .toList();
  }

  // 3. Location Filter
  if (filter.location != 'All') {
    list = list.where((file) => file.location == filter.location).toList();
  }

  // 4. Vault Filter
  if (filter.showVaultOnly) {
    list = list.where((file) => file.isVault).toList();
  }

  // 5. Duplicates Filter
  if (filter.showDuplicatesOnly) {
    list = list.where((file) => file.isDuplicate).toList();
  }

  // 6. Size Range Filter
  if (filter.sizeRange != 'All') {
    list = list.where((file) {
      if (filter.sizeRange == 'Small (<1MB)') return file.sizeInMb < 1.0;
      if (filter.sizeRange == 'Medium (1-10MB)')
        return file.sizeInMb >= 1.0 && file.sizeInMb <= 10.0;
      if (filter.sizeRange == 'Large (10-100MB)')
        return file.sizeInMb >= 10.0 && file.sizeInMb <= 100.0;
      if (filter.sizeRange == 'Huge (>100MB)') return file.sizeInMb > 100.0;
      return true;
    }).toList();
  }

  // 7. Date Range Filter
  if (filter.dateRange != 'All') {
    final today = DateTime.now();
    list = list.where((file) {
      final diff = today.difference(file.modifiedDate).inDays;
      if (filter.dateRange == 'Today') return diff == 0;
      if (filter.dateRange == 'This Week') return diff <= 7;
      if (filter.dateRange == 'This Month') return diff <= 30;
      if (filter.dateRange == 'Older') return diff > 30;
      return true;
    }).toList();
  }

  // 8. Chained Multi-Level Sorting
  list.sort((a, b) {
    // 1st Priority: Name sort (if active)
    if (filter.nameSort != 'Off') {
      final isDesc = filter.nameSort == 'Descending';
      final comp = isDesc
          ? b.name.toLowerCase().compareTo(a.name.toLowerCase())
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (comp != 0) return comp;
    }
    // 2nd Priority: Date sort (if active)
    if (filter.dateSort != 'Off') {
      final isDesc = filter.dateSort == 'Descending';
      final comp = isDesc
          ? b.modifiedDate.compareTo(a.modifiedDate)
          : a.modifiedDate.compareTo(b.modifiedDate);
      if (comp != 0) return comp;
    }
    // 3rd Priority: Size sort (if active)
    if (filter.sizeSort != 'Off') {
      final isDesc = filter.sizeSort == 'Descending';
      final comp = isDesc
          ? b.sizeInMb.compareTo(a.sizeInMb)
          : a.sizeInMb.compareTo(b.sizeInMb);
      if (comp != 0) return comp;
    }
    return 0;
  });

  return list;
});
