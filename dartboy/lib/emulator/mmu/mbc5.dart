import '../../emulator/cartridge/cartridge.dart';
import 'mmu.dart';

class MBC5 extends MMU
{
  MBC5(Cartridge cartridge) : super(cartridge);

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