import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mbc.dart';

class MBC2 extends MBC
{
  MBC2(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);
}