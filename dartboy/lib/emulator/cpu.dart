import 'registers.dart';
import 'memory.dart';

/// CPU
///
/// Sharp LR35902
class CPU
{
  /// Frequency hz
  static const int FREQUENCY = 4194304;

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

  void reset()
  {
    this.registers.reset();
    this.memory.reset();
    this.sp = 0xFFFE;
    this.pc = 0x100;
  }
  void step()
  {
    int instruction = this.memory.readByte(this.pc);
    this.pc = execute(instruction);
  }

  /// Decode the instruction execute it and return the next PC address
  int execute(int instruction)
  {
    // Pre filter instruction value
    instruction &= 0xFF;

    //TODO <ADD CODE HERE>

    return this.pc + 1;
  }
}