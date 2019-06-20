import 'package:dartboy/emulator/memory/cartridge.dart';
import 'mmu.dart';

class MBC2 extends MMU
{
  MBC2(Cartridge cartridge) : super(cartridge);

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