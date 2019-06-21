import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mmu.dart';

class MBC3 extends MMU
{
  MBC3(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);

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