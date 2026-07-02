import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/providers/file_filter_provider.dart';
import '../../home/presentation/widgets/file_detail_sheet.dart';
import '../../search/presentation/widgets/quick_sort_filter_sheet.dart';
import '../../../core/widgets/flux_icon.dart';
import '../../../core/widgets/file_type_icon.dart';
import '../../../core/providers/trash_provider.dart';
import '../../../../bridge/flux_bridge.dart';
import '../../../../core/utils/date_formatter.dart';

class AllFilesScreen extends ConsumerStatefulWidget {
  final String title;
  final String? category;
  const AllFilesScreen({Key? key, this.title = 'All Files', this.category})
    : super(key: key);

  @override
  ConsumerState<AllFilesScreen> createState() => _AllFilesScreenState();
}

class _AllFilesScreenState extends ConsumerState<AllFilesScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _searchScope = 'all'; // 'all', 'local', 'cloud'
  final TextEditingController _searchController = TextEditingController();
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

  Future<void> _deleteSelectedFiles(List<FluxFile> filesList) async {
    final selectedFiles = filesList.where((f) => _selectedFids.contains(f.fid)).toList();
    final fids = selectedFiles.map((f) => f.fid!).toList();
    if (fids.isEmpty) return;

    final success = await FluxBridge.executeBatchDelete(fids);
    if (success) {
      ref.read(trashProvider.notifier).refreshTrash();
      ref.read(allFilesProvider.notifier).refreshFiles();

      final fileNames = selectedFiles.map((f) => f.name).toList();
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
                ref.read(allFilesProvider.notifier).refreshFiles();
              }
            },
          ),
        ),
      );
    }
  }

  void _shareSelectedFiles(List<FluxFile> filesList) {
    final selectedPaths = filesList
        .where((f) => _selectedFids.contains(f.fid) && f.category != 'Directory')
        .map((f) => f.path)
        .toList();
    if (selectedPaths.isEmpty) return;
    
    FluxBridge.shareFiles(selectedPaths);
    setState(() {
      _isSelectionMode = false;
      _selectedFids.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _filterNotifier = ref.read(fileFilterProvider.notifier);
    if (widget.category != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _filterNotifier.setCategories({widget.category!});
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    Future.microtask(() {
      _filterNotifier.reset();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;
    final textColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark
        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
        : AppColors.neutral400;
    final iconColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Watch the unified sorted and filtered mixed files list (including search query)
    final allFiles = ref.watch(filteredFilesProvider(_searchQuery));

    // Filter by category if specified
    final List<FluxFile> realCategoryList = widget.category != null
        ? allFiles.where((f) => f.category == widget.category).toList()
        : allFiles;

    final List<FluxFile> categoryFilesList;
    if (widget.category != null && realCategoryList.isEmpty) {
      categoryFilesList = _getMockFilesForCategory(widget.category!, isDark);
    } else {
      categoryFilesList = realCategoryList;
    }

    // Apply search scope
    final List<FluxFile> filesList;
    if (_searchScope == 'local') {
      filesList = categoryFilesList
          .where((f) => f.location == 'Local')
          .toList();
    } else if (_searchScope == 'cloud') {
      filesList = categoryFilesList
          .where((f) => f.location == 'Cloud')
          .toList();
    } else {
      filesList = categoryFilesList;
    }

    final filterState = ref.watch(fileFilterProvider);

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
              _searchScope = 'all';
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
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
                      padding: EdgeInsets.fromLTRB(
                        16.0.w,
                        16.0.h,
                        20.0.w,
                        8.0.h,
                      ),
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
                                if (_selectedFids.length == filesList.length) {
                                  _selectedFids.clear();
                                  _isSelectionMode = false;
                                } else {
                                  _selectedFids.addAll(
                                    filesList.where((f) => f.fid != null).map((f) => f.fid!),
                                  );
                                }
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0.w),
                              child: Icon(
                                _selectedFids.length == filesList.length
                                    ? Icons.deselect_rounded
                                    : Icons.select_all_rounded,
                                size: 24.0.r,
                                color: iconColor,
                              ),
                            ),
                          ),
                          // Share Selected
                          GestureDetector(
                            onTap: () => _shareSelectedFiles(filesList),
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
                            onTap: () => _deleteSelectedFiles(filesList),
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
                          padding: EdgeInsets.fromLTRB(
                            16.0.w,
                            16.0.h,
                            20.0.w,
                            8.0.h,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSearching = false;
                                    _searchQuery = '';
                                    _searchScope = 'all';
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
                          padding: EdgeInsets.fromLTRB(
                            16.0.w,
                            16.0.h,
                            20.0.w,
                            8.0.h,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
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
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24.0.sp,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSearching = true;
                                    _searchScope = 'all';
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

            // macOS Finder style Scope Bar inside All Files Screen
            if (_isSearching)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0.w,
                  vertical: 8.0.h,
                ),
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
                      label: 'All Files',
                      isActive: _searchScope == 'all',
                      onTap: () {
                        setState(() {
                          _searchScope = 'all';
                        });
                      },
                      isDark: isDark,
                      borderColor: dividerColor,
                    ),
                    SizedBox(width: 8.0.w),
                    _buildScopePill(
                      label: 'Local Only',
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
                      label: 'Cloud Only',
                      isActive: _searchScope == 'cloud',
                      onTap: () {
                        setState(() {
                          _searchScope = 'cloud';
                        });
                      },
                      isDark: isDark,
                      borderColor: dividerColor,
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16.0.h),

            // Sorting/Filter Row
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.0.w,
                vertical: 8.0.h,
              ),
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
                  GestureDetector(
                    onTap: () {
                      QuickSortFilterSheet.show(context, hideFileType: false);
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
                ],
              ),
            ),
            SizedBox(height: 8.0.h),

            // Files List View
            Expanded(
              child: RefreshIndicator(
                color: AppColors.mintAccent,
                backgroundColor: isDark ? AppColors.neutral900 : Colors.white,
                onRefresh: () async {
                  ref.read(allFilesProvider.notifier).refreshFiles();
                },
                child: filesList.isEmpty
                    ? ListView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 80.0.h),
                            child: Center(
                              child: Text(
                                'No files found',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15.0.sp,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0.w,
                          vertical: 12.0.h,
                        ),
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        itemCount: filesList.length,
                        separatorBuilder: (context, index) => Divider(
                          color: dividerColor,
                          height: 1.0.h,
                          thickness: 1.0.r,
                        ),
                        itemBuilder: (context, index) {
                          final file = filesList[index];
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
                                FluxBridge.shareFiles([file.path]);
                                return false; // Do not dismiss the tile
                              }
                              return true; // Dismiss (delete)
                            },
                            onDismissed: (direction) async {
                              final fid = file.fid;
                              if (fid == null) return;
                              
                              final success = await FluxBridge.executeBatchDelete([fid]);
                              if (success) {
                                ref.read(trashProvider.notifier).refreshTrash();
                                ref.read(allFilesProvider.notifier).refreshFiles();
                                
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
                                          ref.read(allFilesProvider.notifier).refreshFiles();
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
                                    createdDate: DateFormatter.formatFriendly(file.modifiedDate),
                                    modifiedDate:
                                        '${file.modifiedDate.year}-${file.modifiedDate.month.toString().padLeft(2, '0')}-${file.modifiedDate.day.toString().padLeft(2, '0')}',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                      Icon(
                                        Icons.more_vert,
                                        size: 20.0.r,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    ),);
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

  List<FluxFile> _getMockFilesForCategory(String category, bool isDark) {
    final now = DateTime.now();
    if (category == 'Application') {
      return [
        FluxFile(
          name: 'WhatsApp_Messenger_v2.24.apk',
          path: '/storage/emulated/0/Download/WhatsApp_Messenger_v2.24.apk',
          category: 'Application',
          sizeString: '42.6 MB',
          sizeInMb: 42.6,
          modifiedDate: now.subtract(const Duration(days: 2)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF9013FE),
        ),
        FluxFile(
          name: 'Instagram_Lite_v398.apk',
          path: '/storage/emulated/0/Download/Instagram_Lite_v398.apk',
          category: 'Application',
          sizeString: '18.2 MB',
          sizeInMb: 18.2,
          modifiedDate: now.subtract(const Duration(days: 5)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF9013FE),
        ),
        FluxFile(
          name: 'Flux_File_Explorer_Beta.apk',
          path: '/storage/emulated/0/Download/Flux_File_Explorer_Beta.apk',
          category: 'Application',
          sizeString: '35.4 MB',
          sizeInMb: 35.4,
          modifiedDate: now.subtract(const Duration(hours: 4)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF9013FE),
        ),
        FluxFile(
          name: 'PUBG_Mobile_v3.2_Installer.apk',
          path: '/storage/emulated/0/Download/PUBG_Mobile_v3.2_Installer.apk',
          category: 'Application',
          sizeString: '890.5 MB',
          sizeInMb: 890.5,
          modifiedDate: now.subtract(const Duration(days: 12)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF9013FE),
        ),
      ];
    }
    if (category == 'Audio') {
      return [
        FluxFile(
          name: 'Blinding Lights - The Weeknd.mp3',
          path: '/storage/emulated/0/Music/Blinding Lights - The Weeknd.mp3',
          category: 'Audio',
          sizeString: '7.8 MB',
          sizeInMb: 7.8,
          modifiedDate: now.subtract(const Duration(days: 1)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF4A90E2),
        ),
        FluxFile(
          name: 'Stay - The Kid LAROI & Justin Bieber.mp3',
          path: '/storage/emulated/0/Music/Stay - The Kid LAROI & Justin Bieber.mp3',
          category: 'Audio',
          sizeString: '5.4 MB',
          sizeInMb: 5.4,
          modifiedDate: now.subtract(const Duration(days: 4)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF4A90E2),
        ),
        FluxFile(
          name: 'Lofi Chill Beats Vol.4.wav',
          path: '/storage/emulated/0/Music/Lofi Chill Beats Vol.4.wav',
          category: 'Audio',
          sizeString: '24.2 MB',
          sizeInMb: 24.2,
          modifiedDate: now.subtract(const Duration(days: 9)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF4A90E2),
        ),
        FluxFile(
          name: 'Voice Memo 042.m4a',
          path: '/storage/emulated/0/Recordings/Voice Memo 042.m4a',
          category: 'Audio',
          sizeString: '1.2 MB',
          sizeInMb: 1.2,
          modifiedDate: now.subtract(const Duration(hours: 18)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF4A90E2),
        ),
      ];
    }
    if (category == 'Bin') {
      return [
        FluxFile(
          name: 'unwanted_blurry_photo.jpg',
          path: '/storage/emulated/0/DCIM/Camera/unwanted_blurry_photo.jpg',
          category: 'Bin',
          sizeString: '3.4 MB',
          sizeInMb: 3.4,
          modifiedDate: now.subtract(const Duration(days: 1)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF607D8B),
        ),
        FluxFile(
          name: 'draft_report_v1_obsolete.docx',
          path: '/storage/emulated/0/Documents/draft_report_v1_obsolete.docx',
          category: 'Bin',
          sizeString: '1.2 MB',
          sizeInMb: 1.2,
          modifiedDate: now.subtract(const Duration(days: 3)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF607D8B),
        ),
        FluxFile(
          name: 'temp_log_9083.tmp',
          path: '/storage/emulated/0/Android/data/temp_log_9083.tmp',
          category: 'Bin',
          sizeString: '14.5 MB',
          sizeInMb: 14.5,
          modifiedDate: now.subtract(const Duration(days: 6)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF607D8B),
        ),
      ];
    }
    if (category == 'Games') {
      return [
        FluxFile(
          name: 'Asphalt_9_Asset_Pack.pak',
          path: '/storage/emulated/0/Android/obb/com.gameloft.android.ANMP.GloftA9HM/Asphalt_9_Asset_Pack.pak',
          category: 'Games',
          sizeString: '180.5 MB',
          sizeInMb: 180.5,
          modifiedDate: now.subtract(const Duration(days: 20)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF4CAF50),
        ),
        FluxFile(
          name: 'Minecraft_World_Save.dat',
          path: '/storage/emulated/0/games/com.mojang/minecraftWorlds/Minecraft_World_Save.dat',
          category: 'Games',
          sizeString: '45.2 MB',
          sizeInMb: 45.2,
          modifiedDate: now.subtract(const Duration(days: 3)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF4CAF50),
        ),
        FluxFile(
          name: 'Cyberpunk_Mobile_Cached_Data.obb',
          path: '/storage/emulated/0/Android/obb/com.cdpred.cyberpunk/Cyberpunk_Mobile_Cached_Data.obb',
          category: 'Games',
          sizeString: '45.3 MB',
          sizeInMb: 45.3,
          modifiedDate: now.subtract(const Duration(days: 15)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF4CAF50),
        ),
      ];
    }
    if (category == 'System') {
      return [
        FluxFile(
          name: 'android.boot.img',
          path: '/system/boot/android.boot.img',
          category: 'System',
          sizeString: '16.5 GB',
          sizeInMb: 16500.0,
          modifiedDate: now.subtract(const Duration(days: 40)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF9C27B0),
        ),
        FluxFile(
          name: 'system.img',
          path: '/system/partitions/system.img',
          category: 'System',
          sizeString: '12.2 GB',
          sizeInMb: 12200.0,
          modifiedDate: now.subtract(const Duration(days: 40)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF9C27B0),
        ),
        FluxFile(
          name: 'recovery.img',
          path: '/system/boot/recovery.img',
          category: 'System',
          sizeString: '4.8 GB',
          sizeInMb: 4800.0,
          modifiedDate: now.subtract(const Duration(days: 40)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF9C27B0),
        ),
        FluxFile(
          name: 'build.prop',
          path: '/system/build.prop',
          category: 'System',
          sizeString: '1.5 MB',
          sizeInMb: 1.5,
          modifiedDate: now.subtract(const Duration(days: 10)),
          isDuplicate: false,
          isVault: false,
          location: 'Local',
          themeColor: const Color(0xFF9C27B0),
        ),
      ];
    }
    return [];
  }
}
