import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mbc.dart';

class MBC2 extends MBC
{
  MBC2(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);


  @override
  void reset()
  {
    super.reset();

    //TODO <ADD CODE HERE>
  }

  @override
  void writeByte(int address, int value)
  {
    address &= 0xffff;
    value = value & 0xff;

    //TODO <ADD CODE HERE>

    super.writeByte(address, value);
  }
}