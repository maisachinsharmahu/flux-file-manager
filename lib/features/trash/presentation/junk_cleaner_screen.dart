import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flux/bridge/flux_bridge.dart';
import 'package:flux/core/theme/app_colors.dart';
import 'package:flux/features/home/providers/copy_task_provider.dart';
import 'package:flux/features/home/providers/storage_status_provider.dart';
import 'package:flux/core/utils/byte_formatter.dart';
import 'package:go_router/go_router.dart';

class JunkCleanerScreen extends ConsumerStatefulWidget {
  const JunkCleanerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JunkCleanerScreen> createState() => _JunkCleanerScreenState();
}

class _JunkCleanerScreenState extends ConsumerState<JunkCleanerScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _junkFiles = [];
  bool _isLoading = true;
  bool _isCleaning = false;
  
  // Selected categories
  final Map<String, bool> _selectedCategories = {
    'Cache/Temporary File': true,
    'WhatsApp Sent Copy': true,
    'Large Old Download': true,
  };

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
      await Future.delayed(const Duration(milliseconds: 300));
      // Refresh storage states
      ref.invalidate(storageStatusProvider);
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

    // Storage Status values
    final storageState = ref.watch(storageStatusProvider);
    double usedPercent = 0.74; // Fallback 74%
    String usedStorageText = "86.3 / 128 GB";
    
    storageState.whenData((data) {
      final totalStorage = data['totalStorage'] as int? ?? 128 * 1000 * 1000 * 1000;
      final totalUsed = data['totalUsed'] as int? ?? 0;
      usedPercent = totalUsed / totalStorage;
      
      final usedGb = totalUsed / (1024 * 1024 * 1024);
      final totalGb = totalStorage / (1024 * 1024 * 1024);
      usedStorageText = "${usedGb.toStringAsFixed(1)} / ${totalGb.toStringAsFixed(0)} GB";
    });

    final totalSelectedBytes = _calculateTotalSelectedBytes();
    final formattedBytes = ByteFormatter.format(totalSelectedBytes);

    // Calculate dynamic carbon savings estimate (e.g. 0.94g of CO2 saved per MB of junk removed)
    final carbonSaveGrams = (totalSelectedBytes / (1024 * 1024)) * 0.94;
    final formattedCarbon = carbonSaveGrams > 1000 
        ? '${(carbonSaveGrams / 1000).toStringAsFixed(2)} kg' 
        : '${carbonSaveGrams.toStringAsFixed(2)} g';

    // Tool categories matching screen specs
    final List<Map<String, dynamic>> tools = [
      {
        'key': 'Cache/Temporary File',
        'title': 'Cache & Temp Files',
        'desc': '${_getItemsByCategory('Cache/Temporary File').length} logs & temporary caches',
        'size': _getCategorySize('Cache/Temporary File'),
        'icon': Icons.cleaning_services_rounded,
        'color': Colors.blueAccent,
        'route': null,
      },
      {
        'key': 'Photo Clean',
        'title': 'Photo Clean (Duplicates)',
        'desc': 'Duplicate content clusters',
        'size': _getCategorySize('Duplicate File'), // from index duplicate flag
        'icon': Icons.image_outlined,
        'color': Colors.orangeAccent,
        'route': '/duplicates',
      },
      {
        'key': 'WhatsApp Sent Copy',
        'title': 'WhatsApp Sent Copies',
        'desc': '${_getItemsByCategory('WhatsApp Sent Copy').length} redundant sent media items',
        'size': _getCategorySize('WhatsApp Sent Copy'),
        'icon': Icons.chat_bubble_outline_rounded,
        'color': Colors.greenAccent,
        'route': null,
      },
      {
        'key': 'Large Old Download',
        'title': 'Large Old Downloads',
        'desc': '${_getItemsByCategory('Large Old Download').length} old downloads (>30 days)',
        'size': _getCategorySize('Large Old Download'),
        'icon': Icons.download_done_rounded,
        'color': Colors.amberAccent,
        'route': null,
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutral950 : AppColors.neutral50,
      body: SafeArea(
        child: _isLoading
            ? Center(
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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row Actions
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: Icon(
                            Icons.settings_outlined,
                            size: 24.r,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_outlined, color: Colors.amber, size: 12.r),
                              SizedBox(width: 4.w),
                              Text(
                                'PRO',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top stats labels
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total save $formattedBytes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: headerColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Total CO₂ save $formattedCarbon',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Storage Circular usage card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(28.r),
                        border: Border.all(color: borderColor, width: 1.2.r),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Circular usage
                              Container(
                                width: 90.r,
                                height: 90.r,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 90.r,
                                      height: 90.r,
                                      child: CircularProgressIndicator(
                                        value: usedPercent,
                                        strokeWidth: 9.r,
                                        backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                        color: AppColors.mintAccent,
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'USING',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? Colors.white38 : Colors.black38,
                                          ),
                                        ),
                                        Text(
                                          '${(usedPercent * 100).round()}%',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w900,
                                            color: headerColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 24.w),

                              // Text values & button
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Storage Used:',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      usedStorageText,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w900,
                                        color: headerColor,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          
                          // Quick Clean button inside card
                          GestureDetector(
                            onTap: _cleanNow,
                            child: Container(
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: AppColors.mintAccent,
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Quick Clean',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16.r),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tool Section Indicators
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOOLS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white38 : Colors.black38,
                            letterSpacing: 1.w,
                          ),
                        ),
                        Text(
                          'WILL SAVE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white38 : Colors.black38,
                            letterSpacing: 1.w,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tools Category List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      itemCount: tools.length,
                      itemBuilder: (context, index) {
                        final tool = tools[index];
                        final String key = tool['key'] as String;
                        final String title = tool['title'] as String;
                        final String desc = tool['desc'] as String;
                        final int size = tool['size'] as int;
                        final IconData icon = tool['icon'] as IconData;
                        final Color color = tool['color'] as Color;
                        final String? route = tool['route'] as String?;
                        
                        // Fallback check state
                        final isSelected = _selectedCategories[key] ?? false;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: borderColor, width: 1.2.r),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                            onTap: () {
                              if (route != null) {
                                context.push(route);
                              } else {
                                // Toggle category selection state
                                setState(() {
                                  _selectedCategories[key] = !isSelected;
                                });
                              }
                            },
                            leading: Container(
                              width: 40.r,
                              height: 40.r,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(icon, color: color, size: 20.r),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: headerColor,
                              ),
                            ),
                            subtitle: Text(
                              desc,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.sp,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ByteFormatter.format(size),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.mintAccent,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                if (route != null)
                                  Icon(Icons.arrow_forward_ios_rounded, size: 12.r, color: isDark ? Colors.white24 : Colors.black26)
                                else
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
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
