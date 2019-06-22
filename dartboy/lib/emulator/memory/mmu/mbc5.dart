import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mmu.dart';

class MBC5 extends MMU
{
  MBC5(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);
}