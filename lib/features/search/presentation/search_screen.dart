import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_state_provider.dart';
import '../../../core/theme/app_colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;

  // Mock list of files representing query matches in layouts
  final List<Map<String, String>> _mockFiles = [
    {
      'name': 'Employment Contract.docx',
      'date': 'January 15, 2023',
      'size': '560 KB',
    },
    {
      'name': 'Partnership Agreement.doc',
      'date': 'March 28, 2022',
      'size': '2.5 MB',
    },
    {
      'name': 'Agreement Contract.pdf',
      'date': 'June 5, 2023',
      'size': '793 KB',
    },
    {
      'name': 'Employment Contract.pdf',
      'date': 'August 10, 2022',
      'size': '793 KB',
    },
    {
      'name': 'Licensing Agreement.docx',
      'date': 'February 7, 2023',
      'size': '793 KB',
    },
    {
      'name': 'Service Agreement Contract.pdf',
      'date': 'November 20, 2022',
      'size': '912 KB',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
    
    // Auto-focus search field on transition end
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = ref.watch(searchStateProvider);
    final history = ref.watch(searchHistoryProvider);

    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subColor = isDark ? AppColors.textSecondaryLight : AppColors.neutral400;

    // Sync input field value if query is set by selecting from history
    if (query != _searchController.text) {
      _searchController.text = query;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: query.length),
      );
    }

    // Filtered list based on text match
    final filteredFiles = _mockFiles.where((file) {
      final name = file['name']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();

    final bgGradient = isDark
        ? const RadialGradient(
            center: Alignment(0.0, -1.2),
            radius: 1.4,
            colors: [
              AppColors.indigoHaze,
              AppColors.pureBlack,
            ],
          )
        : const RadialGradient(
            center: Alignment(0.0, -1.2),
            radius: 1.4,
            colors: [
              AppColors.lightHaze,
              AppColors.pureWhite,
            ],
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation Search Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 12.0.h),
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
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.neutral900 : AppColors.neutral100,
                          border: Border.all(
                            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                            width: 1.0.r,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: isDark ? AppColors.neutral50 : AppColors.neutral900,
                          size: 20.0.r,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.0.w),
                    // Input Bar wrapped in Hero tag 'search_bar_hero'
                    Expanded(
                      child: Hero(
                        tag: 'search_bar_hero',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            height: 48.0.h,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.neutral900 : AppColors.neutral100,
                              borderRadius: BorderRadius.circular(24.0.r),
                              border: Border.all(
                                color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                                width: 1.0.r,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                                  size: 20.0.r,
                                ),
                                SizedBox(width: 10.0.w),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _focusNode,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.0.sp,
                                      color: isDark ? AppColors.neutral50 : AppColors.neutral900,
                                      decoration: TextDecoration.none,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search',
                                      hintStyle: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14.0.sp,
                                        color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      ref.read(searchStateProvider.notifier).state = val;
                                    },
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        ref.read(searchHistoryProvider.notifier).add(val.trim());
                                      }
                                    },
                                  ),
                                ),
                                if (query.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      ref.read(searchStateProvider.notifier).state = '';
                                    },
                                    child: Icon(
                                      Icons.close,
                                      color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                                      size: 18.0.r,
                                    ),
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

              // Dynamic Body switching states
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 12.0.h),
                  child: query.isEmpty
                      ? _buildHistoryState(ref, isDark, titleColor, history)
                      : _buildResultsState(isDark, titleColor, subColor, filteredFiles),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryState(WidgetRef ref, bool isDark, Color titleColor, List<String> history) {
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
            if (history.isNotEmpty)
              GestureDetector(
                onTap: () {
                  ref.read(searchHistoryProvider.notifier).clear();
                },
                child: Text(
                  'Clear History',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.0.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.actionBlue,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.0.h),
        if (history.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40.0.h),
              child: Text(
                'No recent searches.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0.sp,
                  color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                      size: 20.0.r,
                    ),
                    SizedBox(width: 14.0.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(searchStateProvider.notifier).state = item;
                          ref.read(searchHistoryProvider.notifier).add(item);
                        },
                        child: Text(
                          item,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.0.sp,
                            fontWeight: FontWeight.w400,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(searchHistoryProvider.notifier).remove(item);
                      },
                      child: Icon(
                        Icons.close,
                        color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                        size: 16.0.r,
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

  Widget _buildResultsState(bool isDark, Color titleColor, Color subColor, List<Map<String, String>> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search Results',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15.0.sp,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: isDark ? AppColors.neutral50 : AppColors.neutral900,
                  size: 20.0.r,
                ),
                SizedBox(width: 12.0.w),
                Icon(
                  Icons.view_headline,
                  color: isDark ? AppColors.neutral50 : AppColors.neutral900,
                  size: 20.0.r,
                ),
              ],
            ),
          ],
        ),
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
              final fileName = file['name'] ?? '';
              final fileDate = file['date'] ?? '';
              final fileSize = file['size'] ?? '';

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0.h),
                child: Row(
                  children: [
                    // Document Icon (Yellow/Amber container matching design reference folders)
                    Container(
                      width: 44.0.w,
                      height: 44.0.h,
                      decoration: BoxDecoration(
                        color: AppColors.amberAccent,
                        borderRadius: BorderRadius.circular(12.0.r),
                        border: Border.all(
                          color: AppColors.amberBorder,
                          width: 1.0.r,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.insert_drive_file_outlined,
                          color: AppColors.amberIcon,
                          size: 22.0.r,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.0.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
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
                            '$fileDate | $fileSize',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.0.sp,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      color: isDark ? AppColors.textSecondaryLight : AppColors.neutral400,
                      size: 20.0.r,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
