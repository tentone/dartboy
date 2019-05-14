import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LCDPainter extends CustomPainter
{
  LCDPainter();


  @override
  void paint(Canvas canvas, Size size)
  {

    var paint = new Paint();
    paint.style = PaintingStyle.fill;
    paint.color = Colors.black;
    paint.strokeWidth = 2.0;

    canvas.drawRect(new Rect.fromLTRB(-100, 20, 100, 100), paint);
  }

  @override
  bool shouldRepaint(LCDPainter oldDelegate)
  {
    return false;
  }
}