import '../cpu/cpu.dart';
import '../memory/memory_registers.dart';

/// Palette is used to store the gameboy palette colors.
///
/// Each palette is composed of four colors, for classic gameboy gray scale colors are stored.
///
/// For gameboy color the palette stores RGB colors.
abstract class Palette
{
  List<int> colors;

  /// Gets the RGBA color associated to a given index.
  int getColor(int number);
}

class GBPalette implements Palette
{
  CPU cpu;
  int register;
  List<int> colors;

  GBPalette(CPU cpu, List<int> colors, int register)
  {
    if(register != MemoryRegisters.BGP && register != MemoryRegisters.OBP0 && register != MemoryRegisters.OBP1)
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
  int getColor(int number)
  {
    return this.colors[(this.cpu.mmu.readRegisterByte(this.register) >> (number * 2)) & 0x3];
  }
}

class GBCPalette implements Palette
{
  List<int> colors;

  GBCPalette(List<int> colors)
  {
    if(colors.length < 4)
    {
      throw new Exception("Colors must be of length 4.");
    }

    this.colors = colors;
  }

  @override
  int getColor(int number)
  {
    return this.colors[number];
  }
}
