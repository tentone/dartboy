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

    var center = Offset(size.width / 2, size.height / 2);

    //canvas.drawRect(new Rect.fromCenter(center: center, width: size.width, height: size.height), paint);
    canvas.drawCircle(center, 75.0, paint);
  }

  @override
  bool shouldRepaint(LCDPainter oldDelegate)
  {
    return true;
  }
}