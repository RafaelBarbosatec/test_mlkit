import 'package:flutter/material.dart';

class FramePainter extends CustomPainter {
  final Rect rect;
  final BorderRadius borderRadius;

  final backgroundColor = Colors.black.withOpacity(0.5);

  FramePainter(this.rect, this.borderRadius);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paintBackground = Paint();
    canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height), paintBackground);
    canvas.drawColor(backgroundColor, BlendMode.dstATop);

    Paint paintFill;
    Paint paintStroke;
    final RRect borderRect =
        borderRadius.resolve(TextDirection.ltr).toRRect(rect);
    paintFill = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4
      ..blendMode = BlendMode.clear;
    canvas.drawRRect(borderRect, paintFill);

    paintStroke = Paint()
      ..color = Colors.red.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(borderRect, paintStroke);
  }

  @override
  bool shouldRepaint(FramePainter oldDelegate) => false;
}
