
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

  /// The rest of the the data stored in the system after the cartridge.
  List<int> data;

  /// Size of the memory in bytes
  int size;

  Memory([int size])
  {
    if(size != null)
    {
      this.size = size;
      this.initialize();
    }
  }

  /// Initialize the memory, create the data array with the defined size.
  void initialize()
  {
    this.data = new List<int>(this.size);

    for(int i = 0; i < this.data.length; i++)
    {
      this.data[i] = 0;
    }
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
