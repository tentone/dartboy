import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mmu.dart';

class MBC2 extends MMU
{
  MBC2(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);
}