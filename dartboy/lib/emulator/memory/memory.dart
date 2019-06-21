import '../cpu/cpu.dart';
import './cartridge.dart';
import './hdma.dart';
import './memory_addresses.dart';

/// Generic memory container used to represent memory spaces in the gameboy system.
///
/// Contains all the memory spaces of the gameboy except for the cartridge data.
///
/// Can be used to represent booth ROM or RAM memory and provides Byte based access.
class Memory
{
  /// Size of a page of Video RAM, in bytes. 8kb.
  static const int VRAM_PAGESIZE = 0x2000;

  /// Size of a page of Work RAM, in bytes. 4kb.
  static const int WRAM_PAGESIZE = 0x1000;

  /// Size of a page of ROM, in bytes. 16kb.
  static const int ROM_PAGESIZE = 0x4000;

  /// Register values, mapped from $FF00-$FF7F + HRAM ($FF80-$FFFE) + Interrupt Enable Register ($FFFF)
  List<int> registers;

  /// Sprite Attribute Table, mapped from $FE00-$FE9F.
  List<int> oam;

  /// Video RAM, mapped from $8000-$9FFF.
  /// On the GBC, this bank is switchable 0-1 by writing to $FF4F.
  List<int> vram;

  /// Work RAM, mapped from $C000-$CFFF and $D000-$DFFF.
  /// On the GBC, this bank is switchable 1-7 by writing to $FF07.
  List<int> wram;

  /// The current page of Video RAM, always multiples of Memory.VRAM_PAGESIZE.
  /// On non-GBC, this is always 0.
  int vramPageStart = 0;

  /// The current page of Work RAM, always multiples of Memory.WRAM_PAGESIZE.
  /// On non-GBC, this is always Memory.VRAM_PAGESIZE.
  int wramPageStart = WRAM_PAGESIZE;

  /// The current page of ROM, always multiples of Memory.ROM_PAGESIZE.
  int romPageStart = ROM_PAGESIZE;

  /// CPU that is using the MMU, useful to trigger changes in other parts affected by memory changes.
  CPU cpu;

  /// HDMA memory controller (only available on gameboy color games).
  ///
  /// Used for direct memory copy operations.
  HDMA hdma;

  Memory(CPU cpu)
  {
    this.cpu = cpu;

    this.initialize();
  }

  /// Initialize the memory, create the data array with the defined size.
  void initialize()
  {
    this.registers = new List<int>(0x100);
    this.registers.fillRange(0, this.registers.length, 0);

    this.oam = new List<int>(0xA0);
    this.oam.fillRange(0, this.oam.length, 0);

    this.wram = new List<int>(WRAM_PAGESIZE * (this.cpu.cartridge.gameboyType == GameboyType.COLOR ? 8 : 2));
    this.wram.fillRange(0, this.wram.length, 0);

    this.vram = new List<int>(VRAM_PAGESIZE * (this.cpu.cartridge.gameboyType == GameboyType.COLOR ? 2 : 1));
    this.vram.fillRange(0, this.vram.length, 0);
  }

  /// Write a byte into memory address
  void writeByte(int address, int value)
  {
    value &= 0xff;
    address &= 0xFFFF;

    int block = address & 0xF000;

    if(address < MemoryAddresses.CARTRIDGE_ROM_END)
    {
      //throw new Exception('Cannot write data into cartridge ROM memory.');
      return;
    }
    else if(address >= MemoryAddresses.VIDEO_RAM_START && address < MemoryAddresses.VIDEO_RAM_END)
    {
      this.vram[this.vramPageStart + address - MemoryAddresses.VIDEO_RAM_START] = value;
    }
    else if(address >= MemoryAddresses.SWITCHABLE_RAM_START && address < MemoryAddresses.SWITCHABLE_RAM_END)
    {
      //throw new Exception('Cannot write data into cartridge RAM memory.');
      return;
    }
    else if(block == MemoryAddresses.RAM_A_START)
    {
      this.wram[address - MemoryAddresses.RAM_A_START] = value;
    }
    else if(block == MemoryAddresses.RAM_A_SWITCHABLE_START)
    {
      this.wram[this.wramPageStart + address - MemoryAddresses.RAM_A_START] = value;
    }
    else if(address >= MemoryAddresses.EMPTY_A_START && address < MemoryAddresses.EMPTY_A_END)
    {
      return;
    }
    else if(address >= MemoryAddresses.RAM_A_ECHO_START && address < MemoryAddresses.RAM_A_ECHO_END)
    {
      this.writeByte(address - MemoryAddresses.RAM_A_ECHO_START, value);
    }
    else if(address >= MemoryAddresses.OAM_START && address < MemoryAddresses.EMPTY_A_END)
    {
      this.oam[address - MemoryAddresses.OAM_START] = value;
    }
    else if(address >= MemoryAddresses.IO_START)
    {
      this.writeIO(address - MemoryAddresses.IO_START, value);
    }
  }

  /// Write data into the IO section of memory space.
  void writeIO(int address, int value)
  {

  }

  /// Read a byte from memory address
  ///
  /// If the address falls into the cartridge addressing zone read directly from the cartridge object.
  int readByte(int address)
  {
    address &= 0xFFFF;
    int block = address & 0xF000;

    if(address < MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START)
    {
      return this.cpu.cartridge.data[address];
    }
    if(address >= MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START && address < MemoryAddresses.CARTRIDGE_ROM_END)
    {
      return this.cpu.cartridge.data[this.romPageStart + address - MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START];
    }
    else if(address >= MemoryAddresses.VIDEO_RAM_START && address < MemoryAddresses.VIDEO_RAM_END)
    {
      return this.vram[this.vramPageStart + address - MemoryAddresses.VIDEO_RAM_START];
    }
    else if(address >= MemoryAddresses.SWITCHABLE_RAM_START && address < MemoryAddresses.SWITCHABLE_RAM_END)
    {
      return 0;
    }
    else if(block == MemoryAddresses.RAM_A_START)
    {
      return this.wram[address - MemoryAddresses.RAM_A_START];
    }
    else if(block == MemoryAddresses.RAM_A_SWITCHABLE_START)
    {
      return this.wram[this.wramPageStart + address - MemoryAddresses.RAM_A_START];
    }
    else if(address >= MemoryAddresses.EMPTY_A_START && address < MemoryAddresses.EMPTY_A_END)
    {
      return 0xFF;
    }
    else if(address >= MemoryAddresses.RAM_A_ECHO_START && address < MemoryAddresses.RAM_A_ECHO_END)
    {
      return this.readByte(address - MemoryAddresses.RAM_A_ECHO_START);
    }
    else if(address >= MemoryAddresses.OAM_START && address < MemoryAddresses.EMPTY_A_END)
    {
      return this.oam[address - MemoryAddresses.OAM_START];
    }
    else if(address >= MemoryAddresses.IO_START)
    {
      this.readIO(address - MemoryAddresses.IO_START);
    }

    return 0xFF;
  }

  int readIO(int address)
  {
    return 0;
  }
}
