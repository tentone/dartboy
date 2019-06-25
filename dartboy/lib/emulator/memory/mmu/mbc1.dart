import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mmu.dart';

/// Memory banking chip
class MBC1 extends MMU
{
  MBC1(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);


}