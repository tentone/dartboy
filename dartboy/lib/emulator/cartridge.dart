
/// Stores the cartridge information and data.
///
/// Also manages the cartridge type and is responsible for the memory bank switching.
class Cartridge
{
  /// Data read from the cartridge.
  List<int> data;

  /// Cartridge name read from the
  String name;

  /// Cartridge type, there are 16 different types.
  ///
  /// Read from memory address 0x147 (Check page 11 of the GB CPU manual for details)
  int type;

  /// In cartridge ROM configuration. Read from the address 0x148.
  ///
  /// (Check page 12 of the GB CPU manual for details)
  int romType;

  /// In cartridge RAM configuration. Read from the address 0x149.
  ///
  /// (Check page 12 of the GB CPU manual for details)
  int ramType;

  /// Load cartridge byte data
  void load(List<int> data)
  {
    this.data = data;
    this.type = this.readByte(0x147);
    this.name = String.fromCharCodes(this.readBytes(0x134, 0x142));
    this.romType = this.readByte(0x148);
    this.ramType = this.readByte(0x149);
  }

  /// Read a range of bytes from the cartridge.
  List<int> readBytes(int initialAddress, int finalAddress)
  {
    return this.data.sublist(initialAddress, finalAddress);
  }

  /// Read a single byte from cartridge
  int readByte(int address)
  {
    return this.data[address] & 0xFF;
  }

  /// Read 16 bits from the cartridge
  int readWord(int address)
  {
    return ((this.data[address] << 8) | this.data[address + 1]) & 0xFFFF;
  }
}
