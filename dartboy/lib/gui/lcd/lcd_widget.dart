import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../emulator/cpu/cpu.dart';
import '../../emulator/graphics/lcd.dart';

class LCDWidget extends StatefulWidget
{
  /// Gameboy CPU object to extract the graphics data.
  ///
  /// If set to null data is not drawn.
  CPU cpu;

  LCDWidget(this.cpu);

  @override
  State<LCDWidget> createState()
  {
    return new LCDState();
  }
}

class LCDState extends State<LCDWidget> with SingleTickerProviderStateMixin
{
  @override
  Widget build(BuildContext context)
  {
    return new CustomPaint
    (
      isComplex: true,
      willChange: true,
      painter: new LCDPainter(this.widget.cpu)
    );
  }
}

class LCDPainter extends CustomPainter
{
  CPU cpu;

  LCDPainter(this.cpu);

  static const int LCD_WIDTH = 160;
  static const int LCD_HEIGHT = 144;

  static const double LCD_RATIO = LCD_WIDTH / LCD_HEIGHT;

  @override
  void paint(Canvas canvas, Size size)
  {
    if(this.cpu.lcd == null)
    {
      return;
    }

    for(int x = 0; x < LCD_WIDTH; x++)
    {
      for(int y = 0; y < LCD_HEIGHT; y++)
      {
        Paint color = new Paint();
        color.style = PaintingStyle.stroke;
        color.strokeWidth = 1.0;
        color.color = new Color(this.cpu.lcd.screenBuffer[x + y * LCD_WIDTH]);

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