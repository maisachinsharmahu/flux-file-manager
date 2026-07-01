import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../home/presentation/widgets/file_detail_sheet.dart';
import '../../../core/providers/file_filter_provider.dart';
import '../../search/presentation/widgets/quick_sort_filter_sheet.dart';
import '../../../core/widgets/file_type_icon.dart';
import '../../../../bridge/flux_bridge.dart';
import '../../../../core/utils/share_helper.dart';
import '../../../core/providers/trash_provider.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  bool _isSearching = false;
  String _searchQuery = '';
  String _searchScope = 'local'; // 'local' or 'global'
  final TextEditingController _searchController = TextEditingController();

  String _currentPath = '/storage/emulated/0';
  final List<String> _pathHistory = [];
  List<dynamic> _currentContents = [];
  bool _isLoading = false;
  late final FileFilterNotifier _filterNotifier;

  bool _isSelectionMode = false;
  final Set<int> _selectedFids = {};
  double? _dragStartHeight;

  void _toggleSelection(int fid) {
    setState(() {
      if (_selectedFids.contains(fid)) {
        _selectedFids.remove(fid);
        if (_selectedFids.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFids.add(fid);
      }
    });
  }

  Future<void> _deleteSelectedFiles(List<dynamic> itemsList, List<FluxFile> currentFileList, bool isFolderList) async {
    final List<int> fids = [];
    final List<String> fileNames = [];

    if (isFolderList) {
      final selectedItems = itemsList.where((item) {
        final fid = (item['fid'] as num?)?.toInt();
        return fid != null && _selectedFids.contains(fid);
      }).toList();
      for (final item in selectedItems) {
        fids.add((item['fid'] as num).toInt());
        fileNames.add(item['name'] as String);
      }
    } else {
      final selectedItems = currentFileList.where((f) => f.fid != null && _selectedFids.contains(f.fid)).toList();
      for (final f in selectedItems) {
        fids.add(f.fid!);
        fileNames.add(f.name);
      }
    }

    if (fids.isEmpty) return;

    final success = await FluxBridge.executeBatchDelete(fids);
    if (success) {
      ref.read(trashProvider.notifier).refreshTrash();
      await _loadDirectoryContents();

      setState(() {
        _isSelectionMode = false;
        _selectedFids.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fids.length == 1
                ? 'Moved "${fileNames.first}" to Trash'
                : 'Moved ${fids.length} files to Trash',
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.neutral900,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.0.r),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.mintAccent,
            onPressed: () async {
              final restored = await FluxBridge.restoreTombstones(fids);
              if (restored) {
                ref.read(trashProvider.notifier).refreshTrash();
                await _loadDirectoryContents();
              }
            },
          ),
        ),
      );
    }
  }

  void _shareSelectedFiles(List<dynamic> itemsList, List<FluxFile> currentFileList, bool isFolderList) {
    final List<String> selectedNames = [];

    if (isFolderList) {
      final selectedItems = itemsList.where((item) {
        final fid = (item['fid'] as num?)?.toInt();
        return fid != null && _selectedFids.contains(fid);
      }).toList();
      for (final item in selectedItems) {
        selectedNames.add(item['name'] as String);
      }
    } else {
      final selectedItems = currentFileList.where((f) => f.fid != null && _selectedFids.contains(f.fid)).toList();
      for (final f in selectedItems) {
        selectedNames.add(f.name);
      }
    }

    if (selectedNames.isEmpty) return;
    
    ShareHelper.showShareSheet(context, selectedNames);
    setState(() {
      _isSelectionMode = false;
      _selectedFids.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _filterNotifier = ref.read(fileFilterProvider.notifier);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _loadDirectoryContents();
  }

  Future<void> _loadDirectoryContents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final contents = await FluxBridge.getDirectoryContents(_currentPath);
      if (!mounted) return;
      
      // Sort directories first, then files alphabetically
      contents.sort((a, b) {
        final aIsDir = a['category'] == 'Directory';
        final bIsDir = b['category'] == 'Directory';
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
      });

      setState(() {
        _currentContents = contents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading directory contents: $e');
    }
  }

  void _navigateToFolder(String folderPath) {
    setState(() {
      _pathHistory.add(_currentPath);
      _currentPath = folderPath;
    });
    _loadDirectoryContents();
  }

  void _navigateBack() {
    if (_pathHistory.isNotEmpty) {
      setState(() {
        _currentPath = _pathHistory.removeLast();
      });
      _loadDirectoryContents();
    } else {
      context.pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    Future.microtask(() {
      _filterNotifier.reset();
    });
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await FluxBridge.initializeIndex(force: true);
    await _loadDirectoryContents();
    if (mounted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {

    final activeCategory = ref.watch(selectedBrowserCategoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryLight.withValues(alpha: 0.6) : AppColors.neutral400;
    final iconColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);

    final filterState = ref.watch(fileFilterProvider);

    // Resolve dynamic list based on whether category view is active
    bool isFolderList = activeCategory == null;
    final String pageTitle = activeCategory ??
        (_currentPath == '/storage/emulated/0'
            ? 'Internal Storage'
            : _currentPath.split('/').last);
    List<FluxFile> currentFileList = [];

    // Helper to map dynamic maps back to FluxFile objects
    FluxFile mapToFluxFile(Map<dynamic, dynamic> map) {
      final category = map['category'] as String? ?? 'Others';
      Color themeColor;
      if (category == 'Photos') themeColor = const Color(0xFFF5A623);
      else if (category == 'Videos') themeColor = const Color(0xFFD0021B);
      else if (category == 'Audio') themeColor = const Color(0xFF4A90E2);
      else if (category == 'Documents') themeColor = const Color(0xFF7ED321);
      else if (category == 'Application') themeColor = const Color(0xFF9013FE);
      else if (category == 'Directory') themeColor = const Color(0xFFFFB020);
      else themeColor = const Color(0xFF9E9E9E);

      return FluxFile(
        fid: (map['fid'] as num?)?.toInt(),
        name: map['name'] as String? ?? '',
        path: map['path'] as String? ?? '',
        category: category,
        sizeString: map['sizeString'] as String? ?? '0 B',
        sizeInMb: (map['size'] as num? ?? 0).toDouble() / (1024.0 * 1024.0),
        modifiedDate: DateTime.fromMillisecondsSinceEpoch((map['modifiedDate'] as num? ?? 0).toInt()),
        isDuplicate: map['isDuplicate'] as bool? ?? false,
        isVault: map['isVault'] as bool? ?? false,
        location: map['location'] as String? ?? 'Local',
        themeColor: themeColor,
      );
    }

    final List<Map<dynamic, dynamic>> displayedContents = List<Map<dynamic, dynamic>>.from(_currentContents);

    if (_isSearching && _searchScope == 'global') {
      isFolderList = false;
      currentFileList = ref.watch(filteredFilesProvider(_searchQuery));
    } else {
      if (!isFolderList) {
        final allFiltered = ref.watch(filteredFilesProvider(_isSearching ? _searchQuery : ''));
        currentFileList = allFiltered.where((file) => file.category == activeCategory).toList();
      } else {
        if (_isSearching && _searchQuery.isNotEmpty) {
          final lowerQuery = _searchQuery.toLowerCase();
          displayedContents.retainWhere((item) => (item['name'] as String).toLowerCase().contains(lowerQuery));
        }

        // Sort dynamically based on filterState
        displayedContents.sort((a, b) {
          final aIsDir = a['category'] == 'Directory';
          final bIsDir = b['category'] == 'Directory';
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;

          if (filterState.nameSort != 'Off') {
            final isDesc = filterState.nameSort == 'Descending';
            final comp = (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
            return isDesc ? -comp : comp;
          }
          if (filterState.dateSort != 'Off') {
            final isDesc = filterState.dateSort == 'Descending';
            final aTime = a['modifiedDate'] as num? ?? 0;
            final bTime = b['modifiedDate'] as num? ?? 0;
            final comp = aTime.compareTo(bTime);
            return isDesc ? -comp : comp;
          }
          if (filterState.sizeSort != 'Off') {
            final isDesc = filterState.sizeSort == 'Descending';
            final aSize = a['size'] as num? ?? 0;
            final bSize = b['size'] as num? ?? 0;
            final comp = aSize.compareTo(bSize);
            return isDesc ? -comp : comp;
          }
          return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
        });
      }
    }


    String formatFriendlyDate(DateTime dt) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$month ${dt.day}, ${dt.year}, $hour:$minute $ampm';
    }

    Widget buildListContent() {
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.mintAccent,
          ),
        );
      }

      if (isFolderList) {
        if (displayedContents.isEmpty) {
          return ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              Padding(
                padding: EdgeInsets.only(top: 80.0.h),
                child: Center(
                  child: Text(
                    'This folder is empty.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.0.sp,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: displayedContents.length,
            separatorBuilder: (context, index) => Divider(
              color: dividerColor,
              height: 1.0.h,
              thickness: 1.0.r,
            ),
            itemBuilder: (context, index) {
              final item = displayedContents[index];
              final name = item['name'] as String? ?? '';
              final path = item['path'] as String? ?? '';
              final category = item['category'] as String? ?? 'Others';
              final isDir = category == 'Directory';

              if (isDir) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _navigateToFolder(path),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder,
                          size: 44.0.r,
                          color: const Color(0xFFFFB020),
                        ),
                        SizedBox(width: 16.0.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.0.sp,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 4.0.h),
                              Text(
                                'Folder',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.0.sp,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14.0.r,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                final file = mapToFluxFile(item);
                return Dismissible(
                  key: Key('file_dismiss_${file.fid}_${file.path}'),
                  direction: _isSelectionMode 
                      ? DismissDirection.none 
                      : DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20.0.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.share_rounded,
                          color: Colors.green,
                          size: 22.0.r,
                        ),
                        SizedBox(width: 8.0.w),
                        Text(
                          'Share File',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                            fontSize: 13.0.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.0.w),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.0.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Move to Trash',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                            fontSize: 13.0.sp,
                          ),
                        ),
                        SizedBox(width: 8.0.w),
                        Icon(
                          Icons.delete_sweep_outlined,
                          color: Colors.redAccent,
                          size: 22.0.r,
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      ShareHelper.showShareSheet(context, [file.name]);
                      return false;
                    }
                    return true;
                  },
                  onDismissed: (direction) async {
                    final fid = file.fid;
                    if (fid == null) return;
                    final success = await FluxBridge.executeBatchDelete([fid]);
                    if (success) {
                      ref.read(trashProvider.notifier).refreshTrash();
                      await _loadDirectoryContents();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Moved "${file.name}" to Trash',
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
                          ),
                          backgroundColor: AppColors.neutral900,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16.0.r),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
                          action: SnackBarAction(
                            label: 'UNDO',
                            textColor: AppColors.mintAccent,
                            onPressed: () async {
                              final restored = await FluxBridge.restoreTombstones([fid]);
                              if (restored) {
                                ref.read(trashProvider.notifier).refreshTrash();
                                await _loadDirectoryContents();
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(file.fid!);
                      } else {
                        final detail = FileDetail(
                          name: file.name,
                          size: file.sizeString,
                          createdDate: formatFriendlyDate(file.modifiedDate),
                          modifiedDate: '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
                          type: file.category,
                          themeColor: file.themeColor,
                          fallbackIcon: file.fallbackIcon,
                          fluxIcon: file.fluxIcon,
                        );
                        FileDetailSheet.show(context, detail);
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedFids.add(file.fid!);
                        });
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0.h),
                      child: Row(
                        children: [
                          if (_isSelectionMode)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(right: 12.0.w),
                              child: Icon(
                                _selectedFids.contains(file.fid)
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: _selectedFids.contains(file.fid)
                                    ? AppColors.mintAccent
                                    : subtitleColor,
                                size: 22.0.r,
                              ),
                            ),
                          FileTypeIcon(
                            extension: file.fileExtension,
                            path: file.path,
                            size: 44.0.r,
                          ),
                          SizedBox(width: 16.0.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16.0.sp,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: 4.0.h),
                                Text(
                                  file.sizeString,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.0.sp,
                                    fontWeight: FontWeight.w500,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isSelectionMode)
                            GestureDetector(
                              onTap: () {
                                final detail = FileDetail(
                                  name: file.name,
                                  size: file.sizeString,
                                  createdDate: formatFriendlyDate(file.modifiedDate),
                                  modifiedDate: '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
                                  type: file.category,
                                  themeColor: file.themeColor,
                                  fallbackIcon: file.fallbackIcon,
                                  fluxIcon: file.fluxIcon,
                                );
                                FileDetailSheet.show(context, detail);
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.0.r),
                                child: Icon(
                                  Icons.more_vert,
                                  size: 20.0.r,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          );
        }
      } else {
        if (currentFileList.isEmpty) {
          return ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              Padding(
                padding: EdgeInsets.only(top: 80.0.h),
                child: Center(
                  child: Text(
                    'No matching files found.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.0.sp,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: currentFileList.length,
            separatorBuilder: (context, index) => Divider(
              color: dividerColor,
              height: 1.0.h,
              thickness: 1.0.r,
            ),
            itemBuilder: (context, index) {
              final file = currentFileList[index];

              return Dismissible(
                key: Key('file_dismiss_${file.fid}_${file.path}'),
                direction: _isSelectionMode 
                    ? DismissDirection.none 
                    : DismissDirection.horizontal,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 20.0.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.0.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.share_rounded,
                        color: Colors.green,
                        size: 22.0.r,
                      ),
                      SizedBox(width: 8.0.w),
                      Text(
                        'Share File',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                          fontSize: 13.0.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.0.w),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.0.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Move to Trash',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                          fontSize: 13.0.sp,
                        ),
                      ),
                      SizedBox(width: 8.0.w),
                      Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.redAccent,
                        size: 22.0.r,
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    ShareHelper.showShareSheet(context, [file.name]);
                    return false;
                  }
                  return true;
                },
                onDismissed: (direction) async {
                  final fid = file.fid;
                  if (fid == null) return;
                  final success = await FluxBridge.executeBatchDelete([fid]);
                  if (success) {
                    ref.read(trashProvider.notifier).refreshTrash();
                    await _loadDirectoryContents();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Moved "${file.name}" to Trash',
                          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: AppColors.neutral900,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(16.0.r),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
                        action: SnackBarAction(
                          label: 'UNDO',
                          textColor: AppColors.mintAccent,
                          onPressed: () async {
                            final restored = await FluxBridge.restoreTombstones([fid]);
                            if (restored) {
                              ref.read(trashProvider.notifier).refreshTrash();
                              await _loadDirectoryContents();
                            }
                          },
                        ),
                      ),
                    );
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(file.fid!);
                    } else {
                      final detail = FileDetail(
                        name: file.name,
                        size: file.sizeString,
                        createdDate: formatFriendlyDate(file.modifiedDate),
                        modifiedDate: '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
                        type: file.category,
                        themeColor: file.themeColor,
                        fallbackIcon: file.fallbackIcon,
                        fluxIcon: file.fluxIcon,
                      );
                      FileDetailSheet.show(context, detail);
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedFids.add(file.fid!);
                      });
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0.h),
                    child: Row(
                      children: [
                        if (_isSelectionMode)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: 12.0.w),
                            child: Icon(
                              _selectedFids.contains(file.fid)
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: _selectedFids.contains(file.fid)
                                  ? AppColors.mintAccent
                                  : subtitleColor,
                              size: 22.0.r,
                            ),
                          ),
                        FileTypeIcon(
                          extension: file.fileExtension,
                          path: file.path,
                          size: 44.0.r,
                        ),
                        SizedBox(width: 16.0.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.0.sp,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.0.h),
                              Text(
                                '${file.sizeString} • ${file.location}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.0.sp,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isSelectionMode)
                          GestureDetector(
                            onTap: () {
                              final detail = FileDetail(
                                name: file.name,
                                size: file.sizeString,
                                createdDate: formatFriendlyDate(file.modifiedDate),
                                modifiedDate: '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
                                type: file.category,
                                themeColor: file.themeColor,
                                fallbackIcon: file.fallbackIcon,
                                fluxIcon: file.fluxIcon,
                              );
                              FileDetailSheet.show(context, detail);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.all(8.0.r),
                              child: Icon(
                                Icons.more_vert,
                                size: 20.0.r,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (details) {
        _dragStartHeight = details.globalPosition.dy;
      },
      onVerticalDragEnd: (details) {
        if (_dragStartHeight != null &&
            MediaQuery.of(context).size.height - _dragStartHeight! < 120) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            setState(() {
              _isSearching = true;
              _searchScope = 'local';
            });
          }
        }
      },
      child: PopScope(
        canPop: activeCategory == null && _pathHistory.isEmpty,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (activeCategory != null) {
            ref.read(selectedBrowserCategoryProvider.notifier).state = null;
          } else {
            _navigateBack();
          }
        },
        child: Scaffold(
          backgroundColor: bgColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with Animated Switcher for Search Mode
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, -0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _isSelectionMode
                            ? Padding(
                                key: const ValueKey('selectionHeader'),
                                padding: EdgeInsets.fromLTRB(16.0.w, 16.0.h, 20.0.w, 8.0.h),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSelectionMode = false;
                                          _selectedFids.clear();
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(8.0.r),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 24.0.r,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.0.w),
                                    Text(
                                      '${_selectedFids.length} selected',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 20.0.sp,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Select/Deselect All
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          // Gather all selectable FIDs in current view
                                          final List<int> selectableFids = [];
                                          if (isFolderList) {
                                            for (final item in displayedContents) {
                                              final category = item['category'] as String? ?? 'Others';
                                              final fid = (item['fid'] as num?)?.toInt();
                                              if (category != 'Directory' && fid != null) {
                                                selectableFids.add(fid);
                                              }
                                            }
                                          } else {
                                            for (final file in currentFileList) {
                                              if (file.fid != null) {
                                                selectableFids.add(file.fid!);
                                              }
                                            }
                                          }

                                          if (_selectedFids.length == selectableFids.length) {
                                            _selectedFids.clear();
                                            _isSelectionMode = false;
                                          } else {
                                            _selectedFids.addAll(selectableFids);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0.w),
                                        child: Icon(
                                          // Simple length comparison to toggle Select All icon
                                          (() {
                                            final List<int> selectableFids = [];
                                            if (isFolderList) {
                                              for (final item in displayedContents) {
                                                final category = item['category'] as String? ?? 'Others';
                                                final fid = (item['fid'] as num?)?.toInt();
                                                if (category != 'Directory' && fid != null) {
                                                  selectableFids.add(fid);
                                                }
                                              }
                                            } else {
                                              for (final file in currentFileList) {
                                                if (file.fid != null) {
                                                  selectableFids.add(file.fid!);
                                                }
                                              }
                                            }
                                            return _selectedFids.length == selectableFids.length
                                                ? Icons.deselect_rounded
                                                : Icons.select_all_rounded;
                                          })(),
                                          size: 24.0.r,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                    // Share Selected
                                    GestureDetector(
                                      onTap: () => _shareSelectedFiles(displayedContents, currentFileList, isFolderList),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0.w),
                                        child: Icon(
                                          Icons.share_rounded,
                                          size: 24.0.r,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                    // Delete Selected
                                    GestureDetector(
                                      onTap: () => _deleteSelectedFiles(displayedContents, currentFileList, isFolderList),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0.w),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 24.0.r,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _isSearching
                                ? Padding(
                                    key: const ValueKey('searchHeader'),
                                    padding: EdgeInsets.fromLTRB(16.0.w, 16.0.h, 20.0.w, 8.0.h),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isSearching = false;
                                              _searchQuery = '';
                                              _searchController.clear();
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(8.0.r),
                                            child: Icon(
                                              Icons.arrow_back_ios_new,
                                              size: 20.0.r,
                                              color: iconColor,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8.0.w),
                                        Expanded(
                                          child: Container(
                                            height: 40.0.h,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.05)
                                                  : Colors.black.withValues(alpha: 0.03),
                                              borderRadius: BorderRadius.circular(20.0.r),
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.search,
                                                  size: 18.0.r,
                                                  color: subtitleColor,
                                                ),
                                                SizedBox(width: 8.0.w),
                                                Expanded(
                                                  child: TextField(
                                                    controller: _searchController,
                                                    autofocus: true,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _searchQuery = val;
                                                      });
                                                    },
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 14.0.sp,
                                                      color: textColor,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: 'Search...',
                                                      hintStyle: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14.0.sp,
                                                        color: subtitleColor,
                                                      ),
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ),
                                                if (_searchQuery.isNotEmpty)
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _searchQuery = '';
                                                        _searchController.clear();
                                                      });
                                                    },
                                                    child: Icon(
                                                      Icons.close_rounded,
                                                      size: 18.0.r,
                                                      color: subtitleColor,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Padding(
                                    key: const ValueKey('normalHeader'),
                                    padding: EdgeInsets.fromLTRB(16.0.w, 16.0.h, 20.0.w, 8.0.h),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (activeCategory != null) {
                                              ref.read(selectedBrowserCategoryProvider.notifier).state = null;
                                            } else {
                                              _navigateBack();
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(8.0.r),
                                            child: Icon(
                                              Icons.arrow_back_ios_new,
                                              size: 20.0.r,
                                              color: iconColor,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8.0.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                pageTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 24.0.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: textColor,
                                                ),
                                              ),
                                              if (activeCategory == null)
                                                Text(
                                                  _currentPath.replaceAll('/storage/emulated/0', 'Internal Storage'),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12.0.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: subtitleColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isSearching = true;
                                              _searchScope = 'local';
                                            });
                                          },
                                          child: Icon(
                                            Icons.search,
                                            size: 26.0.r,
                                            color: iconColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                    ),

                    // macOS Finder style Search Scope Bar
                    if (_isSearching)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
                        child: Row(
                          children: [
                            Text(
                              'Search: ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.0.sp,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                            SizedBox(width: 8.0.w),
                            _buildScopePill(
                              label: pageTitle,
                              isActive: _searchScope == 'local',
                              onTap: () {
                                setState(() {
                                  _searchScope = 'local';
                                });
                              },
                              isDark: isDark,
                              borderColor: dividerColor,
                            ),
                            SizedBox(width: 8.0.w),
                            _buildScopePill(
                              label: 'All Files',
                              isActive: _searchScope == 'global',
                              onTap: () {
                                setState(() {
                                  _searchScope = 'global';
                                });
                              },
                              isDark: isDark,
                              borderColor: dividerColor,
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 16.0.h),
                    
                    // Filters Row: Sorting and Layout settings
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 8.0.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PopupMenuButton<String>(
                            onSelected: (String value) {
                              final filterNotifier = ref.read(fileFilterProvider.notifier);
                              if (value == 'name') {
                                filterNotifier.setDateSort('Off');
                                filterNotifier.setSizeSort('Off');
                                filterNotifier.setNameSort('Ascending');
                              } else if (value == 'size') {
                                filterNotifier.setNameSort('Off');
                                filterNotifier.setDateSort('Off');
                                filterNotifier.setSizeSort('Descending');
                              } else if (value == 'date') {
                                filterNotifier.setNameSort('Off');
                                filterNotifier.setSizeSort('Off');
                                filterNotifier.setDateSort('Descending');
                              }
                            },
                            offset: Offset(0, 30.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0.r),
                              side: BorderSide(color: dividerColor, width: 1.0.r),
                            ),
                            color: isDark ? AppColors.neutral950 : Colors.white,
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'date',
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 18.0.r, color: textColor),
                                    SizedBox(width: 8.0.w),
                                    Text('Sort by Date', style: TextStyle(fontFamily: 'Inter', fontSize: 14.0.sp, color: textColor)),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'size',
                                child: Row(
                                  children: [
                                    Icon(Icons.crop_free_outlined, size: 18.0.r, color: textColor),
                                    SizedBox(width: 8.0.w),
                                    Text('Sort by Size', style: TextStyle(fontFamily: 'Inter', fontSize: 14.0.sp, color: textColor)),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'name',
                                child: Row(
                                  children: [
                                    Icon(Icons.sort_by_alpha_outlined, size: 18.0.r, color: textColor),
                                    SizedBox(width: 8.0.w),
                                    Text('Sort by Name', style: TextStyle(fontFamily: 'Inter', fontSize: 14.0.sp, color: textColor)),
                                  ],
                                ),
                              ),
                            ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  filterState.nameSort != 'Off'
                                      ? 'Name'
                                      : (filterState.sizeSort != 'Off' ? 'Size' : 'Date'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.0.sp,
                                    fontWeight: FontWeight.w600,
                                    color: subtitleColor,
                                  ),
                                ),
                                SizedBox(width: 4.0.w),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 20.0.r,
                                  color: subtitleColor,
                                ),
                              ],
                            ),
                          ),
                          
                          // Quick Actions: Advanced Filters & Grid toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                GestureDetector(
                                  onTap: () {
                                    QuickSortFilterSheet.show(context, hideFileType: true);
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 22.0.r,
                                        color: filterState.activeFiltersCount > 0
                                            ? AppColors.mintAccent
                                            : subtitleColor,
                                      ),
                                      if (filterState.activeFiltersCount > 0)
                                        Positioned(
                                          top: -3.0.r,
                                          right: -3.0.r,
                                          child: Container(
                                            padding: EdgeInsets.all(2.0.r),
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: 8.0.r,
                                              minHeight: 8.0.r,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16.0.w),
                              Icon(
                                Icons.grid_view_outlined,
                                size: 22.0.r,
                                color: subtitleColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.0.h),

                    // Dynamic Files/Folders ListView wrapped in RefreshIndicator
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.mintAccent,
                        backgroundColor: isDark ? AppColors.neutral900 : Colors.white,
                        displacement: 20.h,
                        onRefresh: _handleRefresh,
                        child: buildListContent(),
                            ),
                          ),
                  ],
                ),
                // Floating scan/layout icon at the bottom right corner
                Positioned(
                  right: 24.0.w,
                  bottom: 24.0.h,
                  child: Container(
                    width: 48.0.r,
                    height: 48.0.r,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral900 : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10.0.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                      border: Border.all(
                        color: dividerColor,
                        width: 1.0.r,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fit_screen_outlined,
                        size: 22.0.r,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    );
  }
  Widget _buildScopePill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 6.0.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.mintAccent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16.0.r),
          border: Border.all(
            color: isActive ? AppColors.mintAccent : borderColor,
            width: 1.0.r,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0.sp,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? Colors.black
                : (isDark ? AppColors.pureWhite : AppColors.neutral900),
          ),
        ),
      ),
    );
  }
}