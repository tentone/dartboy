import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mbc.dart';

class MBC5 extends MBC
{
  MBC5(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);
}