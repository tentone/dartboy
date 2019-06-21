import '../memory/cartridge.dart';
import '../memory/memory_registers.dart';
import '../memory/mmu/mmu.dart';
import '../graphics/ppu.dart';
import 'registers.dart';
import 'instructions.dart';

/// CPU class is responsible for the instruction execution, interrupts and timing of the system.
///
/// Sharp LR35902
class CPU
{
  /// Frequency frequency (hz)
  static const int FREQUENCY = 4194304;

  /// Game cartridge memory data composes the lower 32kB of memory from (0x0000 to 0x8000).
  Cartridge cartridge;

  /// Memory control unit decides from where the addresses are read and written to
  MMU mmu;

  /// Internal CPU registers
  Registers registers;

  /// PPU handles the graphics display
  PPU ppu;

  /// Whether the CPU is currently halted if so, it will still operate at 4MHz, but will not execute any instructions until an interrupt is cyclesExecutedThisSecond.
  /// This mode is used for power saving.
  bool halted;

  /// Whether the CPU should trigger interrupt handlers.
  bool interruptsEnabled;

  /// The current CPU clock cycle since the beginning of the emulation.
  int clocks;

  /// The number of cycles elapsed since the last speed emulation sleep.
  int cyclesSinceLastSleep;

  /// The number of cycles executed in the last second.
  int cyclesExecutedThisSecond;

  /// Indicates if the emulator is running at double speed.
  bool doubleSpeed = false;

  /// The current cycle of the DIV register.
  int divCycle = 0;

  /// The current cycle of the TIMA register.
  int timerCycle = 0;

  /// 16 bit Program Counter, the memory address of the next instruction to be fetched
  int _pc = 0;

  set pc(int value)
  {
    this._pc = value & 0xFFFF;
  }

  int get pc
  {
    return this._pc & 0xFFFF;
  }

  /// 16 bit Stack Pointer, the memory address of the top of the stack
  int sp = 0;

  CPU(Cartridge cartridge)
  {
    this.cartridge = cartridge;
    this.mmu = this.cartridge.createController(this);
    this.registers = new Registers(this);
    this.ppu = new PPU(this);

    this.reset();
  }

  /// Read the next program byte and update the PC value
  int nextUBytePC()
  {
    return this.getUByte(this.pc++);
  }

  /// Read the next program byte and update the PC value
  int nextBytePC()
  {
    return this.getByte(this.pc++);
  }

  /// Read and filter value from memory
  int getUByte(int address)
  {
    return this.getByte(address) & 0xff;
  }

  /// Read a byte from memory (takes 4 clocks)
  int getByte(int address)
  {
    this.tick(4);
    return this.mmu.readByte(address);
  }

  /// Write a byte into memory (takes 4 clocks)
  void setByte(int address, int value)
  {
    this.tick(4);
    this.mmu.writeByte(address, value);
  }

  /// Push word into the temporary stack and update the stack pointer
  void pushWordSP(int value)
  {
    this.sp -= 2;
    this.mmu.writeByte(this.sp, value & 0x00FF);
    this.mmu.writeByte(this.sp + 1, (value & 0xFF00) >> 8);
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode.
  /// It can return a register pair or the CPU SP value.
  /// Returns the value of the register
  int getRegisterPairSP(int r)
  {
    if(r == 0x0) {return this.registers.bc;}
    if(r == 0x1) {return this.registers.de;}
    if(r == 0x2) {return this.registers.hl;}
    if(r == 0x3) {return this.sp;}

    throw new Exception('Unknown register pair address getRegisterPair().');
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// It can set a register pair or the CPU SP value.
  /// Returns the value of the register
  void setRegisterPairSP(int r, int hi, {int lo})
  {
    if(lo == null)
    {
      int value = hi;
      hi = (value >> 8) & 0xFF;
      lo = value & 0xFF;
    }
    else
    {
      hi &= 0xff;
      lo &= 0xff;
    }

    if(r == 0x0)
    {
      this.registers.b = hi;
      this.registers.c = lo;
    }
    else if(r == 0x1)
    {
      this.registers.d = hi;
      this.registers.e = lo;
    }
    else if(r == 0x2)
    {
      this.registers.h = hi;
      this.registers.l = lo;
    }
    else if(r == 0x3)
    {
      this.sp = ((hi & 0xff) << 8) | lo & 0xff;
    }
  }

  ///Increase the clock cycles and trigger interrupts as needed.
  void tick(int clocks)
  {
    this.clocks += clocks;
    this.updateInterrupts(clocks);
  }

  /// Update interrupt counter, check for interruptions waiting.
  ///
  /// Trigger timer interrupts, LCD updates, and sound updates as needed.
  ///
  /// @param delta CPU cycles elapsed since the last call to this method
  void updateInterrupts(int delta)
  {
    if(this.doubleSpeed)
    {
      delta ~/= 2;
    }

    // The DIV register increments at 16KHz, and resets to 0 after
    this.divCycle += delta;

    if(this.divCycle >= 256)
    {
      this.divCycle -= 256;
      this.mmu.writeRegisterByte(MemoryRegisters.R_DIV, this.mmu.readRegisterByte(MemoryRegisters.R_DIV) + 1);
    }

    // The Timer is similar to DIV, except that when it overflows it triggers an interrupt
    int tac = this.mmu.readRegisterByte(MemoryRegisters.R_TAC);

    // If timer 3 bit is set the timer should start
    if((tac & 0x4) != 0)
    {
      this.timerCycle += delta;

      // The Timer has a settable frequency
      int timerPeriod = 0;

      switch (tac & 0x3)
      {
        // 4096 Hz
        case 0x0:
          timerPeriod = FREQUENCY ~/ 4096;
          break;
        // 262144 Hz
        case 0x1:
          timerPeriod = FREQUENCY ~/ 262144;
          break;
        // 65536 Hz
        case 0x2:
          timerPeriod = FREQUENCY ~/ 65536;
          break;
        // 16384 Hz
        case 0x3:
          timerPeriod = FREQUENCY ~/ 16384;
          break;
      }

      while(this.timerCycle >= timerPeriod)
      {
        this.timerCycle -= timerPeriod;

        // And it resets to a specific value
        int tima = (this.mmu.readRegisterByte(MemoryRegisters.R_TIMA) & 0xff) + 1;

        if(tima > 0xff)
        {
          tima = this.mmu.readRegisterByte(MemoryRegisters.R_TMA) & 0xff;
          setInterruptTriggered(MemoryRegisters.TIMER_OVERFLOW_BIT);
        }

        this.mmu.writeRegisterByte(MemoryRegisters.R_TIMA, tima & 0xff);
      }
    }

    this.ppu.tick(delta);
  }

  /// Triggers a particular interrupt by writing the correct interrupt bit to the interrupt register.
  ///
  /// @param interrupt The interrupt bit.
  void setInterruptTriggered(int interrupt)
  {
    this.mmu.writeRegisterByte(MemoryRegisters.R_TRIGGERED_INTERRUPTS, this.mmu.readRegisterByte(MemoryRegisters.R_TRIGGERED_INTERRUPTS) | interrupt);
  }

  /// Fires interrupts if interrupts are enabled.
  void fireInterrupts()
  {
    // Auxiliary method to check if an interruption was triggered.
    bool interruptTriggered(int interrupt)
    {
      return (this.mmu.readRegisterByte(MemoryRegisters.R_TRIGGERED_INTERRUPTS) & this.mmu.readRegisterByte(MemoryRegisters.R_ENABLED_INTERRUPTS) & interrupt) != 0;
    }

    // If interrupts are disabled (via the DI instruction), ignore this call
    if(!this.interruptsEnabled)
    {
      return;
    }

    // Flag of which interrupts should be triggered
    int triggeredInterrupts = this.mmu.readRegisterByte(MemoryRegisters.R_TRIGGERED_INTERRUPTS);

    // Which interrupts the program is actually interested in, these are the ones we will fire
    int enabledInterrupts =  this.mmu.readRegisterByte(MemoryRegisters.R_ENABLED_INTERRUPTS);

    // If this is nonzero, then some interrupt that we are checking for was triggered
    if((triggeredInterrupts & enabledInterrupts) != 0)
    {
      this.pushWordSP(this.pc);

      // This is important
      this.interruptsEnabled = false;

      // Interrupt priorities are vblank > lcdc > tima overflow > serial transfer > hilo
      if(interruptTriggered(MemoryRegisters.VBLANK_BIT))
      {
        this.pc = MemoryRegisters.VBLANK_HANDLER_ADDRESS;
        triggeredInterrupts &= ~MemoryRegisters.VBLANK_BIT;
      }
      else if(interruptTriggered(MemoryRegisters.LCDC_BIT))
      {
        this.pc = MemoryRegisters.LCDC_HANDLER_ADDRESS;
        triggeredInterrupts &= ~MemoryRegisters.LCDC_BIT;
      }
      else if(interruptTriggered(MemoryRegisters.TIMER_OVERFLOW_BIT))
      {
        this.pc = MemoryRegisters.TIMER_OVERFLOW_HANDLER_ADDRESS;
        triggeredInterrupts &= ~MemoryRegisters.TIMER_OVERFLOW_BIT;
      }
      else if(interruptTriggered(MemoryRegisters.SERIAL_TRANSFER_BIT))
      {
        this.pc = MemoryRegisters.SERIAL_TRANSFER_HANDLER_ADDRESS;
        triggeredInterrupts &= ~MemoryRegisters.SERIAL_TRANSFER_BIT;
      }
      else if(interruptTriggered(MemoryRegisters.HILO_BIT))
      {
        this.pc = MemoryRegisters.HILO_HANDLER_ADDRESS;
        triggeredInterrupts &= ~MemoryRegisters.HILO_BIT;
      }

      this.mmu.writeRegisterByte(MemoryRegisters.R_TRIGGERED_INTERRUPTS, triggeredInterrupts);
    }
  }

  void reset()
  {
    this.registers.reset();
    this.mmu.reset();

    this.sp = 0xFFFE;
    this.pc = 0x100;

    this.halted = false;
    this.interruptsEnabled = false;

    this.clocks = 0;
    this.cyclesSinceLastSleep = 0;
    this.cyclesExecutedThisSecond = 0;
  }

  /// Next step in the CPU processing, should be called at a fixed rate.
  void step()
  {
    this.execute();

    if(this.interruptsEnabled)
    {
      this.fireInterrupts();
    }
  }

  /// Decode the instruction, execute it, update the CPU timer variables, check for interrupts.
  void execute()
  {
    if(this.halted)
    {
      if(this.mmu.readRegisterByte(MemoryRegisters.R_TRIGGERED_INTERRUPTS) == 0)
      {
        this.clocks += 4;
      }

      this.halted = false;
    }

    int op = this.mmu.readByte(this.pc);

    if(op == null)
    {
      throw new Exception('Read null op code. (PC: 0x' + this.pc.toRadixString(16) + ')');
    }

    this.pc++;

    switch (op)
    {
      case 0x00:
        Instructions.NOP(this);
        break;
      case 0xC4:
      case 0xCC:
      case 0xD4:
      case 0xDC:
        Instructions.CALL_cc_nn(this, op);
        break;
      case 0xCD:
        Instructions.CALL_nn(this);
        break;
      case 0x01:
      case 0x11:
      case 0x21:
      case 0x31:
        Instructions.LD_dd_nn(this, op);
        break;
      case 0x06:
      case 0x0E:
      case 0x16:
      case 0x1E:
      case 0x26:
      case 0x2E:
      case 0x36:
      case 0x3E:
        Instructions.LD_r_n(this, op);
        break;
      case 0x0A:
        Instructions.LD_A_BC(this);
        break;
      case 0x1A:
        Instructions.LD_A_DE(this);
        break;
      case 0x02:
        Instructions.LD_BC_A(this);
        break;
      case 0x12:
        Instructions.LD_DE_A(this);
        break;
      case 0xF2:
        Instructions.LD_A_C(this);
        break;
      case 0xE8:
        Instructions.ADD_SP_n(this);
        break;
      case 0x37:
        Instructions.SCF(this);
        break;
      case 0x3F:
        Instructions.CCF(this);
        break;
      case 0x3A:
        Instructions.LD_A_n(this);
        break;
      case 0xEA:
          Instructions.LD_nn_A(this);
          break;
      case 0xF8:
          Instructions.LDHL_SP_n(this);
          break;
      case 0x2F:
          Instructions.CPL(this);
          break;
      case 0xE0:
          Instructions.LD_FFn_A(this);
          break;
      case 0xE2:
          Instructions.LDH_FFC_A(this);
          break;
      case 0xFA:
          Instructions.LD_A_nn(this);
          break;
      case 0x2A:
          Instructions.LD_A_HLI(this);
          break;
      case 0x22:
          Instructions.LD_HLI_A(this);
          break;
      case 0x32:
          Instructions.LD_HLD_A(this);
          break;
      case 0x10:
          Instructions.STOP(this);
          break;
      case 0xf9:
          this.setRegisterPairSP(Registers.ADDR_SP, this.registers.hl);
          break;
      case 0xc5: // BC
      case 0xd5: // DE
      case 0xe5: // HL
      case 0xf5: // AF
          Instructions.PUSH_rr(this, op);
          break;
      case 0xc1: // BC
      case 0xd1: // DE
      case 0xe1: // HL
      case 0xf1: // AF
          Instructions.POP_rr(this, op);
          break;
      case 0x08:
          Instructions.LD_a16_SP(this);
          break;
      case 0xd9:
          Instructions.RETI(this);
          break;
      case 0xc3:
          Instructions.JP_nn(this);
          break;
      case 0x07:
          Instructions.RLCA(this);
          break;
      case 0x3c: // A
      case 0x4: // B
      case 0xc: // C
      case 0x14: // D
      case 0x1c: // E
      case 0x24: // F
      case 0x34: // (HL)
      case 0x2c: // G
          Instructions.INC_r(this, op);
          break;
      case 0x3d: // A
      case 0x05: // B
      case 0x0d: // C
      case 0x15: // D
      case 0x1d: // E
      case 0x25: // H
      case 0x2d: // L
      case 0x35: // (HL)
          Instructions.DEC_r(this, op);
          break;
      case 0x3:
      case 0x13:
      case 0x23:
      case 0x33:
          Instructions.INC_rr(this, op);
          break;
      case 0xb8:
      case 0xb9:
      case 0xba:
      case 0xbb:
      case 0xbc:
      case 0xbd:
      case 0xbe:
      case 0xbf:
          Instructions.CP_rr(this, op);
          break;
      case 0xfe:
          Instructions.CP_n(this);
          break;
      case 0x09:
      case 0x19:
      case 0x29:
      case 0x39:
          Instructions.ADD_HL_rr(this, op);
          break;
      case 0xe9:
          Instructions.JP_HL(this);
          break;
      case 0xde:
          Instructions.SBC_n(this);
          break;
      case 0xd6:
          Instructions.SUB_n(this);
          break;
      case 0x90:
      case 0x91:
      case 0x92:
      case 0x93:
      case 0x94:
      case 0x95:
      case 0x96: // (HL)
      case 0x97:
          Instructions.SUB_r(this, op);
          break;
      case 0xc6:
          Instructions.ADD_n(this);
          break;
      case 0x87:
      case 0x80:
      case 0x81:
      case 0x82:
      case 0x83:
      case 0x84:
      case 0x85:
      case 0x86: // (HL)
          Instructions.ADD_r(this, op);
          break;
      case 0x88:
      case 0x89:
      case 0x8a:
      case 0x8b:
      case 0x8c:
      case 0x8e:
      case 0x8d:
      case 0x8f:
          Instructions.ADC_r(this, op);
          break;
      case 0xa0:
      case 0xa1:
      case 0xa2:
      case 0xa3:
      case 0xa4:
      case 0xa5:
      case 0xa6: // (HL)
      case 0xa7:
          Instructions.AND_r(this, op);
          break;
      case 0xa8:
      case 0xa9:
      case 0xaa:
      case 0xab:
      case 0xac:
      case 0xad:
      case 0xae:
      case 0xaf:
        Instructions.XOR_r(this, op);
        break;
      case 0xf6:
        Instructions.OR_n(this);
        break;
      case 0xb0:
      case 0xb1:
      case 0xb2:
      case 0xb3:
      case 0xb4:
      case 0xb5:
      case 0xb6: // (HL)
      case 0xb7:
        Instructions.OR_r(this, op);
        break;
      case 0x18:
        Instructions.JR_e(this);
        break;
      case 0x27:
        Instructions.DAA(this);
        break;
      case 0xca:
      case 0xc2: // NZ
      case 0xd2:
      case 0xda:
        Instructions.JP_c_nn(this, op);
        break;
      case 0x20: // NZ
      case 0x28:
      case 0x30:
      case 0x38:
        Instructions.JR_c_e(this, op);
        break;
      case 0xf0:
        Instructions.LDH_FFnn(this);
        break;
      case 0x76:
        Instructions.HALT(this);
        break;
      case 0xc0: // NZ non zero (Z)
      case 0xc8: // Z zero (Z)
      case 0xd0: // NC non carry (C)
      case 0xd8: // Carry (C)
        Instructions.RET_c(this, op);
        break;
      case 0xc7:
      case 0xcf:
      case 0xd7:
      case 0xdf:
      case 0xe7:
      case 0xef:
      case 0xf7:
      case 0xff:
        Instructions.RST_p(this, op);
        break;
      case 0xf3:
        Instructions.DI(this);
        break;
      case 0xfb:
        Instructions.EI(this);
        break;
      case 0xE6:
        Instructions.AND_n(this);
        break;
      case 0xEE:
        Instructions.XOR_n(this);
        break;
      case 0xc9:
        Instructions.RET(this);
        break;
      case 0xce:
        Instructions.ADC_n(this);
        break;
      case 0x98:
      case 0x99:
      case 0x9a:
      case 0x9b:
      case 0x9c:
      case 0x9d:
      case 0x9e: // (HL)
      case 0x9f:
        Instructions.SBC_r(this, op);
        break;
      case 0x0F: // RRCA
        Instructions.RRCA(this);
        break;
      case 0x1f: // RRA
        Instructions.RRA(this);
        break;
      case 0x17: // RLA
        Instructions.RLA(this);
        break;
      case 0x0b:
      case 0x1b:
      case 0x2b:
      case 0x3b:
        Instructions.DEC_rr(this, op);
        break;
      case 0xcb:
        Instructions.CBPrefix(this);
        break;
      default:
        switch (op & 0xC0)
        {
          case 0x40: // LD r, r
            Instructions.LD_r_r(this, op);
            break;
          default:
            throw new Exception('Unsupported operations, clocks: ' + this.clocks.toString() + ", op: " + op.toRadixString(16));
        }
    }
  }

}