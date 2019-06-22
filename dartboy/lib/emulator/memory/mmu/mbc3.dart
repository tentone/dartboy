import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mmu.dart';

class MBC3 extends MMU
{
  MBC3(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);
}