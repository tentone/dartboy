
import 'cartridge.dart';

/// Implements the GBC memory model
///
/// Interrupt Enable Register FF80 - FFFF
/// Internal RAM FF4C - FF80
/// Empty but unusable for I/O FF4C - FF80
/// I/O ports FEA0 - FF00 - FF4C
/// Empty but unusable for I/O FEA0 - FF00
/// Sprite Attrib Memory (OAM) FE00 - FEA0
/// Echo of 8kB Internal RAM E000 - FE00
/// 8kB Internal RAM C000 - E000
/// 8kB switchable RAM bank A000 - C000
/// 8kB Video RAM 8000 - A000
/// 16kB switchable ROM bank 4000 - 8000 (32kB Cartridge)
/// 16kB ROM bank #0 0000 - 4000
///
/// From address 0x0000 to index 0x00FF is the bootstrap code.
/// Address 0x100 until index 0x3FFF include the contents of the cartridge (depending on the cartridge size this memory bank can change totally)
class Memory
{
  /// Total memory addressable size
  static const ADDRESS_SIZE = 65536;

  /// Cartridge end address
  static const CARTRIDGE_END_ADDRESS = 0x8000;

  /// Cartridge loaded into the system
  Cartridge cartridge;

  /// The rest of the the data stored in the system after the cartridge.
  List<int> data;

  Memory(Cartridge cartridge)
  {
    this.data = new List<int>(ADDRESS_SIZE - CARTRIDGE_END_ADDRESS);
    this.cartridge = cartridge;
  }

  /// Reset the memory to default boot values.
  ///
  /// (Check page 17 and 18 of the GB CPU manual)
  void reset()
  {
    this.writeByte(0xFF04, 0xAB);
    this.writeByte(0xFF05, 0x00);
    this.writeByte(0xFF06, 0x00);
    this.writeByte(0xFF07, 0x00);
    this.writeByte(0xFF10, 0x80);
    this.writeByte(0xFF11, 0xBF);
    this.writeByte(0xFF12, 0xF3);
    this.writeByte(0xFF14, 0xBF);
    this.writeByte(0xFF16, 0x3F);
    this.writeByte(0xFF17, 0x00);
    this.writeByte(0xFF19, 0xBF);
    this.writeByte(0xFF1A, 0x7F);
    this.writeByte(0xFF1B, 0xFF);
    this.writeByte(0xFF1C, 0x9F);
    this.writeByte(0xFF1E, 0xBF);
    this.writeByte(0xFF20, 0xFF);
    this.writeByte(0xFF21, 0x00);
    this.writeByte(0xFF22, 0x00);
    this.writeByte(0xFF23, 0xBF);
    this.writeByte(0xFF24, 0x77);
    this.writeByte(0xFF25, 0xF3);
    this.writeByte(0xFF26, this.cartridge.superGameboy ? 0xF0 : 0xF1);
    this.writeByte(0xFF40, 0x91);
    this.writeByte(0xFF42, 0x00);
    this.writeByte(0xFF43, 0x00);
    this.writeByte(0xFF45, 0x00);
    this.writeByte(0xFF47, 0xFC);
    this.writeByte(0xFF48, 0xFF);
    this.writeByte(0xFF49, 0xFF);
    this.writeByte(0xFF4A, 0x00);
    this.writeByte(0xFF4B, 0x00);
    this.writeByte(0xFFFF, 0x00);
  }

  /// Write a byte of data into memory.
  void writeByte(int address, int value)
  {
    if(address < CARTRIDGE_END_ADDRESS)
    {
      throw 'Cannot write data into ROM memory.';
    }
    else
    {
      this.data[address - CARTRIDGE_END_ADDRESS] = value & 0xFF;
    }
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

  /// Read a single byte from memory
  ///
  /// If the address falls into the cartridge addressing zone read directly from the cartridge object.
  int readByte(int address)
  {
    if(address < CARTRIDGE_END_ADDRESS)
    {
      return this.cartridge.readByte(address);
    }
    else
    {
      return this.data[address - CARTRIDGE_END_ADDRESS];
    }
  }

  /// Read 16 bits from the memory.
  ///
  /// If the address falls into the cartridge addressing zone read directly from the cartridge object.
  int readWord(int address)
  {
    if(address < CARTRIDGE_END_ADDRESS)
    {
      return this.cartridge.readWord(address);
    }
    else
    {
      return (this.data[address + 1 - CARTRIDGE_END_ADDRESS] << 8) + this.data[address - CARTRIDGE_END_ADDRESS];
    }
  }
}