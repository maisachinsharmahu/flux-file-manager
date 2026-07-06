import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flux/bridge/flux_bridge.dart';
import 'package:flux/core/theme/app_colors.dart';
import 'package:flux/features/home/providers/copy_task_provider.dart';
import 'package:flux/core/utils/byte_formatter.dart';
import 'package:flux/core/widgets/file_type_icon.dart';
import 'package:go_router/go_router.dart';

class DuplicatesPrunerScreen extends ConsumerStatefulWidget {
  const DuplicatesPrunerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DuplicatesPrunerScreen> createState() => _DuplicatesPrunerScreenState();
}

class _DuplicatesPrunerScreenState extends ConsumerState<DuplicatesPrunerScreen> {
  List<List<Map<String, dynamic>>> _duplicateGroups = [];
  final Set<int> _selectedFids = {};
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadDuplicates();
  }

  Future<void> _loadDuplicates() async {
    setState(() => _isLoading = true);
    final groups = await FluxBridge.getDuplicateGroups();
    
    // Sort groups by total size
    groups.sort((a, b) {
      final aSize = a.fold<int>(0, (sum, item) => sum + (item['size'] as num).toInt());
      final bSize = b.fold<int>(0, (sum, item) => sum + (item['size'] as num).toInt());
      return bSize.compareTo(aSize);
    });

    if (mounted) {
      setState(() {
        _duplicateGroups = groups;
        _selectedFids.clear();
        _isLoading = false;
      });
      _autoSelectDuplicates();
    }
  }

  void _autoSelectDuplicates() {
    setState(() {
      _selectedFids.clear();
      for (final group in _duplicateGroups) {
        if (group.length > 1) {
          // Keep first copy unchecked (Original)
          // Select all other copies for pruning
          for (var i = 1; i < group.length; i++) {
            final fid = (group[i]['fid'] as num).toInt();
            _selectedFids.add(fid);
          }
        }
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final group in _duplicateGroups) {
        for (final item in group) {
          final fid = (item['fid'] as num).toInt();
          _selectedFids.add(fid);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedFids.clear();
    });
  }

  void _toggleGroupSelection(List<Map<String, dynamic>> group) {
    // Check if all items in this group are already selected (except the original)
    final fids = group.map((item) => (item['fid'] as num).toInt()).toList();
    final duplicateFids = fids.sublist(1);
    
    final allDuplicatesSelected = duplicateFids.every((fid) => _selectedFids.contains(fid));
    
    setState(() {
      if (allDuplicatesSelected) {
        // Deselect all duplicates in this group
        for (final fid in duplicateFids) {
          _selectedFids.remove(fid);
        }
      } else {
        // Select all duplicates in this group
        for (final fid in duplicateFids) {
          _selectedFids.add(fid);
        }
      }
    });
  }

  void _toggleSelection(int fid) {
    setState(() {
      if (_selectedFids.contains(fid)) {
        _selectedFids.remove(fid);
      } else {
        _selectedFids.add(fid);
      }
    });
  }

  int _calculateSelectedSize() {
    var totalBytes = 0;
    for (final group in _duplicateGroups) {
      for (final item in group) {
        final fid = (item['fid'] as num).toInt();
        if (_selectedFids.contains(fid)) {
          totalBytes += (item['size'] as num).toInt();
        }
      }
    }
    return totalBytes;
  }

  Future<void> _pruneSelected() async {
    if (_selectedFids.isEmpty || _isProcessing) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Prune Duplicates?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Permanently delete the selected ${_selectedFids.length} duplicate files from storage? This cannot be undone.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);

    // Launch progress overlay via copyTaskProvider
    final taskId = ref.read(copyTaskProvider.notifier).startRealTask(
          GlobalTaskType.delete,
          fileCount: _selectedFids.length,
        );

    final success = await FluxBridge.deletePermanentlyWithProgress(
      _selectedFids.toList(),
      (progress) {
        ref.read(copyTaskProvider.notifier).updateProgress(progress, taskId);
      },
    );

    if (success) {
      ref.read(copyTaskProvider.notifier).completeTask(taskId);
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadDuplicates();
    } else {
      ref.read(copyTaskProvider.notifier).failTask(taskId);
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildFileThumbnail(Map<String, dynamic> item, bool isOriginal, bool isSelected) {
    final name = item['name']?.toString() ?? '';
    final path = item['path']?.toString() ?? '';
    final ext = name.contains('.') ? name.split('.').last.toLowerCase().trim() : 'other';
    final isImage = const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);

    Widget innerWidget;
    if (isImage && path.isNotEmpty) {
      final file = File(path);
      innerWidget = Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 256,
        cacheHeight: 256,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: FileTypeIcon(extension: ext, path: path, size: 40.r),
          );
        },
      );
    } else {
      innerWidget = Center(
        child: FileTypeIcon(extension: ext, path: path, size: 40.r),
      );
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.mintAccent : Colors.transparent,
            width: 1.5.r,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Thumbnail image/icon
            Positioned.fill(child: innerWidget),

            // Top-left "✓ Original" label if it's the original file
            if (isOriginal)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.mintAccent,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 10.r, color: Colors.black),
                      SizedBox(width: 2.w),
                      Text(
                        'Best',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom-right checkbox overlay (only checkable for duplicates)
            if (!isOriginal)
              Positioned(
                bottom: 8.h,
                right: 8.w,
                child: Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.mintAccent : Colors.black45,
                    border: Border.all(
                      color: isSelected ? AppColors.mintAccent : Colors.white70,
                      width: 1.5.r,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 12.r, color: Colors.black)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final headerColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final cardBgColor = isDark
        ? AppColors.neutral900.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Deselect all vs Select all state
    final allSelected = _duplicateGroups.isNotEmpty &&
        _duplicateGroups.every((g) => g.sublist(1).every((item) => _selectedFids.contains((item['fid'] as num).toInt())));

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral950 : AppColors.neutral50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Nav Header Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.mintAccent, size: 18.r),
                        SizedBox(width: 4.w),
                        Text(
                          'Photo...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mintAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: allSelected ? _deselectAll : _selectAll,
                    child: Text(
                      allSelected ? 'Deselect all' : 'Select all',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mintAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Large Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Text(
                'Similar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  color: headerColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Main duplicates content area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.mintAccent))
                  : _duplicateGroups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 64.r,
                                color: AppColors.mintAccent.withValues(alpha: 0.5),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No duplicate photos found!',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: headerColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _duplicateGroups.length,
                          itemBuilder: (context, index) {
                            final group = _duplicateGroups[index];
                            final totalGroupSize = group.fold<int>(0, (sum, item) => sum + (item['size'] as num).toInt());
                            
                            // Check if all duplicates in this group are selected
                            final duplicateFids = group.sublist(1).map((item) => (item['fid'] as num).toInt());
                            final allGroupDuplicatesSelected = duplicateFids.every((fid) => _selectedFids.contains(fid));

                            return Container(
                              margin: EdgeInsets.only(bottom: 20.h),
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(color: borderColor, width: 1.2.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Top info row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Circle item count badge
                                      Container(
                                        width: 28.r,
                                        height: 28.r,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.black12,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${group.length}',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.bold,
                                            color: headerColor,
                                          ),
                                        ),
                                      ),
                                      // Select All/Deselect group duplicates button
                                      GestureDetector(
                                        onTap: () => _toggleGroupSelection(group),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white10 : Colors.black12,
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Text(
                                            allGroupDuplicatesSelected ? 'Deselect all' : 'Select all',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                              color: headerColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 14.h),

                                  // Grid layout for thumbnails
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10.w,
                                      mainAxisSpacing: 10.h,
                                    ),
                                    itemCount: group.length,
                                    itemBuilder: (context, itemIndex) {
                                      final item = group[itemIndex];
                                      final fid = (item['fid'] as num).toInt();
                                      final isOriginal = itemIndex == 0;
                                      final isSelected = _selectedFids.contains(fid);

                                      return GestureDetector(
                                        onTap: () {
                                          if (!isOriginal) {
                                            _toggleSelection(fid);
                                          }
                                        },
                                        child: _buildFileThumbnail(item, isOriginal, isSelected),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    'Group Size: ${ByteFormatter.format(totalGroupSize)}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.sp,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Bottom action layout
            if (!_isLoading && _duplicateGroups.isNotEmpty)
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral950 : AppColors.neutral50,
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1.0.r),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_selectedFids.length} photos ${ByteFormatter.format(_calculateSelectedSize())}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: _pruneSelected,
                      child: Container(
                        height: 54.h,
                        decoration: BoxDecoration(
                          color: AppColors.mintAccent,
                          borderRadius: BorderRadius.circular(27.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintAccent.withValues(alpha: 0.25),
                              blurRadius: 16.r,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Delete Selected',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
