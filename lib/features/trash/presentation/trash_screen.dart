import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flux/features/home/providers/copy_task_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/trash_provider.dart';
import '../../../../core/widgets/file_type_icon.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<int> _selectedFids = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  void _showActionsDialog(TrashFluxFile file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            color: isDark ? const Color(0xF2121212) : const Color(0xF2FFFFFF),
            padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 34.0.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FileTypeIcon(
                      extension: file.fileExtension,
                      path: file.path,
                      size: 40.0.r,
                    ),
                    SizedBox(width: 14.0.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.0.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.pureWhite
                                  : AppColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.0.h),
                          Text(
                            file.sizeString,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.0.sp,
                              color: isDark
                                  ? AppColors.textSecondaryLight
                                  : AppColors.neutral400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.0.h),
                Divider(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.1),
                  height: 1.0.r,
                  thickness: 1.0.r,
                ),
                SizedBox(height: 16.0.h),
                ListTile(
                  leading: Icon(
                    Icons.settings_backup_restore_rounded,
                    color: AppColors.mintAccent,
                    size: 24.0.r,
                  ),
                  title: Text(
                    'Restore File',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15.0.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.pureWhite
                          : AppColors.neutral900,
                    ),
                  ),
                  subtitle: Text(
                    'Put file back in its original folder.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0.sp,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    Navigator.of(context).pop();
                    ref
                        .read(copyTaskProvider.notifier)
                        .startRealTask(GlobalTaskType.restore);
                    await ref.read(trashProvider.notifier).restoreFiles(
                      [file.fid],
                      onProgress: (p) => ref.read(copyTaskProvider.notifier).updateProgress(p),
                    );
                    ref.read(copyTaskProvider.notifier).completeTask();
                  },
                ),
                SizedBox(height: 8.0.h),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                    size: 24.0.r,
                  ),
                  title: Text(
                    'Delete Permanently',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15.0.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.pureWhite
                          : AppColors.neutral900,
                    ),
                  ),
                  subtitle: Text(
                    'Erase file from disk forever.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0.sp,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    Navigator.of(context).pop();
                    _confirmPermanentDelete([file.fid], file.name);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmPermanentDelete(List<int> fids, String displayName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0.r),
        ),
        title: Text(
          'Delete permanently?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.0.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete $displayName? This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.0.sp,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () async {
              Navigator.of(context).pop();
              ref
                  .read(copyTaskProvider.notifier)
                  .startRealTask(GlobalTaskType.delete);
              await ref.read(trashProvider.notifier).deletePermanently(
                fids,
                onProgress: (p) => ref.read(copyTaskProvider.notifier).updateProgress(p),
              );
              ref.read(copyTaskProvider.notifier).completeTask();
              setState(() {
                _isSelectionMode = false;
                _selectedFids.clear();
              });
            },
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
      ),
    );
  }

  void _confirmEmptyTrash(List<TrashFluxFile> files) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0.r),
        ),
        title: Text(
          'Empty Trash?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.0.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Permanently erase all ${files.length} items from disk? This cannot be undone.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.0.sp,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () async {
              Navigator.of(context).pop();
              final fids = files.map((f) => f.fid).toList();
              ref
                  .read(copyTaskProvider.notifier)
                  .startRealTask(GlobalTaskType.delete);
              await ref.read(trashProvider.notifier).deletePermanently(
                fids,
                onProgress: (p) => ref.read(copyTaskProvider.notifier).updateProgress(p),
              );
              ref.read(copyTaskProvider.notifier).completeTask();
            },
            child: const Text(
              'Empty All',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final trashFiles = ref.watch(trashProvider);
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
    final borderColor = dividerColor;

    return Scaffold(
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
                    // Header Bar
                    Padding(
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
                              if (_isSelectionMode) {
                                setState(() {
                                  _isSelectionMode = false;
                                  _selectedFids.clear();
                                });
                              } else {
                                context.pop();
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
                          Text(
                            _isSelectionMode
                                ? '${_selectedFids.length} Selected'
                                : 'Trash',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24.0.sp,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          if (trashFiles.isNotEmpty) ...[
                            if (!_isSelectionMode) ...[
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSelectionMode = true;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.0.w,
                                    vertical: 8.0.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16.0.r),
                                  ),
                                  child: Text(
                                    'Select',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.0.sp,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.0.w),
                              GestureDetector(
                                onTap: () => _confirmEmptyTrash(trashFiles),
                                child: Container(
                                  padding: EdgeInsets.all(8.0.r),
                                  child: Icon(
                                    Icons.delete_sweep_rounded,
                                    color: Colors.redAccent,
                                    size: 24.0.r,
                                  ),
                                ),
                              ),
                            ] else ...[
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_selectedFids.length ==
                                        trashFiles.length) {
                                      _selectedFids.clear();
                                      _isSelectionMode = false;
                                    } else {
                                      _selectedFids.addAll(
                                        trashFiles.map((f) => f.fid),
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.0.w,
                                    vertical: 8.0.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16.0.r),
                                  ),
                                  child: Text(
                                    _selectedFids.length == trashFiles.length
                                        ? 'Deselect All'
                                        : 'Select All',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.0.sp,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    // Info Bar
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0.w,
                        vertical: 8.0.h,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(12.0.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12.0.r),
                          border: Border.all(color: dividerColor, width: 1.0.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16.0.r,
                              color: subtitleColor,
                            ),
                            SizedBox(width: 8.0.w),
                            Expanded(
                              child: Text(
                                'Items in Trash are logically tombstoned. Restoring takes <2 ms.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.0.sp,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Files List
                    Expanded(
                      child: trashFiles.isEmpty
                          ? _buildEmptyState(isDark, textColor, subtitleColor)
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                24.0.w,
                                16.0.h,
                                24.0.w,
                                100.0.h,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: trashFiles.length,
                              separatorBuilder: (context, index) => Divider(
                                color: dividerColor,
                                height: 1.0.h,
                                thickness: 1.0.r,
                              ),
                              itemBuilder: (context, index) {
                                final file = trashFiles[index];
                                final isSelected = _selectedFids.contains(
                                  file.fid,
                                );

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleSelection(file.fid);
                                      } else {
                                        _showActionsDialog(file);
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_isSelectionMode) {
                                        setState(() {
                                          _isSelectionMode = true;
                                          _selectedFids.add(file.fid);
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12.0.r),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.0.h,
                                      ),
                                      child: Row(
                                        children: [
                                          if (_isSelectionMode) ...[
                                            Checkbox(
                                              value: isSelected,
                                              activeColor: AppColors.mintAccent,
                                              checkColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      4.0.r,
                                                    ),
                                              ),
                                              onChanged: (val) {
                                                _toggleSelection(file.fid);
                                              },
                                            ),
                                            SizedBox(width: 8.0.w),
                                          ],
                                          FileTypeIcon(
                                            extension: file.fileExtension,
                                            path: file.path,
                                            size: 40.0.r,
                                          ),
                                          SizedBox(width: 14.0.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  file.name,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 15.0.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4.0.h),
                                                Text(
                                                  '${file.sizeString} • Tombstoned',
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
                  ],
                ),

                // Selection Bottom Floating Bar
                if (_isSelectionMode && _selectedFids.isNotEmpty)
                  Positioned(
                    bottom: 24.0.h,
                    left: 24.0.w,
                    right: 24.0.w,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0.w,
                            vertical: 12.0.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.neutral900.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16.0.r),
                            border: Border.all(
                              color: borderColor,
                              width: 1.2.r,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedFids.length} selected',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.0.sp,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final selectedList = _selectedFids.toList();
                                      ref
                                          .read(copyTaskProvider.notifier)
                                          .startRealTask(GlobalTaskType.restore);
                                      await ref
                                          .read(trashProvider.notifier)
                                          .restoreFiles(
                                            selectedList,
                                            onProgress: (p) => ref.read(copyTaskProvider.notifier).updateProgress(p),
                                          );
                                      ref.read(copyTaskProvider.notifier).completeTask();
                                      setState(() {
                                        _isSelectionMode = false;
                                        _selectedFids.clear();
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.0.w,
                                        vertical: 8.0.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintAccent.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.0.r,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .settings_backup_restore_rounded,
                                            size: 16.0.r,
                                            color: AppColors.mintAccent,
                                          ),
                                          SizedBox(width: 6.0.w),
                                          const Text(
                                            'Restore',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: AppColors.mintAccent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.0.w),
                                  GestureDetector(
                                    onTap: () {
                                      _confirmPermanentDelete(
                                        _selectedFids.toList(),
                                        '${_selectedFids.length} files',
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.0.w,
                                        vertical: 8.0.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.0.r,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_forever_rounded,
                                            size: 16.0.r,
                                            color: Colors.redAccent,
                                          ),
                                          SizedBox(width: 6.0.w),
                                          const Text(
                                            'Delete',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.0.r),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 48.0.r,
              color: subtitleColor,
            ),
          ),
          SizedBox(height: 16.0.h),
          Text(
            'Trash is empty',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16.0.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: 6.0.h),
          Text(
            'Deleted files will appear here for recovery',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0.sp,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
