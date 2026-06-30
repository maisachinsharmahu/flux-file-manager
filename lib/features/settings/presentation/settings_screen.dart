import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/providers/navigation_provider.dart';
import '../../../bridge/flux_bridge.dart';
import '../../../core/providers/file_filter_provider.dart'; // to reload index after generation/clear!

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  bool _isGenerating = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateTestFiles() async {
    setState(() {
      _isGenerating = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0.r)),
          title: Row(
            children: [
              SizedBox(
                width: 24.0.r,
                height: 24.0.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              SizedBox(width: 16.0.w),
              Expanded(
                child: Text(
                  'Generating Files...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.0.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Creating 1,000,000 unique dummy files (~25 GB) in the app sandbox. This will take ~45-60 seconds. Progress logs are streaming in Android Debug Console.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0.sp,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );

    final result = await FluxBridge.generateTestFiles(count: 1000000, targetSizeGb: 25.0);
    
    if (mounted) {
      Navigator.of(context).pop(); // dismiss loading dialog
      setState(() {
        _isGenerating = false;
      });

      if (result != null) {
        // Trigger a force reload of all files inside index so we pick them up instantly!
        ref.read(allFilesProvider.notifier).initAndLoad(force: true);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0.r)),
            title: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 28.0.r),
                SizedBox(width: 12.0.w),
                Text(
                  'Generation Successful',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.0.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            content: Text(
              'Successfully generated ${result["filesCreated"]} dummy files inside sandbox in ${result["durationSeconds"].toStringAsFixed(1)} seconds.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0.sp,
                color: Colors.white70,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0.r)),
            title: const Text('Generation Failed', style: TextStyle(color: Colors.white)),
            content: const Text('An error occurred during file generation. Please verify device disk space.', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.amber)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleClearTestFiles() async {
    setState(() {
      _isClearing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0.r)),
          title: Row(
            children: [
              SizedBox(
                width: 24.0.r,
                height: 24.0.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                ),
              ),
              SizedBox(width: 16.0.w),
              Expanded(
                child: Text(
                  'Clearing Dummy Files...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.0.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Recursively deleting dummy files to restore storage space. Please wait...',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );

    final deletedCount = await FluxBridge.clearTestFiles();

    if (mounted) {
      Navigator.of(context).pop(); // dismiss loading dialog
      setState(() {
        _isClearing = false;
      });

      // Force refresh the index so the items are cleared immediately
      ref.read(allFilesProvider.notifier).initAndLoad(force: true);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0.r)),
          title: Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28.0.r),
              SizedBox(width: 12.0.w),
              Text(
                'Cleanup Successful',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.0.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'Successfully deleted $deletedCount dummy files from app sandbox.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0.sp,
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text('Settings'),
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 12.0.h),
            children: [
              // System Settings Section
              _buildSectionHeader('SYSTEM SETTINGS'),
              Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
                child: Column(
                  children: [
                    const ListTile(
                      title: Text('Thermal Governor Throttling', style: TextStyle(color: Colors.white)),
                      trailing: Icon(Icons.toggle_on_outlined, color: Colors.amber),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    const ListTile(
                      title: Text('Embeddings Generation', style: TextStyle(color: Colors.white)),
                      trailing: Icon(Icons.toggle_off_outlined, color: Colors.white30),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.0.h),

              // Benchmarking / Dev tools Section
              _buildSectionHeader('DEVELOPER & BENCHMARK TOOLS'),
              Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
                child: Column(
                  children: [
                    ListTile(
                      enabled: !_isGenerating && !_isClearing,
                      leading: const Icon(Icons.speed_rounded, color: Colors.amber),
                      title: const Text('Generate 1,000,000 Files', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                        'Populates sandbox with 1 million unique files (~25 GB) distributed across all categories for performance testing.',
                        style: TextStyle(color: Colors.white54, fontSize: 11.0),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                      onTap: _handleGenerateTestFiles,
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    ListTile(
                      enabled: !_isGenerating && !_isClearing,
                      leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                      title: const Text('Clear Generated Test Files', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                        'Recursively sweeps and clears all test_file_* logs to free up storage space instantly.',
                        style: TextStyle(color: Colors.white54, fontSize: 11.0),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                      onTap: _handleClearTestFiles,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.0.w, bottom: 8.0.h),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.0.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
