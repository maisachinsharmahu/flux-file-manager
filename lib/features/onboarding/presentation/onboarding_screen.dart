import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.pureBlack : AppColors.pureWhite;
    final titleColor = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top progress indicators
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 16.0.h),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index == _currentPage;
                  return Expanded(
                    child: Container(
                      height: 4.0.h,
                      margin: EdgeInsets.symmetric(horizontal: 4.0.w),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.mintAccent
                            : (isDark ? AppColors.neutral800 : AppColors.neutral200),
                        borderRadius: BorderRadius.circular(2.0.r),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 2. Slidable Onboarding Content (PageView)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _OnboardingPage(
                    illustration: const _SearchIllustration(),
                    title: 'Lightning Fast Search',
                    description: 'Find any file instantly. Start typing and watch results appear in the blink of an eye, even if you have thousands of files.',
                    titleColor: titleColor,
                    descriptionColor: subtitleColor,
                  ),
                  _OnboardingPage(
                    illustration: const _SemanticAIIllustration(),
                    title: 'Smart AI Assistant',
                    description: 'Search for files by what they mean. Type "tax notes" to find files named Form16 or Receipts. Completely offline and private.',
                    titleColor: titleColor,
                    descriptionColor: subtitleColor,
                  ),
                  _OnboardingPage(
                    illustration: const _SyncIllustration(),
                    title: 'Always Up to Date',
                    description: 'Never see deleted or missing files again. Your list updates instantly when you add or remove files in any other app.',
                    titleColor: titleColor,
                    descriptionColor: subtitleColor,
                  ),
                ],
              ),
            ),

            // 3. Navigation Controls
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 24.0.h),
              child: _currentPage == 2
                  ? SizedBox(
                      width: double.infinity,
                      height: 52.0.h,
                      child: ElevatedButton(
                        onPressed: () => context.go('/'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mintAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26.0.r),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.0.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : (_currentPage == 0
                      ? SizedBox(
                          width: double.infinity,
                          height: 52.0.h,
                          child: ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mintAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26.0.r)),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15.0.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52.0.h,
                                child: OutlinedButton(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                                      width: 1.0.r,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26.0.r),
                                    ),
                                    foregroundColor: isDark ? AppColors.pureWhite : AppColors.neutral900,
                                  ),
                                  child: Text(
                                    'Previous',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15.0.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.0.w),
                            Expanded(
                              child: SizedBox(
                                height: 52.0.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mintAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26.0.r),
                                    ),
                                  ),
                                  child: Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15.0.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;
  final Color titleColor;
  final Color descriptionColor;

  const _OnboardingPage({
    Key? key,
    required this.illustration,
    required this.title,
    required this.description,
    required this.titleColor,
    required this.descriptionColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic Box
          Expanded(
            flex: 3,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.1,
                child: illustration,
              ),
            ),
          ),
          SizedBox(height: 32.0.h),
          // Typography
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24.0.sp,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0.h),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0.sp,
                    height: 1.5,
                    color: descriptionColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Custom code-only illustrations matching screenshots
// ----------------------------------------------------

class _SearchIllustration extends StatelessWidget {
  const _SearchIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canvasColor = isDark ? AppColors.mintDark : AppColors.mintAccent;
    final cardBg = isDark ? AppColors.neutral900 : AppColors.pureWhite;
    final primaryText = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final border = isDark ? AppColors.neutral800 : AppColors.neutral200;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.circular(28.0.r),
      ),
      padding: EdgeInsets.all(24.0.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20.0.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10.0.r,
                ),
              ],
            ),
            padding: EdgeInsets.all(16.0.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Box Mock
                Container(
                  height: 38.0.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(19.0.r),
                    border: Border.all(color: border, width: 1.0.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16.0.r, color: AppColors.neutral400),
                      SizedBox(width: 8.0.w),
                      Text(
                        'Search: repo',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.0.sp,
                          color: primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.0.h),
                // Trie Tree Graphic
                SizedBox(
                  height: 120.0.h,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TrieGraphPainter(
                      circleColor: isDark ? AppColors.neutral800 : AppColors.neutral100,
                      lineColor: isDark ? AppColors.neutral700 : AppColors.neutral200,
                      textColor: primaryText,
                    ),
                  ),
                ),
                SizedBox(height: 16.0.h),
                // Search Result row
                Row(
                  children: [
                    Container(
                      width: 32.0.w,
                      height: 32.0.h,
                      decoration: BoxDecoration(
                        color: AppColors.pdfBackground,
                        borderRadius: BorderRadius.circular(8.0.r),
                      ),
                      child: Icon(Icons.picture_as_pdf_outlined, color: AppColors.pdfIcon, size: 16.0.r),
                    ),
                    SizedBox(width: 10.0.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quarterly_Report_Q3.pdf',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.0.sp,
                              fontWeight: FontWeight.w600,
                              color: primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Super fast lookup',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.0.sp,
                              color: AppColors.neutral400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.mintLight,
                        borderRadius: BorderRadius.circular(12.0.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 4.0.h),
                      child: Text(
                        '0.8 ms',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.0.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mintAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrieGraphPainter extends CustomPainter {
  final Color circleColor;
  final Color lineColor;
  final Color textColor;

  _TrieGraphPainter({
    required this.circleColor,
    required this.lineColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paints
    final inactiveLinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    
    final activeLinePaint = Paint()
      ..color = AppColors.mintAccent
      ..strokeWidth = 3.0;

    final inactiveCirclePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.fill;

    final activeCirclePaint = Paint()
      ..color = AppColors.mintAccent
      ..style = PaintingStyle.fill;

    // Define nodes
    final root = Offset(size.width / 2, 16);
    
    // Level 1
    final level1E = Offset(size.width / 3, 60);
    final level1O = Offset(size.width * 2 / 3, 60);
    
    // Level 2
    final level2P = Offset(size.width / 4, 104);
    final level2A = Offset(size.width / 2.3, 104);
    final level2O = Offset(size.width * 2 / 3, 104);

    // Active path is R (root) -> E (level1E) -> P (level2P)
    // Draw inactive connections
    canvas.drawLine(root, level1O, inactiveLinePaint);
    canvas.drawLine(level1E, level2A, inactiveLinePaint);
    canvas.drawLine(level1O, level2O, inactiveLinePaint);

    // Draw active connections
    canvas.drawLine(root, level1E, activeLinePaint);
    canvas.drawLine(level1E, level2P, activeLinePaint);

    // Draw node circles
    _drawNode(canvas, root, 'R', true, activeCirclePaint, inactiveCirclePaint);
    _drawNode(canvas, level1E, 'E', true, activeCirclePaint, inactiveCirclePaint);
    _drawNode(canvas, level1O, 'O', false, activeCirclePaint, inactiveCirclePaint);
    _drawNode(canvas, level2P, 'P', true, activeCirclePaint, inactiveCirclePaint);
    _drawNode(canvas, level2A, 'A', false, activeCirclePaint, inactiveCirclePaint);
    _drawNode(canvas, level2O, 'T', false, activeCirclePaint, inactiveCirclePaint);
  }

  void _drawNode(Canvas canvas, Offset center, String text, bool isActive, Paint activePaint, Paint inactivePaint) {
    canvas.drawCircle(center, 12.0, isActive ? activePaint : inactivePaint);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.white : textColor.withValues(alpha: 0.6),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SemanticAIIllustration extends StatelessWidget {
  const _SemanticAIIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canvasColor = isDark ? AppColors.mintDark : AppColors.mintAccent;
    final cardBg = isDark ? AppColors.neutral900 : AppColors.pureWhite;
    final primaryText = isDark ? AppColors.pureWhite : AppColors.neutral900;
    final bodyText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.neutral800 : AppColors.neutral200;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.circular(28.0.r),
      ),
      padding: EdgeInsets.all(24.0.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20.0.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10.0.r,
                ),
              ],
            ),
            padding: EdgeInsets.all(16.0.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Box Mock
                Container(
                  height: 38.0.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(19.0.r),
                    border: Border.all(color: border, width: 1.0.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16.0.r, color: AppColors.neutral400),
                      SLocalizationHelper(primaryText: primaryText),
                    ],
                  ),
                ),
                SizedBox(height: 12.0.h),

                // Proximity Cluster Diagram
                SizedBox(
                  height: 120.0.h,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ClusterVectorPainter(
                      dotColor: AppColors.mintAccent,
                      lineColor: isDark ? AppColors.neutral700 : AppColors.neutral200,
                    ),
                  ),
                ),
                SizedBox(height: 12.0.h),

                // Labeled details
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.0.r),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12.0.r),
                    border: Border.all(color: border, width: 1.0.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Form16_FY2025.pdf',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.0.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            '94% match',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.0.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mintAccent,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.0.h),
                      Text(
                        'Local AI Model • 100% Private',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.0.sp,
                          color: bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SLocalizationHelper extends StatelessWidget {
  final Color primaryText;

  const SLocalizationHelper({
    Key? key,
    required this.primaryText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.0.w),
      child: Text(
        'Find: tax documents',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.0.sp,
          color: primaryText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ClusterVectorPainter extends CustomPainter {
  final Color dotColor;
  final Color lineColor;

  _ClusterVectorPainter({required this.dotColor, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerPoint = Offset(size.width / 2, size.height / 2);

    // 1. Draw concentric similarity rings
    final ringPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(centerPoint, 36.0, ringPaint);
    canvas.drawCircle(centerPoint, 72.0, ringPaint);
    canvas.drawCircle(centerPoint, 108.0, ringPaint);

    // 2. Draw search query radar scan sweep arc
    final radarPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerPoint, 72.0, radarPaint);

    // 3. Draw similarity projection lines (glowing matched connections)
    final projectionPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = dotColor..style = PaintingStyle.fill;
    final mutedDotPaint = Paint()..color = lineColor.withValues(alpha: 0.4)..style = PaintingStyle.fill;

    // Matched Cluster (Close to query center)
    final matchedNodes = [
      Offset(size.width / 2 - 30, size.height / 2 - 18),
      Offset(size.width / 2 + 26, size.height / 2 + 22),
      Offset(size.width / 2 - 18, size.height / 2 + 32),
    ];

    for (var node in matchedNodes) {
      canvas.drawLine(centerPoint, node, projectionPaint);
      canvas.drawCircle(node, 4.0, dotPaint);
    }

    // Unrelated Cluster A (Taxes vs Music - far top-left)
    final clusterA = [
      Offset(24.0, 18.0),
      Offset(38.0, 12.0),
      Offset(30.0, 30.0),
    ];
    for (var node in clusterA) {
      canvas.drawCircle(node, 3.0, mutedDotPaint);
    }

    // Unrelated Cluster B (Taxes vs APKs - far bottom-right)
    final clusterB = [
      Offset(size.width - 30, size.height - 20),
      Offset(size.width - 45, size.height - 15),
      Offset(size.width - 20, size.height - 35),
    ];
    for (var node in clusterB) {
      canvas.drawCircle(node, 3.0, mutedDotPaint);
    }

    // 4. Highlight Center Point Query
    final queryPaint = Paint()..color = AppColors.errorRed..style = PaintingStyle.fill;
    canvas.drawCircle(centerPoint, 6.0, queryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SyncIllustration extends StatelessWidget {
  const _SyncIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canvasColor = isDark ? AppColors.mintDark : AppColors.mintAccent;
    final cardBg = isDark ? AppColors.neutral900 : AppColors.pureWhite;
    final primaryText = isDark ? AppColors.pureWhite : AppColors.neutral900;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.circular(28.0.r),
      ),
      padding: EdgeInsets.all(24.0.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20.0.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10.0.r,
                ),
              ],
            ),
            padding: EdgeInsets.all(16.0.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live File Sync',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.0.sp,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    Icon(Icons.sync, color: AppColors.mintAccent, size: 18.0.r),
                  ],
                ),
                SizedBox(height: 16.0.h),
                // Sync Visual Canvas
                SizedBox(
                  height: 130.0.h,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SyncDiagramPainter(
                      color: AppColors.mintAccent,
                      lineColor: isDark ? AppColors.neutral700 : AppColors.neutral200,
                      textColor: primaryText,
                    ),
                  ),
                ),
                SizedBox(height: 16.0.h),
                // Live Sync Row Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stale files index:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.0.sp,
                        fontWeight: FontWeight.w500,
                        color: primaryText,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.mintLight,
                        borderRadius: BorderRadius.circular(8.0.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 4.0.h),
                      child: Text(
                        '0%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.0.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mintAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncDiagramPainter extends CustomPainter {
  final Color color;
  final Color lineColor;
  final Color textColor;

  _SyncDiagramPainter({
    required this.color,
    required this.lineColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Draw Left Node (Storage Disk Mockup)
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8.0, 10.0, 64.0, 96.0),
      Radius.circular(10.0),
    );
    canvas.drawRRect(leftRect, borderPaint);

    // Left Node Header / Icon (Yellow folder)
    final folderPaint = Paint()..color = AppColors.folderYellow..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(16.0, 22.0, 20.0, 14.0), Radius.circular(3.0)),
      folderPaint,
    );
    
    // Draw content stripes
    final stripePaint = Paint()..color = lineColor..strokeWidth = 2.0;
    canvas.drawLine(Offset(16.0, 52.0), Offset(48.0, 52.0), stripePaint);
    canvas.drawLine(Offset(16.0, 64.0), Offset(36.0, 64.0), stripePaint);

    // 2. Draw Right Node (Application Database Mockup)
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 72.0, 10.0, 64.0, 96.0),
      Radius.circular(10.0),
    );
    canvas.drawRRect(rightRect, borderPaint);

    // Right Node DB Cylinder / Icon (Mint database dot)
    final dbPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width - 40.0, 28.0), 8.0, dbPaint);

    // Draw content stripes
    canvas.drawLine(Offset(size.width - 56.0, 52.0), Offset(size.width - 24.0, 52.0), stripePaint);
    canvas.drawLine(Offset(size.width - 56.0, 64.0), Offset(size.width - 32.0, 64.0), stripePaint);

    // 3. Draw Dashed Connection Curves
    final path1 = Path();
    path1.moveTo(76.0, 36.0);
    path1.quadraticBezierTo(size.width / 2, 8.0, size.width - 76.0, 36.0);
    _drawDashedPath(canvas, path1, dashPaint);

    final path2 = Path();
    path2.moveTo(size.width - 76.0, 72.0);
    path2.quadraticBezierTo(size.width / 2, 104.0, 76.0, 72.0);
    _drawDashedPath(canvas, path2, dashPaint);

    // 4. Draw Floating File sync nodes in the center
    final filePaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2 - 16, 25.0), 5.0, filePaint);
    canvas.drawCircle(Offset(size.width / 2 + 16, 81.0), 5.0, filePaint);

    // Labels
    _drawText(canvas, Offset(8.0, 112.0), 'External disk', textColor.withValues(alpha: 0.6));
    _drawText(canvas, Offset(size.width - 72.0, 112.0), 'Flux Index', textColor.withValues(alpha: 0.6));
  }

  void _drawText(Canvas canvas, Offset pos, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 8.0,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (var metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = 4.0;
        final dashPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(dashPath, paint);
        distance += length + 4.0;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
