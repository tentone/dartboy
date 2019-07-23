import '../../cpu/cpu.dart';
import '../cartridge.dart';
import '../memory.dart';
import '../memory_addresses.dart';
import 'mbc.dart';


/// Memory banking chip 1 (MBC1).
///
/// Supports two modes up to 16Mb ROM/8KB RAM or 4Mb ROM/32KB RAM
class MBC1 extends MBC
{
  static const int RAM_DISABLE_START = 0x0000;
  static const int RAM_DISABLE_END = 0x2000;

  static const int ROM_BANK_SELECT_START = 0x2000;
  static const int ROM_BANK_SELECT_END = 0x4000;

  static const int SELECT_MEMORY_MODE_START = 0x6000;
  static const int SELECT_MEMORY_MODE_END = 0x8000;

  /// MBC1 mode for 16Mb ROM and 8KB RAM, default mode of the controller.
  static const int MODE_16ROM_8RAM = 0;

  /// MBC1 mode for 4Mb ROM and 32KB RAM
  static const int MODE_4ROM_32RAM = 1;

  /// Indicates if the addresses 0x5000 to 0x6000 are redirected to RAM or to ROM
  int modeSelect;

  /// Selected ROM bank
  int romBank;

  MBC1(CPU cpu) : super(cpu);

  @override
  void reset()
  {
    super.reset();

    this.modeSelect = MBC1.MODE_16ROM_8RAM;
    this.romBank = 1;

    this.cartRam = new List<int>(MBC.RAM_PAGESIZE * 4);
    this.cartRam.fillRange(0, this.cartRam.length, 0);
  }

  /// Select the ROM bank to be used.
  void selectROMBank(int bank)
  {
    // Not usable banks, use the next bank available.
    if(bank == 0x00 || bank == 0x20 || bank == 0x40 || bank == 0x60)
    {
      bank++;
    }

    this.romBank = bank;
    this.romPageStart = Memory.ROM_PAGESIZE * bank;
  }

  @override
  void writeByte(int address, int value)
  {
    address &= 0xffff;
    value &= 0xff;

    // Any value with 0xA in the lower 4 bits enables RAM, and any other value disables RAM.
    if(address >= MBC1.RAM_DISABLE_START && address < MBC1.RAM_DISABLE_END)
    {
      if(this.cpu.cartridge.ramBanks > 0)
      {
        this.ramEnabled = (value & 0x0F) == 0x0A;
      }
    }
    // Writing to this address space selects the lower 5 bits of the ROM Bank Number.
    else if(address >= MBC1.ROM_BANK_SELECT_START && address < MBC1.ROM_BANK_SELECT_END)
    {
      this.selectROMBank((this.romBank & 0x60) | (value & 0x1F));
    }
    // Select a RAM Bank in range from 00-03h, or to specify the upper two bits (Bit 5-6) of the ROM Bank number, depending on the current ROM/RAM Mode.
    else if(address >= 0x4000 && address < 0x6000)
    {
      if(this.modeSelect == MBC1.MODE_16ROM_8RAM)
      {
        this.ramPageStart = (value & 0x03) * MBC.RAM_PAGESIZE;
      }
      else // if(this.modeSelect == MBC1.MODE_4ROM_32RAM)
      {
        this.selectROMBank((this.romBank & 0x1F) | ((value & 0x03) << 4));
      }
    }
    // Selects whether the two bits of the above register should be used as upper two bits of the ROM Bank, or as RAM Bank Number.
    else if(address >= MBC1.SELECT_MEMORY_MODE_START && address < MBC1.SELECT_MEMORY_MODE_END)
    {
      if(this.cpu.cartridge.ramBanks == 3)
      {
        this.modeSelect = (value & 0x01);
      }
    }
    // This area is used to address external RAM in the cartridge.
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