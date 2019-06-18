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

  int time = 0;

  @override
  void paint(Canvas canvas, Size size)
  {
    time++;

    for(int x = 0; x < LCD_WIDTH; x++)
    {
      for(int y = 0; y < LCD_HEIGHT; y++)
      {
        Paint color = new Paint();
        color.style = PaintingStyle.stroke;
        color.strokeWidth = 1.0;
        color.color = Color.fromRGBO(((x + time).toDouble() / LCD_WIDTH.toDouble() * 255.0).toInt(), (y.toDouble() / LCD_HEIGHT.toDouble() * 255.0).toInt(), 0, 1.0);

        List<double> points = new List<double>();
        points.add(x.toDouble() - LCD_WIDTH / 2);
        points.add(y.toDouble() + LCD_HEIGHT / 2);

        canvas.drawRawPoints(PointMode.points, new Float32List.fromList(points), color);
      }
    }
  }

  @override
  bool shouldRepaint(LCDPainter oldDelegate)
  {
    return true;
  }
}