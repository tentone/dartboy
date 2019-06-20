import 'package:flutter/material.dart';

/// Util to convert between flutter colors and RGB colors.
class ColorConverter
{
  static int toRGB(Color color)
  {
    return (color.red & 0xFF) << 16 | (color.green & 0xFF) << 8 | (color.blue & 0xFF);
  }

  static Color toColor(int rgb)
  {
    return new Color(rgb);
  }
}
