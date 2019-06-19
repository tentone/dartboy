import 'package:flutter/material.dart';

import '../cpu/cpu.dart';
import '../memory/memory_registers.dart';

/// Palette is used to store the gameboy palette colors.
///
/// Each palette is composed of four colors, for classic gameboy gray scale colors are stored.
///
/// For gameboy color the palette stores RGB colors.
abstract class Palette
{
  /// Gets the RGBA color associated to a given index.
  Color getColor(int number);
}

class GBPalette implements Palette
{
  CPU cpu;
  int register;
  List<Color> colors;

  GBPalette(CPU cpu, List<Color> colors, int register)
  {
    if(register != MemoryRegisters.R_BGP && register != MemoryRegisters.R_OBP0 && register != MemoryRegisters.R_OBP1)
    {
      throw new Exception("Register must be one of R.R_BGP, R.R_OBP0, or R.R_OBP1.");
    }

    if(colors.length < 4)
    {
      throw new Exception("Colors must be of length 4.");
    }

    this.cpu = cpu;
    this.colors = colors;
    this.register = register;
  }

  @override
  Color getColor(int number)
  {
    return this.colors[(this.cpu.mmu.readRegisterByte(this.register) >> (number * 2)) & 0x3];
  }
}

class GBCPalette implements Palette
{
  List<Color> colors;

  GBCPalette(List<Color> colors)
  {
    if(colors.length < 4)
    {
      throw new Exception("Colors must be of length 4.");
    }

    this.colors = colors;
  }

  @override
  Color getColor(int number)
  {
    return this.colors[number];
  }
}
