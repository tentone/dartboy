import 'registers.dart';
import 'instructions.dart';
import '../cartridge.dart';
import '../memory/memory.dart';
import '../memory/memory_registers.dart';

/// CPU class is responsible for the instruction execution, interrupts and timing of the system.
///
/// Sharp LR35902
class CPU
{
  /// Frequency frequency (hz)
  static const int FREQUENCY = 4194304;

  Cartridge cartridge;

  Memory memory;

  Registers registers;

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
    this.clocks += clocks;

    this.updateInterrupts(clocks);
  }

  /// Update interrupt counter, check for interruptions waiting .
  void updateInterrupts(int clocks)
  {
    //TODO <ADD CODE HERE>
  }

  /// Fires interrupts if interrupts are enabled.
  void fireInterrupts()
  {
    // If interrupts are disabled (via the DI instruction), ignore this call
    if(!this.interruptsEnabled)
    {
      return;
    }

    /*
    // Flag of which interrupts should be triggered
    byte triggeredInterrupts = mmu.registers[R.R_TRIGGERED_INTERRUPTS];

    // Which interrupts the program is actually interested in, these are the ones we will fire
    int enabledInterrupts = mmu.registers[R.R_ENABLED_INTERRUPTS];

    // If this is nonzero, then some interrupt that we are checking for was triggered
    if ((triggeredInterrupts & enabledInterrupts) != 0)
    {
      pushWord(pc);

      // This is important
      interruptsEnabled = false;

      // Interrupt priorities are vblank > lcdc > tima overflow > serial transfer > hilo
      if (isInterruptTriggered(R.VBLANK_BIT))
      {
        pc = R.VBLANK_HANDLER_ADDRESS;
        triggeredInterrupts &= ~R.VBLANK_BIT;
      } else if (isInterruptTriggered(R.LCDC_BIT))
      {
        pc = R.LCDC_HANDLER_ADDRESS;
        triggeredInterrupts &= ~R.LCDC_BIT;
      } else if (isInterruptTriggered(R.TIMER_OVERFLOW_BIT))
      {
        pc = R.TIMER_OVERFLOW_HANDLER_ADDRESS;
        triggeredInterrupts &= ~R.TIMER_OVERFLOW_BIT;
      } else if (isInterruptTriggered(R.SERIAL_TRANSFER_BIT))
      {
        pc = R.SERIAL_TRANSFER_HANDLER_ADDRESS;
        triggeredInterrupts &= ~R.SERIAL_TRANSFER_BIT;
      } else if (isInterruptTriggered(R.HILO_BIT))
      {
        pc = R.HILO_HANDLER_ADDRESS;
        triggeredInterrupts &= ~R.HILO_BIT;
      }
      mmu.registers[R.R_TRIGGERED_INTERRUPTS] = triggeredInterrupts;
    }
    */
  }

  void reset()
  {
    this.registers.reset();
    this.memory.reset();
    this.sp = 0xFFFE;
    this.pc = 0x100;
    this.halted = false;
    this.clocks = 0;
  }

  /// Next step in the CPU processing, should be called at a fixed rate.
  void step()
  {
    execute();
  }

  /// Decode the instruction, execute it, update the CPU timer variables, check for interrupts.
  void execute()
  {
    if(this.halted)
    {
      if(this.memory.readRegisterByte(MemoryRegisters.R_TRIGGERED_INTERRUPTS) == 0)
      {
        this.clocks += 4;
      }

      this.halted = false;
    }

    int op = this.memory.readByte(this.pc);
    this.pc++;

    switch (op)
    {
      case 0x00:
        Instructions.NOP(this);
      case 0xC4:
      case 0xCC:
      case 0xD4:
      case 0xDC:
        Instructions.CALL_cc_nn(this, op);
      case 0xCD:
        Instructions.CALL_nn(this);
      case 0x01:
      case 0x11:
      case 0x21:
      case 0x31:
        Instructions.LD_dd_nn(this, op);
      case 0x06:
      case 0x0E:
      case 0x16:
      case 0x1E:
      case 0x26:
      case 0x2E:
      case 0x36:
      case 0x3E:
        Instructions.LD_r_n(this, op);
      case 0x0A:
        Instructions.LD_A_BC(this);
      case 0x1A:
        Instructions.LD_A_DE(this);
      case 0x02:
        Instructions.LD_BC_A(this);
      case 0x12:
        Instructions.LD_DE_A(this);
      case 0xF2:
        Instructions.LD_A_C(this);
      case 0xE8:
        Instructions.ADD_SP_n(this);
      case 0x37:
        Instructions.SCF(this);
      case 0x3F:
        Instructions.CCF(this);
      case 0x3A:
        Instructions.LD_A_n(this);
      case 0xEA:
        Instructions.LD_nn_A(this);
      case 0xF8:
        Instructions.LDHL_SP_n(this);
      case 0x2F:
        Instructions.CPL(this);
      case 0xE0:
        Instructions.LD_FFn_A(this);
      case 0xE2:
        Instructions.LDH_FFC_A(this);
      case 0xFA:
        Instructions.LD_A_nn(this);
      case 0x2A:
        Instructions.LD_A_HLI(this);
      case 0x22:
        Instructions.LD_HLI_A(this);
      case 0x32:
        Instructions.LD_HLD_A(this);
      case 0x10:
        Instructions.STOP(this);
      case 0xf9:
        {
          setRegisterPair(RegisterPair.SP, getRegisterPair(RegisterPair.HL));
          break;
        }
      case 0xc5: // BC
      case 0xd5: // DE
      case 0xe5: // HL
      case 0xf5: // AF
        Instructions.PUSH_rr(this, op);
      case 0xc1: // BC
      case 0xd1: // DE
      case 0xe1: // HL
      case 0xf1: // AF
        Instructions.POP_rr(this, op);
      case 0x08:
        return LD_a16Instructions._SP(this);
      case 0xd9:
        Instructions.RETI(this);
      case 0xc3:
        Instructions.JP_nn(this);
      case 0x07:
        {
          Instructions.RLCA(this);
          break;
        }
      case 0x3c: // A
      case 0x4: // B
      case 0xc: // C
      case 0x14: // D
      case 0x1c: // E
      case 0x24: // F
      case 0x34: // (HL)
      case 0x2c: // G
        {
          Instructions.INC_r(this, op);
          break;
        }
      case 0x3d: // A
      case 0x05: // B
      case 0x0d: // C
      case 0x15: // D
      case 0x1d: // E
      case 0x25: // H
      case 0x2d: // L
      case 0x35: // (HL)
        {
          Instructions.DEC_r(this, op);
          break;
        }
      case 0x3:
      case 0x13:
      case 0x23:
      case 0x33:
        {
          Instructions.INC_rr(this, op);
          break;
        }
      case 0xb8:
      case 0xb9:
      case 0xba:
      case 0xbb:
      case 0xbc:
      case 0xbd:
      case 0xbe:
      case 0xbf:
        {
          Instructions.CP_rr(this, op);
          break;
        }
      case 0xfe:
        {
          Instructions.CP_n(this);
          break;
        }
      case 0x09:
      case 0x19:
      case 0x29:
      case 0x39:
        {
          Instructions.ADD_HL_rr(this, op);
          break;
        }
      case 0xe9:
        {
          Instructions.JP_HL(this);
          break;
        }
      case 0xde:
        {
          Instructions.SBC_n(this);
          break;

        }
      case 0xd6:
        {
          Instructions.SUB_n(this);
          break;
        }
      case 0x90:
      case 0x91:
      case 0x92:
      case 0x93:
      case 0x94:
      case 0x95:
      case 0x96: // (HL)
      case 0x97:
        {
          Instructions.SUB_r(this, op);
          break;
        }
      case 0xc6:
        {
          Instructions.ADD_n(this);
          break;
        }
      case 0x87:
      case 0x80:
      case 0x81:
      case 0x82:
      case 0x83:
      case 0x84:
      case 0x85:
      case 0x86: // (HL)
        {
          Instructions.ADD_r(this, op);
          break;
        }
      case 0x88:
      case 0x89:
      case 0x8a:
      case 0x8b:
      case 0x8c:
      case 0x8e:
      case 0x8d:
      case 0x8f:
        {
          Instructions.ADC_r(this, op);
          break;
        }
      case 0xa0:
      case 0xa1:
      case 0xa2:
      case 0xa3:
      case 0xa4:
      case 0xa5:
      case 0xa6: // (HL)
      case 0xa7:
        {
          Instructions.AND_r(this, op);
          break;
        }
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
      case 0x27:
        Instructions.DAA(this);
        break;
      case 0xca:
      case 0xc2: // NZ
      case 0xd2:
      case 0xda:
        Instructions.JP_c_nn(this, op);
      case 0x20: // NZ
      case 0x28:
      case 0x30:
      case 0x38:
        Instructions.JR_c_e(this, op);
      case 0xf0:
        Instructions.LDH_FFnn(this);
        break;
      case 0x76:
        Instructions.HALT(this);
      case 0xc0: // NZ non zero (Z)
      case 0xc8: // Z zero (Z)
      case 0xd0: // NC non carry (C)
      case 0xd8: // Carry (C)
        Instructions.RET_c(this, op);
      case 0xc7:
      case 0xcf:
      case 0xd7:
      case 0xdf:
      case 0xe7:
      case 0xef:
      case 0xf7:
      case 0xff:
        Instructions.RST_p(this, op);
      case 0xf3:
        Instructions.DI(this);
        break;
      case 0xfb:
        Instructions.EI(this);
      case 0xE6:
        Instructions.AND_n(this);
        break;
      case 0xEE:
        Instructions.XOR_n(this);
        break;
      case 0xc9:
        Instructions.RET(this);
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
          case 0x40: // LD r, r'
            Instructions.LD_r_r(this, op);
            break;
          default:
            break;
            //throw new UnsupportedOperationException(cycle + "-" + Integer.toHexString(op));
        }
    }

    if(this.interruptsEnabled)
    {
        //this.fireInterrupts();
    }

    /*if (System.nanoTime() - last > 1_000_000_000)
    {
        System.err.println(last + " -- " + clockSpeed + " Hz -- " + (1.0 * cyclesExecutedThisSecond / clockSpeed));
        last = System.nanoTime();
        cyclesExecutedThisSecond = 0;
    }*/

    /*int t = 100000;
    if (cyclesSinceLastSleep >= t)
    {
        executeLock.release();
        try
        {
            if (emulateSpeed)
            {
                LockSupport.parkNanos(1_000_000_000L * t / clockSpeed + _last - System.nanoTime());
            } else
            {
                clockSpeed = (int) (1_000_000_000L * t / (System.nanoTime() - _last));
                sound.updateClockSpeed(clockSpeed);
            }
            _last = System.nanoTime();
        } catch (Exception e)
        {
            // #error there is no reason for this to fail, but if it does
            //        all we can do is printing the stacktrace for debugging
            e.printStackTrace();
        }
        executeLock.acquireUninterruptibly();
        cyclesSinceLastSleep -= t;
    }*/
  }
}