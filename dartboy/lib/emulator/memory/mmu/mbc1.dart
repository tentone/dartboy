import '../../cpu/cpu.dart';
import '../cartridge.dart';
import '../memory.dart';
import '../memory_addresses.dart';
import 'mbc.dart';

/// Memory banking chip
class MBC1 extends MBC
{
  /// Indicates if the addresses 0x5000 to 0x6000 are redirected to RAM or to ROM
  int modeSelect;

  /// Selected ROM bank
  int romBank;

  MBC1(CPU cpu) : super(cpu);

  @override
  void reset()
  {
    super.reset();

    this.modeSelect = 0;
    this.romBank = 1;

    this.cartRam = new List<int>(MBC.RAM_PAGESIZE * 4);
    this.cartRam.fillRange(0, this.cartRam.length, 0);
  }

  void mapRom(int bank)
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

    switch(address & 0xF000)
    {
      case 0x0000:
      case 0x1000:
        // It is recommended to disable external RAM after accessing it.
        // Practically any value with 0xA in the lower 4 bits enables RAM, and any other value disables RAM.
        if(this.cpu.cartridge.ramBanks > 0)
        {
          this.ramEnabled = (value & 0x0F) == 0x0A;
        }

        break;
      case 0xA000:
      case 0xB000:
        // This area is used to address external RAM in the cartridge.
        if(this.ramEnabled)
        {
          this.cartRam[address - MemoryAddresses.SWITCHABLE_RAM_START + this.ramPageStart] = value;
        }
        break;
      case 0x2000:
      case 0x3000:
        // Writing to this address space selects the lower 5 bits of the ROM Bank Number.
        this.mapRom((this.romBank & 0x60) | (value & 0x1F));
        break;
      case 0x4000:
      case 0x5000:
        // Select a RAM Bank in range from 00-03h, or to specify the upper two bits (Bit 5-6) of the ROM Bank number, depending on the current ROM/RAM Mode.
        if(this.modeSelect == 0)
        {
          this.ramPageStart = (value & 0x03) * MBC.RAM_PAGESIZE;
        }
        else
        {
          this.mapRom((this.romBank & 0x1F) | ((value & 0x03) << 4));
        }
        break;
      case 0x6000:
      case 0x7000:
        // Selects whether the two bits of the above register should be used as upper two bits of the ROM Bank, or as RAM Bank Number.
        if(this.cpu.cartridge.ramBanks == 3)
        {
          this.modeSelect = (value & 0x01);
        }
        break;
      default:
        super.writeByte(address, value);
        break;
    }
  }
}