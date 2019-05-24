import '../../emulator/cartridge/cartridge.dart';
import '../../emulator/memory/memory.dart';

import 'mmu.dart';

class MBC1 implements MMU
{
  MBC1(Memory memory, Cartridge cartridge)
  {
    super(memory, cartridge);

  }

  @override
  int readByte(int address)
  {
    // TODO: implement readByte
  }

  @override
  void writeByte(int address, int value)
  {
    // TODO: implement writeByte
  }

}