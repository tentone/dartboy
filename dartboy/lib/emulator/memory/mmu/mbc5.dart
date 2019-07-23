import '../../cpu/cpu.dart';
import '../cartridge.dart';
import '../memory.dart';
import '../memory_addresses.dart';
import 'mbc.dart';

class MBC5 extends MBC
{
  MBC5(CPU cpu) : super(cpu);

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
    address &= 0xffff;
    value &= 0xff;

    if(address >= MemoryAddresses.CARTRIDGE_ROM_START && address < 0x2000)
    {
      if(this.cpu.cartridge.ramBanks > 0)
      {
        this.ramEnabled = (value & 0x0F) == 0x0A;
      }
    }
    else if(address >= 0x2000 && address < 0x3000)
    {
      // The lower 8 bits of the ROM bank number goes here. Writing 0 will indeed give bank 0 on MBC5, unlike other MBCs.
      this.mapRom((this.romBank & 0x100) | (value & 0xFF));
    }
    else if(address >= 0x3000 && address < 0x4000)
    {
      // The 9th bit of the ROM bank number goes here.
      this.mapRom((this.romBank & 0xff) | ((value & 0x1) << 8));
    }
    else if(address >= MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START && address < 0x6000)
    {
      this.ramPageStart = (value & 0x03) * MBC.RAM_PAGESIZE;
    }
    else if(address >= MemoryAddresses.SWITCHABLE_RAM_START && address < MemoryAddresses.SWITCHABLE_RAM_END)
    {
      if(this.ramEnabled)
      {
        this.cartRam[address - MemoryAddresses.SWITCHABLE_RAM_START + this.ramPageStart] = value;
      }
    }
    else
    {
      super.writeByte(address, value);
    }
  }
}