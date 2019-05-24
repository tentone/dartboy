
import '../../emulator/cartridge/cartridge.dart';
import '../../emulator/memory/memory.dart';

/// The MMU (memory management unit) is used to access memory.
///
/// Depending on the cartridge type it may select different data sources and switch memory banks as required.
///
/// This is the base implementation that considers only a sing ROM bank in the cartridge and a access to the system memory.
class MMU
{
  Memory memory;

  Cartridge cartridge;

  MMU(Memory memory, Cartridge cartridge)
  {
    this.memory = memory;
    this.cartridge = cartridge;
  }

  void writeByte(int address, int value)
  {
    this.memory.writeByte(address, value);
  }

  int readByte(int address)
  {
    this.memory.readByte(address);
  }
}