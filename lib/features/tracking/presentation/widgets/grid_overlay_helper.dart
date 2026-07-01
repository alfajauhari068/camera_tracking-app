import 'package:flutter/material.dart';

/// Draws a thin 3x3 Rule-of-Thirds grid and semi-transparent border.
class GridOverlayHelper extends StatelessWidget {
  final Color lineColor;
  final double lineOpacity;
  final double borderOpacity;

  const GridOverlayHelper({
    Key? key,
    this.lineColor = Colors.white,
    this.lineOpacity = 0.15,
    this.borderOpacity = 0.12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(
        lineColor: lineColor.withOpacity(lineOpacity),
        borderColor: lineColor.withOpacity(borderOpacity),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color lineColor;
  final Color borderColor;

  _GridPainter({required this.lineColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Draw border
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, borderPaint);

    // Vertical lines at 1/3 and 2/3
    final dx1 = size.width / 3;
    final dx2 = 2 * size.width / 3;
    canvas.drawLine(Offset(dx1, 0), Offset(dx1, size.height), paint);
    canvas.drawLine(Offset(dx2, 0), Offset(dx2, size.height), paint);

    // Horizontal lines at 1/3 and 2/3
    final dy1 = size.height / 3;
    final dy2 = 2 * size.height / 3;
    canvas.drawLine(Offset(0, dy1), Offset(size.width, dy1), paint);
    canvas.drawLine(Offset(0, dy2), Offset(size.width, dy2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
