import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/flux_icon.dart';
import 'widgets/storage_bar.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/recents_list.dart';
import 'widgets/downloads_grid.dart';
import 'widgets/smart_cards_list.dart';
import 'widgets/all_storage_section.dart';
import '../../../../core/providers/model_sync_provider.dart';
import '../../../../core/providers/platform_monitor_provider.dart';
import '../../../../core/providers/file_filter_provider.dart';
import '../../../../bridge/flux_bridge.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/copy_task_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Key _storageBarKey = UniqueKey();

  Future<void> _handleRefresh() async {
    // Simulate a network refresh delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        // Force StorageBar state reset so its entry capsule animation plays again
        _storageBarKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent, // Let main navigation radial glow backdrop show through
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.mintAccent,
          backgroundColor: isDark ? AppColors.neutral900 : Colors.white,
          displacement: 20.h,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.only(
              bottom: 120.0.h,
            ), // Spacing to prevent overlay collisions
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HomeSearchBar(),
                StorageBar(key: _storageBarKey),
                const RecentsList(),
                const DownloadsGrid(),
                const AllStorageSection(),
                const QuickAccessGrid(),
                const SmartCardsList(),
                SizedBox(height: 12.0.h),
                const _DevSimulationConsole(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final iconColor = isDark
        ? AppColors.textSecondaryLight
        : AppColors.neutral400;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.0.w, 16.0.h, 24.0.w, 8.0.h),
      child: GestureDetector(
        onTap: () {
          context.push('/search');
        },
        child: Hero(
          tag: 'search_bar_hero',
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26.0.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: Container(
                  height: 52.0.h,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(26.0.r),
                    border: Border.all(color: borderColor, width: 1.5.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14.0.w),
                  child: Row(
                    children: [
                      // Clickable Sidebar open Menu Icon on the Left
                      GestureDetector(
                        onTap: () {
                          Scaffold.of(context).openDrawer();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.menu_rounded,
                          color: iconColor,
                          size: 22.0.r,
                        ),
                      ),
                      SizedBox(width: 12.0.w),
                      // Search Label in the middle
                      Expanded(
                        child: Text(
                          'Search files, folders...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15.0.sp,
                            color: iconColor,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Search Icon on the Right
                      FluxIcon(
                        FluxIconType.searchOff,
                        color: iconColor,
                        size: 22.0.r,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DevSimulationConsole extends ConsumerStatefulWidget {
  const _DevSimulationConsole({Key? key}) : super(key: key);

  @override
  ConsumerState<_DevSimulationConsole> createState() => _DevSimulationConsoleState();
}

class _DevSimulationConsoleState extends ConsumerState<_DevSimulationConsole> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark
        ? AppColors.neutral900.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    final modelStatus = ref.watch(modelSyncProvider);
    final monitorState = ref.watch(platformMonitorProvider);
    final allFiles = ref.watch(allFilesProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 16.0.h),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20.0.r),
              border: Border.all(color: borderColor, width: 1.2.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            size: 18.0.r,
                            color: isDark ? AppColors.mintAccent : Colors.teal,
                          ),
                          SizedBox(width: 8.0.w),
                          Text(
                            'Platform Diagnostic & Model Panel',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.0.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20.0.r,
                        color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
                  SizedBox(height: 16.0.h),
                  const Divider(color: Colors.white12, height: 1),
                  SizedBox(height: 16.0.h),

                  // 1. Model Downloader Status Block
                  Text(
                    'ON-DEVICE SEMANTIC AI SETUP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.0.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                    ),
                  ),
                  SizedBox(height: 8.0.h),
                  Container(
                    padding: EdgeInsets.all(12.0.r),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12.0.r),
                      border: Border.all(color: borderColor, width: 1.0.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MiniLM-L6 (ONNX model)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.0.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                              ),
                            ),
                            _buildStateBadge(modelStatus.state),
                          ],
                        ),
                        SizedBox(height: 6.0.h),
                        Text(
                          modelStatus.statusText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.0.sp,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        if (modelStatus.state == ModelSyncState.downloading ||
                            modelStatus.state == ModelSyncState.indexing) ...[
                          SizedBox(height: 10.0.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0.r),
                            child: LinearProgressIndicator(
                              value: modelStatus.progress,
                              minHeight: 5.0.h,
                              backgroundColor: isDark ? Colors.white10 : Colors.black12,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintAccent),
                            ),
                          ),
                        ],
                        if (modelStatus.state == ModelSyncState.idle) ...[
                          SizedBox(height: 12.0.h),
                          GestureDetector(
                            onTap: () {
                              ref.read(modelSyncProvider.notifier).startDownload();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 10.0.h),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.mintAccent,
                                borderRadius: BorderRadius.circular(10.0.r),
                              ),
                              child: Text(
                                'Download Model & Generate Graph',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.0.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 18.0.h),

                  // 2. Control Testing Buttons
                  Text(
                    'TEST ACTIONS & DIAGNOSTICS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.0.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                    ),
                  ),
                  SizedBox(height: 8.0.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(allFilesProvider.notifier).initAndLoad();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.0.h),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10.0.r),
                            ),
                            child: Text(
                              'Re-scan Storage',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.0.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (allFiles.isEmpty) return;
                            
                            // Find first file that is not already deleted to simulate O(1) delete
                            final file = allFiles.first;
                            final fid = allFiles.length + 2; // Simulated target index
                            
                            ref.read(platformMonitorProvider.notifier).logAction(
                              'executeBatchDelete',
                              'PENDING',
                              'Executing O(1) batch logical deletion for: ${file.name}',
                            );
                            
                            final success = await FluxBridge.executeBatchDelete([fid]);
                            if (success) {
                              ref.read(platformMonitorProvider.notifier).logAction(
                                'executeBatchDelete',
                                'SUCCESS',
                                'Flipped deletion bit for FID $fid. Logged to WAL.',
                              );
                              // Refresh files list to reflect deletion
                              ref.read(allFilesProvider.notifier).refreshFiles();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.0.h),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10.0.r),
                            ),
                            child: Text(
                              'Tombstone Test File',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.0.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 18.0.h),

                  // 3. Platform Channels Monitor Block
                  Text(
                    'PLATFORM CHANNELS STATUS MONITOR',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.0.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                    ),
                  ),
                  SizedBox(height: 8.0.h),
                  Container(
                    height: 110.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black12 : Colors.black.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(12.0.r),
                      border: Border.all(color: borderColor, width: 1.0.r),
                    ),
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 8.0.h),
                      children: monitorState.channelStatuses.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12.0.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              _buildStatusTag(entry.value),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 18.0.h),

                  // 4. Live Platform Logs Console
                  Text(
                    'LIVE BRIDGE ACTIVITY LOGS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.0.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                    ),
                  ),
                  SizedBox(height: 8.0.h),
                  Container(
                    height: 120.h,
                    padding: EdgeInsets.all(8.0.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.8),
                      borderRadius: BorderRadius.circular(12.0.r),
                    ),
                    child: monitorState.logs.isEmpty
                        ? Center(
                            child: Text(
                              'No logs recorded.',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11.0.sp,
                                color: Colors.greenAccent,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: monitorState.logs.length,
                            itemBuilder: (context, index) {
                              final log = monitorState.logs[index];
                              Color statusColor;
                              if (log.status == 'SUCCESS') statusColor = Colors.greenAccent;
                              else if (log.status == 'PENDING') statusColor = Colors.orangeAccent;
                              else statusColor = Colors.redAccent;

                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.0.h),
                                child: Text(
                                  '[${log.timestamp}] [${log.channel}] [${log.status}]: ${log.details}',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 10.0.sp,
                                    color: statusColor,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateBadge(ModelSyncState state) {
    String text;
    Color color;
    if (state == ModelSyncState.idle) {
      text = 'NOT LOADED';
      color = Colors.grey;
    } else if (state == ModelSyncState.downloading) {
      text = 'DOWNLOADING';
      color = Colors.orangeAccent;
    } else if (state == ModelSyncState.indexing) {
      text = 'INDEXING GRAPH';
      color = Colors.blueAccent;
    } else {
      text = 'ACTIVE';
      color = AppColors.mintAccent;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 2.0.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.0.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.0.sp,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color color;
    if (status == 'SUCCESS') color = AppColors.mintAccent;
    else if (status == 'PENDING') color = Colors.orangeAccent;
    else if (status == 'ERROR') color = Colors.redAccent;
    else color = Colors.grey;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.0.w, vertical: 1.0.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.0.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 8.0.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

