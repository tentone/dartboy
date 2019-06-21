import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../emulator/graphics/ppu.dart';
import '../utils/color_converter.dart';
import './main_screen.dart';

class LCDWidget extends StatefulWidget
{
  LCDWidget({Key key}) : super(key: key);

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
      painter: new LCDPainter()
    );
  }
}

class LCDPainter extends CustomPainter
{
  LCDPainter();

  @override
  void paint(Canvas canvas, Size size)
  {
    if(MainScreen.emulator == null || MainScreen.emulator.cpu == null)
    {
      return;
    }

    for(int x = 0; x < PPU.LCD_WIDTH; x++)
    {
      for(int y = 0; y < PPU.LCD_HEIGHT; y++)
      {
        Paint color = new Paint();
        color.style = PaintingStyle.stroke;
        color.strokeWidth = 1.0;
        //color.color = ColorConverter.toColor(MainScreen.emulator.cpu.ppu.screenBuffer[x + y * PPU.LCD_WIDTH]);
        color.color = ColorConverter.toColor((x & 0xFF) << 8 | (y & 0xFF));

        List<double> points = new List<double>();
        points.add(x.toDouble() - PPU.LCD_WIDTH / 2.0);
        points.add(y.toDouble() + PPU.LCD_HEIGHT / 2.0);

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