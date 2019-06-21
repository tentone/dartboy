import '../cpu/cpu.dart';

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

    this.wram = new List<int>(WRAM_PAGESIZE * (this.cpu.cartridge.isColorGB ? 8 : 2));
    this.wram.fillRange(0, this.wram.length, 0);

    this.vram = new List<int>(VRAM_PAGESIZE * (this.cpu.cartridge.isColorGB ? 2 : 1));
    this.vram.fillRange(0, this.vram.length, 0);
  }

  /// Read a single byte from memory
  ///
  /// If the address falls into the cartridge addressing zone read directly from the cartridge object.
  int readByte(int address)
  {
    return this.data[address];
  }

  /// Write a byte of data into memory.
  void writeByte(int address, int value)
  {
    this.data[address] = value & 0xFF;
  }

  /// Write a list of bytes into memory.
  ///
  /// Starting from the address incrementing a byte each time
  void writeBytes(int address, List<int> values)
  {
    for(int i = 0; i < values.length; i++)
    {
      this.writeByte(address, values[i]);
      address++;
    }
  }
}
