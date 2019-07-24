import '../../cpu/cpu.dart';
import 'mbc.dart';

class MBC2 extends MBC
{
  MBC2(CPU cpu) : super(cpu);


  @override
  void reset()
  {
    super.reset();

    //TODO <ADD CODE HERE>
  }

  @override
  void writeByte(int address, int value)
  {
    address &= 0xFFFF;

    //TODO <ADD CODE HERE>

    super.writeByte(address, value);
  }
}