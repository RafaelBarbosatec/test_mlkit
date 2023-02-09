import 'package:flutter/material.dart';

class FramePainter extends CustomPainter {
  final Rect rect;
  final BorderRadius borderRadius;
  final Color strokeColor;

  final backgroundColor = Colors.black.withOpacity(0.5);

  FramePainter(this.rect, this.borderRadius, {this.strokeColor = Colors.red});

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
      ..blendMode = BlendMode.clear;
    canvas.drawRRect(borderRect, paintFill);

    paintStroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(borderRect, paintStroke);
  }

  @override
  bool shouldRepaint(FramePainter oldDelegate) => false;
}
