import 'registers.dart';
import '../cartridge.dart';
import '../memory.dart';

/// CPU
///
/// Sharp LR35902
class CPU
{
  /// Frequency hz
  static const int FREQUENCY = 4194304;

  Cartridge cartridge;

  Memory memory;

  Registers registers;

  /// Whether the CPU is currently halted if so, it will still operate at 4MHz, but will not execute any instructions until an interrupt is cyclesExecutedThisSecond.
  /// This mode is used for power saving.
  bool halted;

  /// The current CPU clock cycle since the beginning of the emulation.
  int clock;

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

  CPU(Cartridge cartridge)
  {
    this.cartridge = cartridge;
    this.registers = new Registers(this);
    this.memory = new Memory(this.cartridge);
  }

  ///Increase the clock cycles and trigger interrupts as needed.
  void tick(int clocks)
  {
    this.clock += clocks;

    this.processInterrupts(clocks);
  }

  /// Update interrupt counter, check for interruptions waiting .
  void processInterrupts(int clocks)
  {
    //TODO <ADD CODE HERE>
  }

  void reset()
  {
    this.registers.reset();
    this.memory.reset();
    this.sp = 0xFFFE;
    this.pc = 0x100;
    this.halted = false;
    this.clock = 0;
  }

  void step()
  {
    int instruction = this.memory.readByte(this.pc);

    this.pc = execute(instruction);
  }

  /// Decode the instruction execute it and return the next PC address
  int execute(int instruction)
  {

    //TODO <ADD CODE HERE>

    return this.pc + 1;
  }
}