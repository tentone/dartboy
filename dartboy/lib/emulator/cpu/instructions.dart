import 'registers.dart';
import 'cpu.dart';

/// Class to handle instruction implementation, instructions run on top of the CPU object.
///
/// This class is just an abstraction to make the CPU structure cleaner.
class Instructions
{
  /// Add a new state to the debug stack.
  ///
  /// The debug stack stores the operations, PC, clock count of a instruction.
  static addDebugStack(String value, CPU cpu)
  {
    if(!cpu.debugInstructions)
    {
      return;
    }

    String data = '0x' + (cpu.pc - 1).toRadixString(16) + '(' + cpu.clocks.toString() + ') [' + value + '] | ';

    data += ' AF: 0x' + cpu.registers.af.toRadixString(16) + ', ';
    data += ' BC: 0x' + cpu.registers.bc.toRadixString(16) + ', ';
    data += ' HL: 0x' + cpu.registers.hl.toRadixString(16) + ', ';
    data += ' DE: 0x' + cpu.registers.de.toRadixString(16) + ' | ';

    data += ' SP: 0x' + cpu.sp.toRadixString(16);

    print(data);
    //cpu.debugStack.add(data);
  }

  static void NOP(CPU cpu)
  {
    addDebugStack('NOP', cpu);
  }

  static void CALL_cc_nn(CPU cpu, int op)
  {
    addDebugStack('CALL_cc_nn', cpu);

    int jmp = (cpu.nextUnsignedBytePC()) | (cpu.nextUnsignedBytePC() << 8);

    if(cpu.registers.getFlag(0x4 | ((op >> 3) & 0x7)))
    {
      cpu.pushWordSP(cpu.pc);
      cpu.pc = jmp;
      cpu.tick(4);
    }
  }

  static void CALL_nn(CPU cpu)
  {
    addDebugStack('CALL_nn', cpu);

    int jmp = (cpu.nextUnsignedBytePC()) | (cpu.nextUnsignedBytePC() << 8);
    cpu.pushWordSP(cpu.pc);
    cpu.pc = jmp;
    cpu.tick(4);
  }

  static void LD_dd_nn(CPU cpu, int op)
  {
    addDebugStack('LD_dd_nn', cpu);

    cpu.setRegisterPairSP((op >> 4) & 0x3, cpu.nextUnsignedBytePC() | (cpu.nextUnsignedBytePC() << 8));
  }

  static void LD_r_n(CPU cpu, int op)
  {
    addDebugStack('LD_r_n', cpu);

    int to = (op >> 3) & 0x7;
    int n = cpu.nextUnsignedBytePC();
    cpu.registers.setRegister(to, n);
  }

  static void LD_A_BC(CPU cpu)
  {
    addDebugStack('LD_A_BC', cpu);

    cpu.registers.a = cpu.getUnsignedByte(cpu.registers.bc);
  }

  static void LD_A_DE(CPU cpu)
  {
    addDebugStack('LD_A_DE', cpu);

    cpu.registers.a = cpu.getUnsignedByte(cpu.registers.de);
  }

  static void LD_BC_A(CPU cpu)
  {
    addDebugStack('LD_BC_A', cpu);

    cpu.mmu.writeByte(cpu.registers.bc, cpu.registers.a);
  }

  static void LD_DE_A(CPU cpu)
  {
    addDebugStack('LD_DE_A', cpu);

    cpu.mmu.writeByte(cpu.registers.de, cpu.registers.a);
  }

  static void LD_A_C(CPU cpu)
  {
    addDebugStack('LD_A_C', cpu);

    cpu.registers.a = cpu.getUnsignedByte(0xFF00 | cpu.registers.c);
  }

  static void ADD_SP_n(CPU cpu)
  {
    addDebugStack('ADD_SP_n', cpu);

    int offset = cpu.nextSignedBytePC();
    int nsp = (cpu.sp + offset);

    cpu.registers.f = 0;
    int carry = nsp ^ cpu.sp ^ offset;
    
    if((carry & 0x100) != 0)
    {
      cpu.registers.f |= Registers.F_CARRY;
    }

    if((carry & 0x10) != 0)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    nsp &= 0xffff;

    cpu.sp = nsp;
    cpu.tick(4);
}

  static void SCF(CPU cpu)
  {
    addDebugStack('SCF', cpu);

    cpu.registers.f &= Registers.F_ZERO;
    cpu.registers.f |= Registers.F_CARRY;
  }

  static void CCF(CPU cpu)
  {
    addDebugStack('CCF', cpu);

    cpu.registers.f = (cpu.registers.f & Registers.F_CARRY) != 0 ? (cpu.registers.f & Registers.F_ZERO) : ((cpu.registers.f & Registers.F_ZERO) | Registers.F_CARRY);
  }

  static void LD_A_n(CPU cpu)
  {
    addDebugStack('LD_A_n', cpu);

    cpu.registers.a = cpu.getUnsignedByte(cpu.registers.hl & 0xffff);
    cpu.registers.hl = (cpu.registers.hl - 1) & 0xFFFF;
  }

  static void LD_nn_A(CPU cpu)
  {
    addDebugStack('LD_nn_A', cpu);

    cpu.mmu.writeByte(cpu.nextUnsignedBytePC() | (cpu.nextUnsignedBytePC() << 8), cpu.registers.a);
  }

  static void LDHL_SP_n(CPU cpu)
  {
    addDebugStack('LDHL_SP_n', cpu);

    int offset = cpu.nextSignedBytePC();
    int nsp = (cpu.sp + offset);

    cpu.registers.f = 0; // (short) (cpu.registers.f & Registers.F_ZERO);
    int carry = nsp ^ cpu.sp ^ offset;

    if((carry & 0x100) != 0)
    {
      cpu.registers.f |= Registers.F_CARRY;
    }
    if((carry & 0x10) != 0)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    nsp &= 0xffff;

    cpu.registers.hl =  nsp;
  }

  static void CPL(CPU cpu)
  {
    addDebugStack('CPL', cpu);

    cpu.registers.a = (~cpu.registers.a) & 0xFF;
    cpu.registers.f = (cpu.registers.f & (Registers.F_CARRY | Registers.F_ZERO)) | Registers.F_HALF_CARRY | Registers.F_SUBTRACT;
  }

  static void LD_FFn_A(CPU cpu)
  {
    addDebugStack('LD_FFn_A', cpu);

    cpu.mmu.writeByte(0xff00 | cpu.nextUnsignedBytePC(), cpu.registers.a);
  }

  static void LDH_FFC_A(CPU cpu)
  {
    addDebugStack('LDH_FFC_A', cpu);

    cpu.mmu.writeByte(0xFF00 | (cpu.registers.c & 0xFF), cpu.registers.a);
  }

  static void LD_A_nn(CPU cpu)
  {
    addDebugStack('LD_A_nn', cpu);

    int nn = cpu.nextUnsignedBytePC() | (cpu.nextUnsignedBytePC() << 8);
    cpu.registers.a = cpu.getUnsignedByte(nn);
  }

  static void LD_A_HLI(CPU cpu)
  {
    addDebugStack('LD_A_HLI', cpu);

    cpu.registers.a = cpu.getUnsignedByte(cpu.registers.hl & 0xffff);
    cpu.registers.hl =  (cpu.registers.hl + 1) & 0xffff;
  }

  static void LD_HLI_A(CPU cpu)
  {
    addDebugStack('LD_HLI_A', cpu);

    cpu.mmu.writeByte(cpu.registers.hl & 0xFFFF, cpu.registers.a);
    cpu.registers.hl =  (cpu.registers.hl + 1) & 0xffff;
  }

  static void LD_HLD_A(CPU cpu)
  {
    addDebugStack('LD_HLD_A', cpu);

    int hl = cpu.registers.hl;
    cpu.mmu.writeByte(hl, cpu.registers.a);
    cpu.registers.hl = (hl - 1) & 0xFFFF;
  }

  static void STOP(CPU cpu)
  {
    addDebugStack('STOP', cpu);

    NOP(cpu);
  }

  static void LD_r_r(CPU cpu, int op)
  {
    addDebugStack('LD_r_r', cpu);

    int from = op & 0x7;
    int to = (op >> 3) & 0x7;

    // important note: getIO(6) fetches (HL)
    cpu.registers.setRegister(to, cpu.registers.getRegister(from) & 0xFF);
  }

  static void CBPrefix(CPU cpu)
  {
    addDebugStack('CBPrefix', cpu);

    int op = cpu.getUnsignedByte(cpu.pc++);
    int reg = op & 0x7;
    int data = cpu.registers.getRegister(reg) & 0xff;

    switch(op & 0xC0)
    {
      case 0x80:
        {
          // RES b, r
          // 1 0 b b b r r r
          cpu.registers.setRegister(reg, data & ~(0x1 << (op >> 3 & 0x7)));
          return;
        }
      case 0xc0:
        {
          // SET b, r
          // 1 1 b b b r r r
          cpu.registers.setRegister(reg, data | (0x1 << (op >> 3 & 0x7)));
          return;
        }
      case 0x40:
        {
          // BIT b, r
          // 0 1 b b b r r r
          cpu.registers.f &= Registers.F_CARRY;
          cpu.registers.f |= Registers.F_HALF_CARRY;
          if((data & (0x1 << (op >> 3 & 0x7))) == 0) cpu.registers.f |= Registers.F_ZERO;
          return;
        }
      case 0x0:
        {
          switch(op & 0xf8)
          {
            case 0x00: // RLcpu.registers.c m
              {
                cpu.registers.f = 0;
                if((data & 0x80) != 0)
                {
                  cpu.registers.f |= Registers.F_CARRY;
                }
                data <<= 1;

                // we're shifting circular left, add back bit 7
                if((cpu.registers.f & Registers.F_CARRY) != 0)
                {
                  data |= 0x01;
                }

                data &= 0xff;

                if(data == 0)
                {
                  cpu.registers.f |= Registers.F_ZERO;
                }

                cpu.registers.setRegister(reg, data);
                return;
              }
            case 0x08: // RRcpu.registers.c m
              {
                cpu.registers.f = 0;
                if((data & 0x1) != 0)
                {
                  cpu.registers.f |= Registers.F_CARRY;
                }

                data >>= 1;

                // we're shifting circular right, add back bit 7
                if((cpu.registers.f & Registers.F_CARRY) != 0)
                {
                  data |= 0x80;
                }

                data &= 0xff;

                if(data == 0)
                {
                  cpu.registers.f |= Registers.F_ZERO;
                }

                cpu.registers.setRegister(reg, data);
                return;
              }
            case 0x10: // Rcpu.registers.l m
              {
                bool carryflag = (cpu.registers.f & Registers.F_CARRY) != 0;
                cpu.registers.f = 0;

                // we'll be shifting left, so if bit 7 is set we set carry
                if((data & 0x80) == 0x80)
                {
                  cpu.registers.f |= Registers.F_CARRY;
                }
                data <<= 1;
                data &= 0xff;

                // move old cpu.registers.c into bit 0
                if(carryflag)
                {
                  data |= 0x1;
                }

                if(data == 0)
                {
                  cpu.registers.f |= Registers.F_ZERO;
                }

                cpu.registers.setRegister(reg, data);
                return;
              }
            case 0x18: // RR m
              {
                bool carryflag = (cpu.registers.f & Registers.F_CARRY) != 0;
                cpu.registers.f = 0;

                // we'll be shifting right, so if bit 1 is set we set carry
                if((data & 0x1) == 0x1)
                {
                  cpu.registers.f |= Registers.F_CARRY;
                }

                data >>= 1;

                // move old cpu.registers.c into bit 7
                if(carryflag)
                {
                  data |= 0x80;
                }

                if(data == 0)
                {
                  cpu.registers.f |= Registers.F_ZERO;
                }

                cpu.registers.setRegister(reg, data);

                return;
              }
            case 0x38: // SRcpu.registers.l m
              {
                cpu.registers.f = 0;

                // we'll be shifting right, so if bit 1 is set we set carry
                if((data & 0x1) != 0)
                {
                  cpu.registers.f |= Registers.F_CARRY;
                }

                data >>= 1;

                if(data == 0)
                {
                  cpu.registers.f |= Registers.F_ZERO;
                }

                cpu.registers.setRegister(reg, data);
                return;
              }
            case 0x20: // SLcpu.registers.a m
              {
                cpu.registers.f = 0;

                // we'll be shifting right, so if bit 1 is set we set carry
                if((data & 0x80) != 0)
                {
                  cpu.registers.f |= Registers.F_CARRY;
                }

                data <<= 1;
                data &= 0xff;

                if(data == 0)
                {
                  cpu.registers.f |= Registers.F_ZERO;
                }

                cpu.registers.setRegister(reg, data);
                return;
              }
            case 0x28: // SRcpu.registers.a m
              {
                bool bit7 = (data & 0x80) != 0;
                cpu.registers.f = 0;
                if((data & 0x1) != 0)
                {
                  cpu.registers.f |= Registers.F_CARRY;
                }

                data >>= 1;

                if(bit7)
                {
                  data |= 0x80;
                }

                if(data == 0)
                {
                  cpu.registers.f |= Registers.F_ZERO;
                }

                cpu.registers.setRegister(reg, data);
                return;
              }
            case 0x30: // SWAP m
              {
                data = ((data & 0xF0) >> 4) | ((data & 0x0F) << 4);
                cpu.registers.f = data == 0 ? Registers.F_ZERO : 0;
                cpu.registers.setRegister(reg, data);
                return;
              }
            default:
              throw new Exception("CB Prefix 0xf8 operation unknown 0x" + op.toRadixString(16));
          }
          break;
        }
      default:
        throw new Exception("CB Prefix operation unknown 0x" + op.toRadixString(16));
    }
  }

  static void DEC_rr(CPU cpu, int op)
  {
    addDebugStack('DEC_rr', cpu);

    int p = (op >> 4) & 0x3;
    int o = cpu.getRegisterPairSP(p);
    cpu.setRegisterPairSP(p, o - 1);
  }

  static void RLA(CPU cpu)
  {
    addDebugStack('RLA', cpu);

    bool carryflag = (cpu.registers.f & Registers.F_CARRY) != 0;
    cpu.registers.f = 0; // &= Registers.F_ZERO;?

    // We'll be shifting left, so if bit 7 is set we set carry
    if((cpu.registers.a & 0x80) == 0x80)
    {
      cpu.registers.f |= Registers.F_CARRY;
    }
    cpu.registers.a <<= 1;
    cpu.registers.a &= 0xff;

    // Move old cpu.registers.c into bit 0
    if(carryflag)
    {
      cpu.registers.a |= 1;
    }
  }

  static void RRA(CPU cpu)
  {
    addDebugStack('RRA', cpu);

    bool carryflag = (cpu.registers.f & Registers.F_CARRY) != 0;
    cpu.registers.f = 0;

    // we'll be shifting right, so if bit 1 is set we set carry
    if((cpu.registers.a & 0x1) == 0x1)
    {
      cpu.registers.f |= Registers.F_CARRY;
    }
    cpu.registers.a >>= 1;

    // move old cpu.registers.c into bit 7
    if(carryflag){cpu.registers.a |= 0x80;}
  }

  static void RRCA(CPU cpu)
  {
    addDebugStack('RRCA', cpu);

    cpu.registers.f = 0;//Registers.F_ZERO;
    if((cpu.registers.a & 0x1) == 0x1)
    {
      cpu.registers.f |= Registers.F_CARRY;
    }
    cpu.registers.a >>= 1;

    // We're shifting circular right, add back bit 7
    if((cpu.registers.f & Registers.F_CARRY) != 0)
    {
      cpu.registers.a |= 0x80;
    }
  }

  static void SBC_r(CPU cpu, int op)
  {
    addDebugStack('SBC_r', cpu);

    int carry = (cpu.registers.f & Registers.F_CARRY) != 0 ? 1 : 0;
    int reg = cpu.registers.getRegister(op & 0x7) & 0xff;

    cpu.registers.f = Registers.F_SUBTRACT;
    if((cpu.registers.a & 0x0f) - (reg & 0x0f) - carry < 0)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    cpu.registers.a -= reg + carry;
    if(cpu.registers.a < 0)
    {
      cpu.registers.f |= Registers.F_CARRY;
      cpu.registers.a &= 0xFF;
    }

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void ADC_n(CPU cpu)
  {
    addDebugStack('ADC_n', cpu);

    int val = cpu.nextUnsignedBytePC();
    int carry = ((cpu.registers.f & Registers.F_CARRY) != 0 ? 1 : 0);
    int n = val + carry;

    cpu.registers.f = 0;

    if((((cpu.registers.a & 0xf) + (val & 0xf)) + carry & 0xF0) != 0)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    cpu.registers.a += n;

    if(cpu.registers.a > 0xFF)
    {
      cpu.registers.f |= Registers.F_CARRY;
      cpu.registers.a &= 0xFF;
    }

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void RET(CPU cpu)
  {
    addDebugStack('RET', cpu);

    cpu.pc = (cpu.getUnsignedByte(cpu.sp + 1) << 8) | cpu.getUnsignedByte(cpu.sp);
    cpu.sp += 2;
    cpu.tick(4);
}

  static void XOR_n(CPU cpu)
  {
    addDebugStack('XOR_n', cpu);

    cpu.registers.a ^= cpu.nextUnsignedBytePC();
    cpu.registers.f = 0;

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void AND_n(CPU cpu)
  {
    addDebugStack('AND_n', cpu);

    cpu.registers.a &= cpu.nextUnsignedBytePC();
    cpu.registers.f = Registers.F_HALF_CARRY;

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void EI(CPU cpu)
  {
    addDebugStack('EI', cpu);

    cpu.interruptsEnabled = true;

    // Note that during the execution of this instruction and the following instruction, maskable interrupts are disabled.
    cpu.tick(4);
    cpu.execute();
  }

  static void DI(CPU cpu)
  {
    addDebugStack('DI', cpu);

    cpu.interruptsEnabled = false;
  }

  static void RST_p(CPU cpu, int op)
  {
    addDebugStack('RST_p', cpu);

    cpu.pushWordSP(cpu.pc);
    cpu.pc = op & 0x38;
    cpu.tick(4);
}

  static void RET_c(CPU cpu, int op)
  {
    addDebugStack('RET_c', cpu);

    if(cpu.registers.getFlag(0x4 | ((op >> 3) & 0x7)))
    {
      cpu.pc = (cpu.getUnsignedByte(cpu.sp + 1) << 8) | cpu.getUnsignedByte(cpu.sp);
      cpu.sp += 2;
    }

    cpu.tick(4);
}

  static void HALT(CPU cpu)
  {
    addDebugStack('HALT', cpu);

    cpu.halted = true;
  }

  static void LDH_FFnn(CPU cpu)
  {
    addDebugStack('LDH_FFnn', cpu);

    cpu.registers.a = cpu.getUnsignedByte(0xFF00 | cpu.nextUnsignedBytePC());
  }

  static void JR_c_e(CPU cpu, int op)
  {
    addDebugStack('JR_c_e', cpu);

    int e = cpu.nextSignedBytePC();

    if(cpu.registers.getFlag((op >> 3) & 0x7))
    {
      cpu.pc += e;
      cpu.tick(4);
    }
  }

  static void JP_c_nn(CPU cpu, int op)
  {
    addDebugStack('JP_c_nn', cpu);

    int npc = cpu.nextUnsignedBytePC() | (cpu.nextUnsignedBytePC() << 8);

    if(cpu.registers.getFlag(0x4 | ((op >> 3) & 0x7)))
    {
      cpu.pc = npc;
      cpu.tick(4);
    }
  }

  static void DAA(CPU cpu)
  {
    addDebugStack('DAA', cpu);

    //TODO <CHECK DAA IMPLEMENTATION>
    
    int tmp = cpu.registers.a;

    if((cpu.registers.f & Registers.F_SUBTRACT) == 0)
    {
      if((cpu.registers.f & Registers.F_HALF_CARRY) != 0 || ((tmp & 0x0f) > 9))
      {
        tmp += 0x06;
      }
      if((cpu.registers.f & Registers.F_CARRY) != 0 || ((tmp > 0x9f)))
      {
        tmp += 0x60;
      }
    }
    else
    {
      if((cpu.registers.f & Registers.F_HALF_CARRY) != 0)
      {
        tmp = ((tmp - 6) & 0xff);
      }
      if((cpu.registers.f & Registers.F_CARRY) != 0)
      {
        tmp -= 0x60;
      }
    }

    cpu.registers.f &= Registers.F_SUBTRACT | Registers.F_CARRY;

    if(tmp > 0xff)
    {
      cpu.registers.f |= Registers.F_CARRY;
      tmp &= 0xff;
    }

    if(tmp == 0){cpu.registers.f |= Registers.F_ZERO;}

    cpu.registers.a = tmp;
  }

  static void JR_e(CPU cpu)
  {
    addDebugStack('JR_e', cpu);

    int e = cpu.nextSignedBytePC();
    cpu.pc += e;
    cpu.tick(4);
}

  static void OR(CPU cpu, int n)
  {
    addDebugStack('OR', cpu);

    cpu.registers.a |= n;
    cpu.registers.f = 0;
    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void OR_r(CPU cpu, int op)
  {
    addDebugStack('OR_r', cpu);

    OR(cpu, cpu.registers.getRegister(op & 0x7) & 0xff);
  }

  static void OR_n(CPU cpu)
  {
    addDebugStack('OR_n', cpu);

    int n = cpu.nextUnsignedBytePC();

    OR(cpu, n);
  }

  static void XOR_r(CPU cpu, int op)
  {
    addDebugStack('XOR_r', cpu);

    cpu.registers.a = (cpu.registers.a ^ cpu.registers.getRegister(op & 0x7)) & 0xff;
    cpu.registers.f = 0;

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void AND_r(CPU cpu, int op)
  {
    addDebugStack('AND_r', cpu);

    cpu.registers.a = (cpu.registers.a & cpu.registers.getRegister(op & 0x7)) & 0xff;
    cpu.registers.f = Registers.F_HALF_CARRY;

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void ADC_r(CPU cpu, int op)
  {
    addDebugStack('ADC_r', cpu);

    int carry = ((cpu.registers.f & Registers.F_CARRY) != 0 ? 1 : 0);
    int reg = (cpu.registers.getRegister(op & 0x7) & 0xff);

    int d = carry + reg;
    cpu.registers.f = 0;
    if((((cpu.registers.a & 0xf) + (reg & 0xf) + carry) & 0xF0) != 0)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    cpu.registers.a += d;

    if(cpu.registers.a > 0xFF)
    {
      cpu.registers.f |= Registers.F_CARRY;
      cpu.registers.a &= 0xFF;
    }

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void ADD(CPU cpu, int n)
  {
    addDebugStack('ADD', cpu);

    cpu.registers.f = 0;
    if((((cpu.registers.a & 0xf) + (n & 0xf)) & 0xF0) != 0)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    cpu.registers.a += n;
    if(cpu.registers.a > 0xFF)
    {
      cpu.registers.f |= Registers.F_CARRY;
      cpu.registers.a &= 0xFF;
    }

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void ADD_r(CPU cpu, int op)
  {
    addDebugStack('ADD_r', cpu);

    int n = cpu.registers.getRegister(op & 0x7) & 0xff;
    ADD(cpu, n);
  }

  static void ADD_n(CPU cpu)
  {
    addDebugStack('ADD_n', cpu);

    int n = cpu.nextUnsignedBytePC();
    ADD(cpu, n);
  }

  static void SUB(CPU cpu, int n)
  {
    addDebugStack('SUB', cpu);

    cpu.registers.f = Registers.F_SUBTRACT;
    if((cpu.registers.a & 0xf) - (n & 0xf) < 0)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    cpu.registers.a -= n;
    if((cpu.registers.a & 0xFF00) != 0)
    {
      cpu.registers.f |= Registers.F_CARRY;
    }

    cpu.registers.a &= 0xFF;
    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void SUB_r(CPU cpu, int op)
  {
    addDebugStack('SUB_r', cpu);

    int n = cpu.registers.getRegister(op & 0x7) & 0xff;

    SUB(cpu, n);
  }

  static void SUB_n(CPU cpu)
  {
    addDebugStack('SUB_n', cpu);

    int n = cpu.nextUnsignedBytePC();

    SUB(cpu, n);
  }

  static void SBC_n(CPU cpu)
  {
    addDebugStack('SBC_n', cpu);

    int val = cpu.nextUnsignedBytePC();
    int carry = ((cpu.registers.f & Registers.F_CARRY) != 0 ? 1 : 0);
    int n = val + carry;

    cpu.registers.f = Registers.F_SUBTRACT;

    if((cpu.registers.a & 0xf) - (val & 0xf) - carry < 0)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    cpu.registers.a -= n;

    if(cpu.registers.a < 0)
    {
      cpu.registers.f |= Registers.F_CARRY;
      cpu.registers.a &= 0xff;
    }

    if(cpu.registers.a == 0)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }
  }

  static void JP_HL(CPU cpu)
  {
    addDebugStack('JP_HL', cpu);

    cpu.pc = cpu.registers.hl & 0xFFFF;
  }

  static void ADD_HL_rr(CPU cpu, int op)
  {
    addDebugStack('ADD_HL_rr', cpu);

    // Z is not affected cpu.registers.h is set if carry out of bit 11; reset otherwise
    // N is reset cpu.registers.c is set if carry from bit 15; reset otherwise
    int ss = cpu.getRegisterPairSP((op >> 4) & 0x3);
    int hl = cpu.registers.hl;

    cpu.registers.f &= Registers.F_ZERO;

    if(((hl & 0xFFF) + (ss & 0xFFF)) > 0xFFF)
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }

    hl += ss;

    if(hl > 0xFFFF)
    {
      cpu.registers.f |= Registers.F_CARRY;
      hl &= 0xFFFF;
    }

    cpu.registers.hl =  hl;
  }

  static void CP(CPU cpu, int n)
  {
    addDebugStack('CP', cpu);

    cpu.registers.f = Registers.F_SUBTRACT;

    if(cpu.registers.a < n)
    {
      cpu.registers.f |= Registers.F_CARRY;
    }
    else if(cpu.registers.a == n)
    {
      cpu.registers.f |= Registers.F_ZERO;
    }

    if((cpu.registers.a & 0xf) < ((cpu.registers.a - n) & 0xf))
    {
      cpu.registers.f |= Registers.F_HALF_CARRY;
    }
  }

  static void CP_n(CPU cpu)
  {
    addDebugStack('CP_n', cpu);

    CP(cpu, cpu.nextUnsignedBytePC());
  }

  static void CP_rr(CPU cpu, int op)
  {
    addDebugStack('CP_rr', cpu);

    CP(cpu, cpu.registers.getRegister(op & 0x7) & 0xFF);
  }

  static void INC_rr(CPU cpu, int op)
  {
    addDebugStack('INC_rr', cpu);

    int pair = (op >> 4) & 0x3;
    int o = cpu.getRegisterPairSP(pair) & 0xffff;
    cpu.setRegisterPairSP(pair, o + 1);
  }

  static void DEC_r(CPU cpu, int op)
  {
    addDebugStack('DEC_r', cpu);

    int reg = (op >> 3) & 0x7;
    int a = cpu.registers.getRegister(reg) & 0xff;

    cpu.registers.f = (cpu.registers.f & Registers.F_CARRY) | InstructionTables.DEC[a];

    a = (a - 1) & 0xff;

    cpu.registers.setRegister(reg, a);
  }

  static void INC_r(CPU cpu, int op)
  {
    addDebugStack('INC_r', cpu);

    int reg = (op >> 3) & 0x7;
    int a = cpu.registers.getRegister(reg) & 0xff;

    cpu.registers.f = (cpu.registers.f & Registers.F_CARRY) | InstructionTables.INC[a];

    a = (a + 1) & 0xff;

    cpu.registers.setRegister(reg, a);
  }

  static void RLCA(CPU cpu)
  {
    addDebugStack('RLCA', cpu);

    bool carry = (cpu.registers.a & 0x80) != 0;
    cpu.registers.a <<= 1;
    cpu.registers.f = 0; // &= Registers.F_ZERO?

    if(carry)
    {
      cpu.registers.f |= Registers.F_CARRY;
      cpu.registers.a |= 1;
    }
    else
    {
      cpu.registers.f = 0;
    }

    cpu.registers.a &= 0xff;
  }

  static void JP_nn(CPU cpu)
  {
    addDebugStack('JP_nn', cpu);

    cpu.pc = (cpu.nextUnsignedBytePC()) | (cpu.nextUnsignedBytePC() << 8);
    cpu.tick(4);
  }

  static void RETI(CPU cpu)
  {
    addDebugStack('RETI', cpu);

    cpu.interruptsEnabled = true;
    cpu.pc = (cpu.getUnsignedByte(cpu.sp + 1) << 8) | cpu.getUnsignedByte(cpu.sp);
    cpu.sp += 2;
    cpu.tick(4);
  }

  static void LD_a16_SP(CPU cpu)
  {
    addDebugStack('LD_a16_SP', cpu);

    int pos = ((cpu.nextUnsignedBytePC()) | (cpu.nextUnsignedBytePC() << 8));
    cpu.mmu.writeByte(pos + 1, (cpu.sp & 0xFF00) >> 8);
    cpu.mmu.writeByte(pos, (cpu.sp & 0x00FF));
  }

  static void POP_rr(CPU cpu, int op)
  {
    addDebugStack('POP_rr', cpu);

    cpu.registers.setRegisterPair((op >> 4) & 0x3, cpu.getSignedByte(cpu.sp + 1), lo: cpu.getSignedByte(cpu.sp));
    cpu.sp += 2;
  }

  static void PUSH_rr(CPU cpu, int op)
  {
    addDebugStack('PUSH_rr', cpu);

    int val = cpu.registers.getRegisterPair((op >> 4) & 0x3);
    cpu.pushWordSP(val);
    cpu.tick(4);
  }
}

/// Instructions execution table used for faster execution of some instructions.
///
/// All possible values are pre calculated based on the instruction input.
class InstructionTables
{
  /// for A in range(0x100):
  ///     F = F_N
  ///     if((A & 0xf) - 1 < 0): F |= F_H
  ///     if A - 1 == 0: F |= F_Z
  ///     DEC[A] = F
  static const List<int> DEC = [96, 192, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64,
  64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
  64, 64, 96, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64];

  /// for A in range(0x100):
  ///     F = 0
  ///     if((((A & 0xf) + 1) & 0xF0) != 0): F |= F_H
  ///     if(A + 1 > 0xff): F |= F_Z
  ///     INC[A] = F
  static const List<int> INC = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 160];
}