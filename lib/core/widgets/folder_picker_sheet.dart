import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../bridge/flux_bridge.dart';
import '../theme/app_colors.dart';

/// A bottom sheet that lets the user pick a destination folder.
/// Starts at `/storage/emulated/0` (Internal Storage).
/// Shows only directories; navigable with a breadcrumb trail.
/// Returns the chosen absolute path via [Navigator.pop].
class FolderPickerSheet extends StatefulWidget {
  final String title;
  final Set<int> sourceFids;

  const FolderPickerSheet({
    Key? key,
    required this.title,
    this.sourceFids = const {},
  }) : super(key: key);

  static Future<String?> show(
    BuildContext context, {
    required String title,
    Set<int> sourceFids = const {},
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FolderPickerSheet(title: title, sourceFids: sourceFids),
    );
  }

  @override
  State<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<FolderPickerSheet> {
  static const _root = '/storage/emulated/0';

  String _currentPath = _root;
  final List<String> _pathHistory = [];
  List<dynamic> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders(_currentPath);
  }

  Future<void> _loadFolders(String path) async {
    setState(() => _isLoading = true);
    final contents = await FluxBridge.getDirectoryContents(path);
    final dirs = contents.where((item) {
      final cat = item['category'] as String? ?? '';
      return cat == 'Directory';
    }).toList();
    if (mounted) {
      setState(() {
        _currentPath = path;
        _folders = dirs;
        _isLoading = false;
      });
    }
  }

  void _navigateInto(String path) {
    _pathHistory.add(_currentPath);
    _loadFolders(path);
  }

  void _navigateBack() {
    if (_pathHistory.isNotEmpty) {
      _loadFolders(_pathHistory.removeLast());
    }
  }

  String get _displayPath =>
      _currentPath.replaceAll('/storage/emulated/0', 'Internal Storage');

  List<String> get _breadcrumbs {
    final stripped = _currentPath.replaceFirst('/storage/emulated/0', '');
    if (stripped.isEmpty) return ['Internal Storage'];
    return ['Internal Storage', ...stripped.split('/').where((s) => s.isNotEmpty)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.neutral950 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;
    final dividerColor = isDark ? Colors.white10 : const Color(0x14000000);
    final canGoBack = _pathHistory.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            border: Border(
              top: BorderSide(color: isDark ? Colors.white12 : const Color(0x1A000000)),
              left: BorderSide(color: isDark ? const Color(0x14FFFFFF) : const Color(0x0A000000)),
              right: BorderSide(color: isDark ? const Color(0x14FFFFFF) : const Color(0x0A000000)),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(top: 10.h, bottom: 4.h),
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: subtitleColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              // ── Header ─────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 16.w, 4.h),
                child: Row(
                  children: [
                    if (canGoBack)
                      GestureDetector(
                        onTap: _navigateBack,
                        child: Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18.r,
                            color: textColor,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // Breadcrumb trail
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _breadcrumbs.asMap().entries.map((entry) {
                                final isLast = entry.key == _breadcrumbs.length - 1;
                                return Row(
                                  children: [
                                    if (entry.key > 0)
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          size: 12.r,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11.sp,
                                        fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                                        color: isLast ? AppColors.mintAccent : subtitleColor,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close_rounded, size: 22.r, color: subtitleColor),
                    ),
                  ],
                ),
              ),

              Divider(color: dividerColor, height: 1),

              // ── Folder list ────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? Center(
                        child: SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.mintAccent,
                          ),
                        ),
                      )
                    : _folders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_off_outlined,
                                    size: 40.r, color: subtitleColor),
                                SizedBox(height: 8.h),
                                Text(
                                  'No subfolders here',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.sp,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _folders.length,
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            itemBuilder: (context, index) {
                              final item = _folders[index] as Map;
                              final name = item['name'] as String? ?? '';
                              final path = item['path'] as String? ?? '';
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 2.h),
                                leading: Icon(
                                  Icons.folder_rounded,
                                  color: AppColors.mintAccent,
                                  size: 22.r,
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18.r,
                                  color: subtitleColor,
                                ),
                                onTap: () => _navigateInto(path),
                              );
                            },
                          ),
              ),

              // ── Paste here button ──────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _currentPath),
                      icon: Icon(Icons.check_rounded, size: 20.r),
                      label: Text(
                        'Select: $_displayPath',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
