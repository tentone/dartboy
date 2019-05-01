import 'registers.dart';
import 'memory.dart';

/// CPU
///
/// Sharp LR35902
class CPU
{
  /// CPU addressable memory
  Memory memory;

  /// CPU internal registers
  Registers registers;

  /// 16 bit Program Counter, the memory address of the next instruction to be fetched
  int _pc = 0;

  set pc(int value)
  {
    _pc = value & 0xFFFF;
  }

  get pc
  {
    return _pc & 0xFFFF;
  }

  /// 16 bit Stack Pointer, the memory address of the top of the stack
  int sp = 0;

  CPU()
  {
    this.registers = new Registers();

    this.memory = new Memory();
  }

  void instructionFetch()
  {

  }

  void decode()
  {

  }

  void execute()
  {

  }
}