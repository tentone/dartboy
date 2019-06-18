import 'package:flutter/material.dart';

import '../cpu/cpu.dart';
import '../memory/memory_registers.dart';

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
    return colors[(this.cpu.mmu.readRegisterByte(this.register) >> (number * 2)) & 0x3];
  }

}