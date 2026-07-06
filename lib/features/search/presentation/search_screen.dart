import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_state_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/file_filter_provider.dart';
import 'widgets/quick_sort_filter_sheet.dart';
import '../../home/presentation/widgets/file_detail_sheet.dart';
import '../../../core/widgets/flux_icon.dart';
import '../../../core/widgets/file_type_icon.dart';
import '../../../../core/utils/date_formatter.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Auto-focus search field on transition end and start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = ref.watch(searchStateProvider);
    final history = ref.watch(searchHistoryProvider);

    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subColor = isDark
        ? AppColors.textSecondaryLight
        : AppColors.neutral400;

    // Sync input field value if query is set by selecting from history
    if (query != _searchController.text) {
      _searchController.text = query;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: query.length),
      );
    }

    // Watch the active filtered files list from our provider
    final filteredFiles = ref.watch(filteredFilesProvider(query));
    final filterState = ref.watch(fileFilterProvider);

    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;

    return Scaffold(
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            color: bgColor,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Search Row
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0.w,
                      vertical: 12.0.h,
                    ),
                    child: Row(
                      children: [
                        // Back Circle Icon Button
                        GestureDetector(
                          onTap: () {
                            context.pop();
                          },
                          child: Container(
                            width: 44.0.w,
                            height: 44.0.h,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                width: 1.0.r,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: isDark
                                  ? AppColors.pureWhite
                                  : AppColors.neutral900,
                              size: 20.0.r,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.0.w),

                        // Search Input Field Container
                        Expanded(
                          child: Container(
                            height: 48.0.h,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(24.0.r),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                width: 1.0.r,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.black38,
                                  size: 20.0.r,
                                ),
                                SizedBox(width: 10.0.w),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _focusNode,
                                    onChanged: (val) {
                                      ref
                                              .read(
                                                searchStateProvider.notifier,
                                              )
                                              .state =
                                          val;
                                    },
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        ref
                                            .read(
                                              searchHistoryProvider.notifier,
                                            )
                                            .add(val);
                                      }
                                    },
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15.0.sp,
                                      color: isDark
                                          ? AppColors.pureWhite
                                          : AppColors.neutral900,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search',
                                      hintStyle: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15.0.sp,
                                        color: isDark
                                            ? Colors.white30
                                            : Colors.black38,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (query.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      ref
                                              .read(
                                                searchStateProvider.notifier,
                                              )
                                              .state =
                                          '';
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      size: 18.0.r,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    height: 1.0.h,
                    thickness: 1.0.r,
                  ),

                  // Expanded results / history area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.0.w,
                        vertical: 16.0.h,
                      ),
                      child: query.isEmpty
                          ? _buildSearchHistoryState(
                              isDark,
                              titleColor,
                              subColor,
                              history,
                            )
                          : _buildResultsState(
                              isDark,
                              titleColor,
                              subColor,
                              filteredFiles,
                              filterState,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHistoryState(
    bool isDark,
    Color titleColor,
    Color subColor,
    List<String> history,
  ) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 80.0.h),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48.0.r,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              SizedBox(height: 16.0.h),
              Text(
                'Type query to search files...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.0.sp,
                  color: subColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Search',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15.0.sp,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(searchHistoryProvider.notifier).clear();
              },
              child: Text(
                'Clear History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.0.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mintAccent,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.0.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final queryText = history[index];
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0.h),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: isDark ? Colors.white30 : Colors.black38,
                    size: 20.0.r,
                  ),
                  SizedBox(width: 14.0.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(searchStateProvider.notifier).state =
                            queryText;
                      },
                      child: Text(
                        queryText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.0.sp,
                          color: titleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(searchHistoryProvider.notifier)
                          .remove(queryText);
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white30 : Colors.black38,
                      size: 18.0.r,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResultsState(
    bool isDark,
    Color titleColor,
    Color subColor,
    List<FluxFile> files,
    FileFilterState filterState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search Results (${ref.watch(searchLatencyProvider).toStringAsFixed(3)} ms)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15.0.sp,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            Row(
              children: [
                // Advanced Filters Tune Button
                GestureDetector(
                  onTap: () {
                    QuickSortFilterSheet.show(context);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: filterState.activeFiltersCount > 0
                            ? AppColors.mintAccent
                            : (isDark
                                  ? AppColors.pureWhite
                                  : AppColors.neutral900),
                        size: 20.0.r,
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
                SizedBox(width: 14.0.w),
                Icon(
                  Icons.view_headline_rounded,
                  color: isDark ? AppColors.pureWhite : AppColors.neutral900,
                  size: 20.0.r,
                ),
              ],
            ),
          ],
        ),
        if (files.isNotEmpty) ...[
          SizedBox(height: 12.0.h),
          SizedBox(
            height: 38.0.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: files.length > 5 ? 5 : files.length,
              itemBuilder: (context, index) {
                final fName = files[index].name;
                return Padding(
                  padding: EdgeInsets.only(right: 8.0.w),
                  child: ActionChip(
                    label: Text(
                      fName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0.sp,
                        color: isDark ? AppColors.mintAccent : AppColors.neutral900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: isDark
                        ? AppColors.mintAccent.withValues(alpha: 0.08)
                        : AppColors.neutral100,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.mintAccent.withValues(alpha: 0.15)
                          : AppColors.neutral200,
                      width: 1.0.r,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 4.0.w),
                    onPressed: () {
                      _searchController.text = fName;
                      ref.read(searchStateProvider.notifier).state = fName;
                    },
                  ),
                );
              },
            ),
          ),
        ],
        SizedBox(height: 16.0.h),
        if (files.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.0.h),
              child: Text(
                'No matching files found.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0.sp,
                  color: subColor,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];

              return GestureDetector(
                onTap: () {
                  context.push('/viewer?path=${Uri.encodeQueryComponent(file.path)}');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0.h),
                  child: Row(
                    children: [
                      // Document Icon
                      FileTypeIcon(extension: file.fileExtension, size: 44.0.r),
                      SizedBox(width: 14.0.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.0.sp,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.0.h),
                            Text(
                              '${file.sizeString} | ${file.location}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.0.sp,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
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
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(8.0.r),
                          child: Icon(
                            Icons.more_vert,
                            color: isDark
                                ? AppColors.textSecondaryLight
                                : AppColors.neutral400,
                            size: 20.0.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
