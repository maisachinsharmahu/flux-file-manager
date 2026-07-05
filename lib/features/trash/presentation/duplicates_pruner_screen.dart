import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flux/bridge/flux_bridge.dart';
import 'package:flux/core/theme/app_colors.dart';
import 'package:flux/features/home/providers/copy_task_provider.dart';
import 'package:flux/core/utils/byte_formatter.dart';
import 'package:flux/core/utils/date_formatter.dart';
import 'package:flux/core/widgets/file_type_icon.dart';

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
    
    // Sort groups so that the largest total group size is shown first
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
      // Automatically apply CCleaner auto-select on start
      _autoSelectDuplicates();
    }
  }

  void _autoSelectDuplicates() {
    setState(() {
      _selectedFids.clear();
      for (final group in _duplicateGroups) {
        if (group.length > 1) {
          // Keep the first copy (original/oldest) unchecked
          // Check all subsequent copies (duplicates) for pruning
          for (var i = 1; i < group.length; i++) {
            final fid = (group[i]['fid'] as num).toInt();
            _selectedFids.add(fid);
          }
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

  int _calculateRecoverableBytes() {
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
      // Wait briefly for progress overlay completion animation
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadDuplicates();
    } else {
      ref.read(copyTaskProvider.notifier).failTask(taskId);
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
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

    final recoverableBytes = _calculateRecoverableBytes();
    final formattedBytes = ByteFormatter.format(recoverableBytes);

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral950 : AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: headerColor, size: 20.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Duplicate Files',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: headerColor,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _duplicateGroups.isNotEmpty)
            TextButton(
              onPressed: _autoSelectDuplicates,
              child: Text(
                'Auto-Select',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mintAccent,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.mintAccent))
          else if (_duplicateGroups.isEmpty)
            Center(
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
                    'No duplicates found!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: headerColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your storage is fully optimized.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.sp,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
              physics: const BouncingScrollPhysics(),
              itemCount: _duplicateGroups.length,
              itemBuilder: (context, index) {
                final group = _duplicateGroups[index];
                final firstItem = group.first;
                final totalGroupSize = group.fold<int>(0, (sum, item) => sum + (item['size'] as num).toInt());
                final formattedGroupSize = ByteFormatter.format(totalGroupSize);

                final name = firstItem['name']?.toString() ?? '';
                final ext = name.contains('.') ? name.split('.').last : 'other';

                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: borderColor, width: 1.2.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                        child: Row(
                          children: [
                            FileTypeIcon(
                              extension: ext,
                              path: firstItem['path']?.toString(),
                              size: 32.r,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: headerColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '${group.length} duplicates • Total: $formattedGroupSize',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.sp,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      // Duplicate Instances
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: group.length,
                        itemBuilder: (context, itemIndex) {
                          final item = group[itemIndex];
                          final fid = (item['fid'] as num).toInt();
                          final isSelected = _selectedFids.contains(fid);
                          final path = item['path'] as String? ?? '';
                          final isOriginal = itemIndex == 0;

                          return InkWell(
                            onTap: () => _toggleSelection(fid),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              child: Row(
                                children: [
                                  // Custom modern checkbox
                                  Container(
                                    width: 20.r,
                                    height: 20.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.mintAccent
                                            : (isDark ? Colors.white24 : Colors.black26),
                                        width: 1.5.r,
                                      ),
                                      color: isSelected
                                          ? AppColors.mintAccent
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 12.r,
                                            color: Colors.black,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 14.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          path,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12.sp,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          children: [
                                            if (isOriginal) ...[
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                decoration: BoxDecoration(
                                                  color: AppColors.mintAccent.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4.r),
                                                ),
                                                child: const Text(
                                                  'Original',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.mintAccent,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 6.w),
                                            ],
                                            Text(
                                              'Modified: ${DateFormatter.formatFriendly(DateTime.fromMillisecondsSinceEpoch((item['mtime'] as num).toInt() * 1000))}',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 10.sp,
                                                color: isDark ? Colors.white38 : Colors.black38,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          
          // Bottom action button overlay
          if (!_isLoading && _selectedFids.isNotEmpty)
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 16.h,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _pruneSelected,
                  child: Container(
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(26.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.3),
                          blurRadius: 16.r,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Prune Selected ($formattedBytes)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
