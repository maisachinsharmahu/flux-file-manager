import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flux/bridge/flux_bridge.dart';
import 'package:flux/core/theme/app_colors.dart';
import 'package:flux/features/home/providers/copy_task_provider.dart';
import 'package:flux/core/utils/byte_formatter.dart';

class JunkCleanerScreen extends ConsumerStatefulWidget {
  const JunkCleanerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JunkCleanerScreen> createState() => _JunkCleanerScreenState();
}

class _JunkCleanerScreenState extends ConsumerState<JunkCleanerScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _junkFiles = [];
  bool _isLoading = true;
  bool _isCleaning = false;
  
  // Track selected categories
  final Map<String, bool> _selectedCategories = {
    'Cache/Temporary File': true,
    'WhatsApp Sent Copy': true,
    'Large Old Download': true,
  };

  // Expanded categories for file lists
  final Map<String, bool> _expandedCategories = {};

  late AnimationController _radialController;

  @override
  void initState() {
    super.initState();
    _radialController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadJunkFiles();
  }

  @override
  void dispose() {
    _radialController.dispose();
    super.dispose();
  }

  Future<void> _loadJunkFiles() async {
    setState(() {
      _isLoading = true;
      _radialController.repeat();
    });

    final files = await FluxBridge.scanJunkFiles();

    if (mounted) {
      setState(() {
        _junkFiles = files;
        _isLoading = false;
        _radialController.stop();
      });
    }
  }

  List<Map<String, dynamic>> _getItemsByCategory(String category) {
    return _junkFiles.where((f) => f['reason'] == category).toList();
  }

  int _getCategorySize(String category) {
    final items = _getItemsByCategory(category);
    return items.fold<int>(0, (sum, item) => sum + (item['size'] as num).toInt());
  }

  int _calculateTotalSelectedBytes() {
    var total = 0;
    _selectedCategories.forEach((category, isSelected) {
      if (isSelected) {
        total += _getCategorySize(category);
      }
    });
    return total;
  }

  List<int> _getSelectedFids() {
    final fids = <int>[];
    _selectedCategories.forEach((category, isSelected) {
      if (isSelected) {
        final items = _getItemsByCategory(category);
        for (final item in items) {
          fids.add((item['fid'] as num).toInt());
        }
      }
    });
    return fids;
  }

  Future<void> _cleanNow() async {
    final fids = _getSelectedFids();
    if (fids.isEmpty || _isCleaning) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            'Clean Junk Files?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Permanently delete the selected ${fids.length} junk items from storage? This action cannot be undone.',
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
                'Clean',
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

    setState(() => _isCleaning = true);

    // Launch progress overlay
    final taskId = ref.read(copyTaskProvider.notifier).startRealTask(
          GlobalTaskType.delete,
          fileCount: fids.length,
        );

    final success = await FluxBridge.deletePermanentlyWithProgress(
      fids,
      (progress) {
        ref.read(copyTaskProvider.notifier).updateProgress(progress, taskId);
      },
    );

    if (success) {
      ref.read(copyTaskProvider.notifier).completeTask(taskId);
      // Wait for progress overlay dismiss
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadJunkFiles();
    } else {
      ref.read(copyTaskProvider.notifier).failTask(taskId);
    }

    if (mounted) {
      setState(() => _isCleaning = false);
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

    final totalSelectedBytes = _calculateTotalSelectedBytes();
    final formattedBytes = ByteFormatter.format(totalSelectedBytes);

    // Define details for categories
    final List<Map<String, dynamic>> categoryMetadata = [
      {
        'key': 'Cache/Temporary File',
        'title': 'Cache & Temp Files',
        'desc': 'Temporary system cache, application logs, and .tmp entries.',
        'icon': Icons.cleaning_services_rounded,
        'color': Colors.blueAccent,
      },
      {
        'key': 'WhatsApp Sent Copy',
        'title': 'WhatsApp Sent Copies',
        'desc': 'Duplicate copies of media files inside WhatsApp Sent folder.',
        'icon': Icons.chat_bubble_outline_rounded,
        'color': Colors.greenAccent,
      },
      {
        'key': 'Large Old Download',
        'title': 'Large Old Downloads',
        'desc': 'Files in Downloads folder larger than 50MB and older than 30 days.',
        'icon': Icons.download_done_rounded,
        'color': Colors.amberAccent,
      },
    ];

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
          'Junk Cleaner',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: headerColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: _radialController,
                    child: Icon(
                      Icons.cached_rounded,
                      size: 64.r,
                      color: AppColors.mintAccent,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Scanning storage partitions...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            )
          else if (_junkFiles.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 64.r,
                    color: AppColors.mintAccent,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Your device is fully optimized!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: headerColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Zero cached logs or residual temporary files found.',
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
            ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
              children: [
                // Premium Reclaim Donut / Header area
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        formattedBytes,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 48.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.mintAccent,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Total Selected Reclaimable Size',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Category List
                ...categoryMetadata.map((cat) {
                  final key = cat['key'] as String;
                  final title = cat['title'] as String;
                  final desc = cat['desc'] as String;
                  final icon = cat['icon'] as IconData;
                  final color = cat['color'] as Color;

                  final items = _getItemsByCategory(key);
                  if (items.isEmpty) return const SizedBox.shrink();

                  final catSize = _getCategorySize(key);
                  final formattedCatSize = ByteFormatter.format(catSize);
                  final isSelected = _selectedCategories[key] ?? false;
                  final isExpanded = _expandedCategories[key] ?? false;

                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: borderColor, width: 1.2.r),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          leading: Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 22.r),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: headerColor,
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              desc,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.sp,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formattedCatSize,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: headerColor,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Checkbox(
                                activeColor: AppColors.mintAccent,
                                checkColor: Colors.black,
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCategories[key] = val ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Expandable details footer
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedCategories[key] = !isExpanded;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isExpanded ? 'Hide Details' : 'Show Details (${items.length} files)',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 14.r,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                )
                              ],
                            ),
                          ),
                        ),

                        if (isExpanded)
                          Container(
                            constraints: BoxConstraints(maxHeight: 200.h),
                            color: Colors.black26,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                final size = (item['size'] as num).toInt();
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    item['name'] as String? ?? '',
                                    style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  subtitle: Text(
                                    item['path'] as String? ?? '',
                                    style: TextStyle(fontSize: 10.sp, color: isDark ? Colors.white38 : Colors.black38),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    ByteFormatter.format(size),
                                    style: TextStyle(fontSize: 12.sp, color: headerColor),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),

          // Action button overlay
          if (!_isLoading && totalSelectedBytes > 0)
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 16.h,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _cleanNow,
                  child: Container(
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: AppColors.mintAccent,
                      borderRadius: BorderRadius.circular(26.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mintAccent.withValues(alpha: 0.3),
                          blurRadius: 16.r,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Clean Now ($formattedBytes)',
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
