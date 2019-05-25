import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LCDPainter extends CustomPainter
{
  LCDPainter();

  static const int LCD_WIDTH = 160;
  static const int LCD_HEIGHT = 144;
  static const double LCD_RATIO = LCD_WIDTH / LCD_HEIGHT;

  @override
  void paint(Canvas canvas, Size size)
  {

    Paint paint = new Paint();
    paint.style = PaintingStyle.fill;
    paint.color = Colors.black;

    Offset center = new Offset(size.width / 2, size.height / 2);

    //Clear rect
    canvas.drawRect(new Rect.fromCenter(center: center, width: LCD_WIDTH.toDouble(), height: LCD_HEIGHT.toDouble()), paint);

    // Points test
    paint.color = Colors.red;

    List<Offset> points = List<Offset>();

    for(int i = 0; i < LCD_WIDTH; i++)
    {
      points.add(new Offset(i.toDouble(), 0));
    }

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(LCDPainter oldDelegate)
  {
    return true;
  }
}