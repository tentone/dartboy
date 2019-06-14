import 'dart:math';
import 'dart:typed_data';
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
    //Paint paint = new Paint();
    //paint.style = PaintingStyle.fill;
    //paint.color = Colors.blue;

    //Clear rect
    Offset center = new Offset(size.width / 2, size.height / 2);
    //canvas.drawRect(new Rect.fromCenter(center: center, width: LCD_WIDTH.toDouble(), height: LCD_HEIGHT.toDouble()), paint);

    // Points test
    Paint linePaint = new Paint();
    linePaint.style = PaintingStyle.stroke;
    linePaint.strokeWidth = 1.0;
    linePaint.color = Color.fromRGBO(255, 0, 0, 1.0);

    List<double> points = new List<double>();

    for(int x = 0; x < LCD_WIDTH; x++)
    {
      for(int y = 0; y < LCD_HEIGHT; y++)
      {
        points.add(x.toDouble());
        points.add(y.toDouble());
      }
    }

    canvas.drawRawPoints(PointMode.points, new Float32List.fromList(points), linePaint);
  }

  @override
  bool shouldRepaint(LCDPainter oldDelegate)
  {
    return true;
  }
}