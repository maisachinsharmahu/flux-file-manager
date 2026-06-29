import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/flux_icon.dart';

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

  FluxIconType? get fluxIcon {
    if (category == 'Documents') {
      if (name.endsWith('.pdf')) return FluxIconType.adobeReader;
      return FluxIconType.documentColor;
    }
    return null;
  }
}

class FileFilterState {
  final Set<String> categories;
  final String sizeRange; // 'All', 'Small (<1MB)', 'Medium (1-10MB)', 'Large (10-100MB)', 'Huge (>100MB)'
  final String dateRange; // 'All', 'Today', 'This Week', 'This Month', 'Older'
  final String sortBy; // 'Name', 'Date', 'Size'
  final bool isDescending; // true for Descending/High-to-Low, false for Ascending/Low-to-High
  final String location; // 'All', 'Local', 'Cloud', 'SD Card'
  final bool showVaultOnly;
  final bool showDuplicatesOnly;

  FileFilterState({
    required this.categories,
    required this.sizeRange,
    required this.dateRange,
    required this.sortBy,
    required this.isDescending,
    required this.location,
    required this.showVaultOnly,
    required this.showDuplicatesOnly,
  });

  FileFilterState copyWith({
    Set<String>? categories,
    String? sizeRange,
    String? dateRange,
    String? sortBy,
    bool? isDescending,
    String? location,
    bool? showVaultOnly,
    bool? showDuplicatesOnly,
  }) {
    return FileFilterState(
      categories: categories ?? this.categories,
      sizeRange: sizeRange ?? this.sizeRange,
      dateRange: dateRange ?? this.dateRange,
      sortBy: sortBy ?? this.sortBy,
      isDescending: isDescending ?? this.isDescending,
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
            sortBy: 'Date',
            isDescending: true, // Default descending (newest first, highest capacity first)
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

  void setSortBy(String sort) {
    state = state.copyWith(sortBy: sort);
  }

  void setIsDescending(bool value) {
    state = state.copyWith(isDescending: value);
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
      sortBy: 'Date',
      isDescending: true,
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

// All files source database provider
final allFilesProvider = Provider<List<FluxFile>>((ref) {
  final now = DateTime.now();
  return [
    // Photos
    FluxFile(
      name: 'vacation_pic_1.jpg',
      path: '/Internal/DCIM/vacation_pic_1.jpg',
      category: 'Photos',
      sizeString: '2.4 MB',
      sizeInMb: 2.4,
      modifiedDate: now.subtract(const Duration(hours: 2)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFFFD020),
    ),
    FluxFile(
      name: 'screenshot_2.png',
      path: '/Internal/DCIM/screenshot_2.png',
      category: 'Photos',
      sizeString: '850 KB',
      sizeInMb: 0.83,
      modifiedDate: now.subtract(const Duration(hours: 10)),
      isDuplicate: true,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFFFD020),
    ),
    FluxFile(
      name: 'profile_3.jpg',
      path: '/Internal/Canva/profile_3.jpg',
      category: 'Photos',
      sizeString: '1.2 MB',
      sizeInMb: 1.2,
      modifiedDate: now.subtract(const Duration(days: 2)),
      isDuplicate: false,
      isVault: true,
      location: 'Cloud',
      themeColor: const Color(0xFFFFD020),
    ),
    FluxFile(
      name: 'insta_story_4.jpeg',
      path: '/Internal/DCIM/insta_story_4.jpeg',
      category: 'Photos',
      sizeString: '3.1 MB',
      sizeInMb: 3.1,
      modifiedDate: now.subtract(const Duration(days: 5)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFFFD020),
    ),
    FluxFile(
      name: 'avatar_glowing.png',
      path: '/Internal/Canva/avatar_glowing.png',
      category: 'Photos',
      sizeString: '400 KB',
      sizeInMb: 0.39,
      modifiedDate: now.subtract(const Duration(days: 15)),
      isDuplicate: false,
      isVault: false,
      location: 'SD Card',
      themeColor: const Color(0xFFFFD020),
    ),

    // Videos
    FluxFile(
      name: 'vlog_v3.mp4',
      path: '/Internal/Movies/vlog_v3.mp4',
      category: 'Videos',
      sizeString: '48 MB',
      sizeInMb: 48.0,
      modifiedDate: now.subtract(const Duration(hours: 4)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFFF9010),
    ),
    FluxFile(
      name: 'tutorial_flutter.mov',
      path: '/Internal/Download/tutorial_flutter.mov',
      category: 'Videos',
      sizeString: '125 MB',
      sizeInMb: 125.0,
      modifiedDate: now.subtract(const Duration(days: 1)),
      isDuplicate: false,
      isVault: false,
      location: 'Cloud',
      themeColor: const Color(0xFFFF9010),
    ),
    FluxFile(
      name: 'movie_sample.mkv',
      path: '/Internal/Movies/movie_sample.mkv',
      category: 'Videos',
      sizeString: '820 MB',
      sizeInMb: 820.0,
      modifiedDate: now.subtract(const Duration(days: 4)),
      isDuplicate: false,
      isVault: true,
      location: 'SD Card',
      themeColor: const Color(0xFFFF9010),
    ),
    FluxFile(
      name: 'screen_recording.mp4',
      path: '/Internal/DCIM/screen_recording.mp4',
      category: 'Videos',
      sizeString: '12 MB',
      sizeInMb: 12.0,
      modifiedDate: now.subtract(const Duration(days: 20)),
      isDuplicate: true,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFFF9010),
    ),

    // Documents
    FluxFile(
      name: 'resume_sachin.pdf',
      path: '/Internal/Documents/resume_sachin.pdf',
      category: 'Documents',
      sizeString: '1.2 MB',
      sizeInMb: 1.2,
      modifiedDate: now.subtract(const Duration(days: 3)),
      isDuplicate: false,
      isVault: false,
      location: 'Cloud',
      themeColor: const Color(0xFFA020F0),
    ),
    FluxFile(
      name: 'invoice_flux.docx',
      path: '/Internal/Documents/invoice_flux.docx',
      category: 'Documents',
      sizeString: '240 KB',
      sizeInMb: 0.23,
      modifiedDate: now.subtract(const Duration(hours: 12)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFA020F0),
    ),
    FluxFile(
      name: 'budget_june.xlsx',
      path: '/Internal/Documents/budget_june.xlsx',
      category: 'Documents',
      sizeString: '670 KB',
      sizeInMb: 0.65,
      modifiedDate: now.subtract(const Duration(days: 6)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFA020F0),
    ),
    FluxFile(
      name: 'project_proposal.pdf',
      path: '/Internal/Documents/project_proposal.pdf',
      category: 'Documents',
      sizeString: '4.2 MB',
      sizeInMb: 4.2,
      modifiedDate: now.subtract(const Duration(days: 12)),
      isDuplicate: true,
      isVault: true,
      location: 'Cloud',
      themeColor: const Color(0xFFA020F0),
    ),
    FluxFile(
      name: 'Agreement Contract.pdf',
      path: '/Internal/Documents/Agreement Contract.pdf',
      category: 'Documents',
      sizeString: '793 KB',
      sizeInMb: 0.77,
      modifiedDate: now.subtract(const Duration(days: 27)),
      isDuplicate: false,
      isVault: false,
      location: 'Cloud',
      themeColor: const Color(0xFFA020F0),
    ),
    FluxFile(
      name: 'Service Agreement Contract.pdf',
      path: '/Internal/Documents/Service Agreement Contract.pdf',
      category: 'Documents',
      sizeString: '912 KB',
      sizeInMb: 0.89,
      modifiedDate: now.subtract(const Duration(days: 45)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFA020F0),
    ),

    // Audio
    FluxFile(
      name: 'audio_recording.wav',
      path: '/Internal/Music/audio_recording.wav',
      category: 'Audio',
      sizeString: '15 MB',
      sizeInMb: 15.0,
      modifiedDate: now.subtract(const Duration(hours: 1)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFFF40A0),
    ),
    FluxFile(
      name: 'song_remix.mp3',
      path: '/Internal/Music/song_remix.mp3',
      category: 'Audio',
      sizeString: '8.2 MB',
      sizeInMb: 8.2,
      modifiedDate: now.subtract(const Duration(days: 3)),
      isDuplicate: true,
      isVault: false,
      location: 'SD Card',
      themeColor: const Color(0xFFFF40A0),
    ),
    FluxFile(
      name: 'podcast_e1.m4a',
      path: '/Internal/Music/podcast_e1.m4a',
      category: 'Audio',
      sizeString: '42 MB',
      sizeInMb: 42.0,
      modifiedDate: now.subtract(const Duration(days: 10)),
      isDuplicate: false,
      isVault: true,
      location: 'Cloud',
      themeColor: const Color(0xFFFF40A0),
    ),

    // Application
    FluxFile(
      name: 'whatsapp_messenger.apk',
      path: '/Internal/Download/whatsapp_messenger.apk',
      category: 'Application',
      sizeString: '52 MB',
      sizeInMb: 52.0,
      modifiedDate: now.subtract(const Duration(days: 2)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFFF4D4D),
    ),
    FluxFile(
      name: 'flux_file_manager.apk',
      path: '/Internal/Download/flux_file_manager.apk',
      category: 'Application',
      sizeString: '18 MB',
      sizeInMb: 18.0,
      modifiedDate: now.subtract(const Duration(hours: 3)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFFFF4D4D),
    ),
    FluxFile(
      name: 'pubg_mobile_installer.apk',
      path: '/Internal/Download/pubg_mobile_installer.apk',
      category: 'Application',
      sizeString: '1.2 GB',
      sizeInMb: 1228.0,
      modifiedDate: now.subtract(const Duration(days: 7)),
      isDuplicate: true,
      isVault: false,
      location: 'SD Card',
      themeColor: const Color(0xFFFF4D4D),
    ),

    // Others
    FluxFile(
      name: 'backup_archive.zip',
      path: '/Internal/Backups/backup_archive.zip',
      category: 'Others',
      sizeString: '420 MB',
      sizeInMb: 420.0,
      modifiedDate: now.subtract(const Duration(days: 4)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFF9E9E9E),
    ),
    FluxFile(
      name: 'system_config.json',
      path: '/Internal/Android/system_config.json',
      category: 'Others',
      sizeString: '12 KB',
      sizeInMb: 0.01,
      modifiedDate: now.subtract(const Duration(hours: 8)),
      isDuplicate: false,
      isVault: false,
      location: 'Local',
      themeColor: const Color(0xFF9E9E9E),
    ),
    FluxFile(
      name: 'encrypted_payload.bin',
      path: '/Internal/Backups/encrypted_payload.bin',
      category: 'Others',
      sizeString: '92 MB',
      sizeInMb: 92.0,
      modifiedDate: now.subtract(const Duration(days: 14)),
      isDuplicate: false,
      isVault: true,
      location: 'Local',
      themeColor: const Color(0xFF9E9E9E),
    ),
  ];
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

  // 8. Sorting
  if (filter.sortBy == 'Name') {
    list.sort((a, b) => filter.isDescending
        ? b.name.toLowerCase().compareTo(a.name.toLowerCase())
        : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  } else if (filter.sortBy == 'Size') {
    list.sort((a, b) => filter.isDescending
        ? b.sizeInMb.compareTo(a.sizeInMb)
        : a.sizeInMb.compareTo(b.sizeInMb));
  } else if (filter.sortBy == 'Date') {
    list.sort((a, b) => filter.isDescending
        ? b.modifiedDate.compareTo(a.modifiedDate)
        : a.modifiedDate.compareTo(b.modifiedDate));
  }

  return list;
});
