
import 'package:dartboy/emulator/cartridge/cartridge.dart';

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
  /// The rest of the the data stored in the system after the cartridge.
  List<int> data;

  Memory(int size)
  {
    this.data = new List<int>(size);

    for(int i = 0; i < this.data.length; i++)
    {
      this.data[i] = 0;
    }
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

  /// Read a single byte from memory
  ///
  /// If the address falls into the cartridge addressing zone read directly from the cartridge object.
  int readByte(int address)
  {
    return this.data[address] & 0xFF;
  }
}