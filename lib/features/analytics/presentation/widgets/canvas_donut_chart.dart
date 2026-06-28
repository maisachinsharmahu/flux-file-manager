import 'package:flutter/material.dart';

class CanvasDonutChart extends StatelessWidget {
  const CanvasDonutChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutChartPainter(),
      child: const Center(
        child: Text('Donut Chart Canvas'),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[350]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      60.0,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
