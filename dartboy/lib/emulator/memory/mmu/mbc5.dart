import '../../cpu/cpu.dart';
import '../cartridge.dart';
import '../memory.dart';
import 'mbc.dart';

class MBC5 extends MBC
{
  MBC5(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);

  /// Indicates if the addresses 0x5000 to 0x6000 are redirected to RAM or to ROM
  int modeSelect;

  /// Selected ROM bank
  int romBank;

  @override
  void reset()
  {
    super.reset();

    this.modeSelect = 0;
    this.romBank = 0;

    this.cartRam = new List<int>(MBC.RAM_PAGESIZE * 16);
    this.cartRam.fillRange(0, this.cartRam.length, 0);
  }

  /// Select ROM bank to be used.
  void mapRom(int bank)
  {
    this.romBank = bank;
    this.romPageStart = Memory.ROM_PAGESIZE * bank;
  }

  @override
  void writeByte(int address, int value)
  {
    //TODO <ADD CODE HERE>
    super.writeByte(address, value);
  }
}