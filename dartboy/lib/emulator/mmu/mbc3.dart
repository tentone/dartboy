import '../memory/cartridge.dart';
import 'mmu.dart';

class MBC3 extends MMU
{
  MBC3(Cartridge cartridge) : super(cartridge);

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