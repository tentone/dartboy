
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

  Memory()
  {
    this.data = new List<int>(ADDRESS_SIZE - CARTRIDGE_END_ADDRESS);

    this.cartridge = new Cartridge();
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