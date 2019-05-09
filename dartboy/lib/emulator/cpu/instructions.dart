import 'cpu.dart';

/// Class to handle instruction implementation, instructions run on top of the CPU object.
///
/// This class is just an abstraction to make the CPU structure cleaner.
class Instructions
{
  static int NOP(CPU cpu)
  {
    return 0;
  }

  static int CALL_cc_nn(CPU cpu, int op)
  {
    int jmp = (nextUByte()) | (nextUByte() << 8);

    if(getConditionalFlag(0b100 | ((op >> 3) & 0x7)))
    {
      pushWord(cpu.pc);
      cpu.pc = jmp;
      return 4;
    }
    return 0;
  }

  static int CALL_nn(CPU cpu)
  {
    int jmp = (nextUByte()) | (nextUByte() << 8);
    pushWord(cpu.pc);
    cpu.pc = jmp;
    return 4;
  }

  static int LD_dd_nn(CPU cpu, int op)
  {
    setRegisterPair(RegisterPair.byValue[(op >> 4) & 0x3], nextUByte() | (nextUByte() << 8));
    return 0;
  }

  static int LD_r_n(CPU cpu, int op)
  {
    int to = (op >> 3) & 0x7;
    int n = nextUByte();
    setRegister(to, n);
    return 0;
  }

  static int LD_A_BC(CPU cpu)
  {
    A = getUByte(getRegisterPair(RegisterPair.BC));
    return 0;
  }

  static int LD_A_DE(CPU cpu)
  {
    A = getUByte(getRegisterPair(RegisterPair.DE));
    return 0;
  }

  static int LD_BC_A(CPU cpu)
  {
    setByte(getRegisterPair(RegisterPair.BC), A);
    return 0;
  }

  static int LD_DE_A(CPU cpu)
  {
    setByte(getRegisterPair(RegisterPair.DE), A);
    return 0;
  }

  static int LD_A_C(CPU cpu)
  {
    A = getUByte(0xFF00 | C);
    return 0;
  }

  static int ADD_SP_n(CPU cpu)
  {
    int offset = nextByte();
    int nsp = (SP + offset);

    F = 0;
    int carry = nsp ^ SP ^ offset;
    if ((carry & 0x100) != 0) F |= F_C;
    if ((carry & 0x10) != 0) F |= F_H;

    nsp &= 0xffff;

    SP = nsp;
    return 4;
  }

  static int SCF(CPU cpu)
  {
    F &= F_Z;
    F |= F_C;
    return 0;
  }

  static int CCF(CPU cpu)
  {
    F = (F & F_C) != 0 ? (F & F_Z) : ((F & F_Z) | F_C);
    return 0;
  }

  static int LD_A_n(CPU cpu)
  {
    A = getUByte(getRegisterPair(RegisterPair.HL) & 0xffff);
    setRegisterPair(RegisterPair.HL, (getRegisterPair(RegisterPair.HL) - 1) & 0xFFFF);
    return 0;
  }

  static int LD_nn_A(CPU cpu)
  {
    setByte(nextUByte() | (nextUByte() << 8), A);
    return 0;
  }

  static int LDHL_SP_n(CPU cpu)
  {
    int offset = nextByte();
    int nsp = (SP + offset);

    F = 0; // (short) (F & F_Z);
    int carry = nsp ^ SP ^ offset;
    if ((carry & 0x100) != 0) F |= F_C;
    if ((carry & 0x10) != 0) F |= F_H;
    nsp &= 0xffff;

    setRegisterPair(RegisterPair.HL, nsp);
    return 0;
  }

  static int CPL(CPU cpu)
  {
    A = (~A) & 0xFF;
    F = (F & (F_C | F_Z)) | F_H | F_N;
    return 0;
  }

  static int LD_FFn_A(CPU cpu)
  {
    setByte(0xff00 | nextUByte(), A);
    return 0;
  }

  static int LDH_FFC_A(CPU cpu)
  {
    setByte(0xFF00 | (C & 0xFF), A);
    return 0;
  }

  static int LD_A_nn(CPU cpu)
  {
    int nn = nextUByte() | (nextUByte() << 8);
    A = getUByte(nn);
    return 0;
  }

  static int LD_A_HLI(CPU cpu)
  {
    A = getUByte(getRegisterPair(RegisterPair.HL) & 0xffff);
    setRegisterPair(RegisterPair.HL, (getRegisterPair(RegisterPair.HL) + 1) & 0xFFFF);
    return 0;
  }

  static int LD_HLI_A(CPU cpu)
  {
    setByte(getRegisterPair(RegisterPair.HL) & 0xFFFF, A);
    setRegisterPair(RegisterPair.HL, (getRegisterPair(RegisterPair.HL) + 1) & 0xFFFF);
    return 0;
  }

  static int LD_HLD_A(CPU cpu)
  {
    int hl = getRegisterPair(RegisterPair.HL);
    setByte(hl, A);
    setRegisterPair(RegisterPair.HL, (hl - 1) & 0xFFFF);

    return 0;
  }

  static int STOP(CPU cpu)
  {
    return NOP();
  }

  static void LD_r_r(CPU cpu, int op)
  {
    int from = op & 0x7;
    int to = (op >> 3) & 0x7;

    // important note: getIO(6) fetches (HL)
    setRegister(to, getRegister(from) & 0xFF);
  }

  static void CBPrefix(CPU cpu)
  {
    int x = cpu.pc++;

    int cbop = getUByte(x);
    int r = cbop & 0x7;
    int d = getRegister(r) & 0xff;

    switch ((cbop & 0b11000000))
    {
      case 0x80:
        {
          // RES b, r
          // 1 0 b b b r r r
          setRegister(r, d & ~(0x1 << (cbop >> 3 & 0x7)));
          return;
        }
      case 0xc0:
        {
          // SET b, r
          // 1 1 b b b r r r
          setRegister(r, d | (0x1 << (cbop >> 3 & 0x7)));
          return;
        }
      case 0x40:
        {
          // BIT b, r
          // 0 1 b b b r r r
          F &= F_C;
          F |= F_H;
          if ((d & (0x1 << (cbop >> 3 & 0x7))) == 0) F |= F_Z;
          return;
        }
      case 0x0:
        {
          switch (cbop & 0xf8)
          {
            case 0x00: // RLC m
              {
                F = 0;
                if ((d & 0x80) != 0) F |= F_C;
                d <<= 1;

                // we're shifting circular left, add back bit 7
                if ((F & F_C) != 0) d |= 0x01;
                d &= 0xff;
                if (d == 0) F |= F_Z;
                setRegister(r, d);
                return;
              }
            case 0x08: // RRC m
              {
                F = 0;
                if ((d & 0b1) != 0) F |= F_C;
                d >>= 1;

                // we're shifting circular right, add back bit 7
                if ((F & F_C) != 0) d |= 0x80;
                d &= 0xff;
                if (d == 0) F |= F_Z;
                setRegister(r, d);
                return;
              }
            case 0x10: // RL m
              {
                boolean carryflag = (F & F_C) != 0;
                F = 0;

                // we'll be shifting left, so if bit 7 is set we set carry
                if ((d & 0x80) == 0x80) F |= F_C;
                d <<= 1;
                d &= 0xff;

                // move old C into bit 0
                if (carryflag) d |= 0b1;
                if (d == 0) F |= F_Z;
                setRegister(r, d);
                return;
              }
            case 0x18: // RR m
              {
                boolean carryflag = (F & F_C) != 0;
                F = 0;

                // we'll be shifting right, so if bit 1 is set we set carry
                if ((d & 0x1) == 0x1) F |= F_C;
                d >>= 1;

                // move old C into bit 7
                if (carryflag) d |= 0b10000000;
                if (d == 0) F |= F_Z;
                setRegister(r, d);
                return;
              }
            case 0x38: // SRL m
              {
                F = 0;

                // we'll be shifting right, so if bit 1 is set we set carry
                if ((d & 0x1) != 0) F |= F_C;
                d >>= 1;
                if (d == 0) F |= F_Z;
                setRegister(r, d);
                return;
              }
            case 0x20: // SLA m
              {
                F = 0;

                // we'll be shifting right, so if bit 1 is set we set carry
                if ((d & 0x80) != 0) F |= F_C;
                d <<= 1;
                d &= 0xff;
                if (d == 0) F |= F_Z;
                setRegister(r, d);
                return;
              }
            case 0x28: // SRA m
              {
                boolean bit7 = (d & 0x80) != 0;
                F = 0;
                if ((d & 0b1) != 0) F |= F_C;
                d >>= 1;
                if (bit7) d |= 0x80;
                if (d == 0) F |= F_Z;
                setRegister(r, d);
                return;
              }
            case 0x30: // SWAP m
              {
                d = ((d & 0xF0) >> 4) | ((d & 0x0F) << 4);
                F = d == 0 ? F_Z : 0;
                setRegister(r, d);
                return;
              }
            default:
              throw new UnsupportedOperationException("cb-&f8-" + Integer.toHexString(cbop));
          }
        }
      default:
        throw new UnsupportedOperationException("cb-" + Integer.toHexString(cbop));
    }
  }

  static void DEC_rr(CPU cpu, int op)
  {
    RegisterPair p = RegisterPair.byValue[(op >> 4) & 0x3];
    int o = getRegisterPair(p);
    setRegisterPair(p, o - 1);
  }

  static void RLA(CPU cpu)
  {
    boolean carryflag = (F & F_C) != 0;
    F = 0; // &= F_Z;?

    // we'll be shifting left, so if bit 7 is set we set carry
    if ((A & 0x80) == 0x80) F |= F_C;
    A <<= 1;
    A &= 0xff;

    // move old C into bit 0
    if (carryflag) A |= 1;
  }

  static void RRA(CPU cpu)
  {
    boolean carryflag = (F & F_C) != 0;
    F = 0;

    // we'll be shifting right, so if bit 1 is set we set carry
    if ((A & 0x1) == 0x1) F |= F_C;
    A >>= 1;

    // move old C into bit 7
    if (carryflag) A |= 0x80;
  }

  static void RRCA(CPU cpu)
  {
    F = 0;//F_Z;
    if ((A & 0x1) == 0x1) F |= F_C;
    A >>= 1;

    // we're shifting circular right, add back bit 7
    if ((F & F_C) != 0) A |= 0x80;
  }

  static void SBC_r(CPU cpu, int op)
  {
    int carry = (F & F_C) != 0 ? 1 : 0;
    int reg = getRegister(op & 0b111) & 0xff;

    F = F_N;
    if ((A & 0x0f) - (reg & 0x0f) - carry < 0) F |= F_H;
    A -= reg + carry;
    if (A < 0)
    {
      F |= F_C;
      A &= 0xFF;
    }
    if (A == 0) F |= F_Z;
  }

  static void ADC_n(CPU cpu)
  {
    int val = nextUByte();
    int carry = ((F & F_C) != 0 ? 1 : 0);
    int n = val + carry;

    F = 0;
    if ((((A & 0xf) + (val & 0xf)) + carry & 0xF0) != 0) F |= F_H;
    A += n;
    if (A > 0xFF)
    {
      F |= F_C;
      A &= 0xFF;
    }
    if (A == 0) F |= F_Z;
  }

  static int RET(CPU cpu)
  {
    cpu.pc = (getUByte(SP + 1) << 8) | getUByte(SP);
    SP += 2;
    return 4;
  }

  static void XOR_n(CPU cpu)
  {
    A ^= nextUByte();
    F = 0;
    if (A == 0) F |= F_Z;
  }

  static void AND_n(CPU cpu)
  {
    A &= nextUByte();
    F = F_H;
    if (A == 0) F |= F_Z;
  }

  static int EI(CPU cpu)
  {
    cpu.interruptsEnabled = true;

    // Note that during the execution of this instruction and the following instruction,
    // maskable interrupts are disabled.

    // we still need to increment div etc
    tick(4);
    return _exec();
  }

  static void DI(CPU cpu)
  {
    cpu.interruptsEnabled = false;
  }

  static int RST_p(CPU cpu, int op)
  {
    pushWord(cpu.pc);
    cpu.pc = op & 0b00111000;
    return 4;
  }

  static int RET_c(CPU cpu, int op)
  {
    if (getConditionalFlag(0b100 | ((op >> 3) & 0x7)))
    {
    cpu.pc = (getUByte(SP + 1) << 8) | getUByte(SP);
    SP += 2;
    }
    return 4;
  }

  static int HALT(CPU cpu)
  {
    cpuHalted = true;
    return 0;
  }

  static void LDH_FFnn(CPU cpu)
  {
    A = getUByte(0xFF00 | nextUByte());
  }

  static int JR_c_e(CPU cpu, int op)
  {
    int e = nextByte();
    if (getConditionalFlag((op >> 3) & 0b111))
    {
      cpu.pc += e;
      return 4;
    }
    return 0;
  }

  static int JP_c_nn(CPU cpu, int op)
  {
    int ncpu.pc = nextUByte() | (nextUByte() << 8);
    if (getConditionalFlag(0b100 | ((op >> 3) & 0x7)))
    {
    cpu.pc = ncpu.pc;
    return 4;
    }
    return 0;
  }

  static void DAA(CPU cpu)
  {
    // TODO warning: this might be implemented wrong!
    /**
     * <code><pre>tmp := a,
     * if nf then
     *      if hf or [a AND 0x0f > 9] then tmp -= 0x06
     *      if cf or [a > 0x99] then tmp -= 0x60
     * else
     *      if hf or [a AND 0x0f > 9] then tmp += 0x06
     *      if cf or [a > 0x99] then tmp += 0x60
     * endif,
     * tmp => flags, cf := cf OR [a > 0x99],
     * hf := a.4 XOR tmp.4, a := tmp
     * </pre>
     * </code>
     * @see http://wikiti.brandonw.net/?title=Z80_Instruction_Set
     */
    int tmp = A;
    if ((F & F_N) == 0)
    {
      if ((F & F_H) != 0 || ((tmp & 0x0f) > 9)) tmp += 0x06;
      if ((F & F_C) != 0 || ((tmp > 0x9f))) tmp += 0x60;
    } else
    {
      if ((F & F_H) != 0) tmp = ((tmp - 6) & 0xff);
      if ((F & F_C) != 0) tmp -= 0x60;
    }
    F &= F_N | F_C;

    if (tmp > 0xff)
    {
      F |= F_C;
      tmp &= 0xff;
    }

    if (tmp == 0) F |= F_Z;

    A = tmp;
  }

  static int JR_e(CPU cpu)
  {
    int e = nextByte();
    cpu.pc += e;
    return 4;
  }

  static void OR(CPU cpu, int n)
  {
    A |= n;
    F = 0;
    if (A == 0) F |= F_Z;
  }

  static void OR_r(CPU cpu, int op)
  {
    OR(getRegister(op & 0b111) & 0xff);
  }

  static void OR_n(CPU cpu)
  {
    int n = nextUByte();
    OR(n);
  }

  static void XOR_r(CPU cpu, int op)
  {
    A = (A ^ getRegister(op & 0b111)) & 0xff;
    F = 0;
    if (A == 0) F |= F_Z;
  }

  static void AND_r(CPU cpu, int op)
  {
    A = (A & getRegister(op & 0b111)) & 0xff;
    F = F_H;
    if (A == 0) F |= F_Z;
  }

  static void ADC_r(CPU cpu, int op)
  {
    int carry = ((F & F_C) != 0 ? 1 : 0);
    int reg = (getRegister(op & 0b111) & 0xff);

    int d = carry + reg;
    F = 0;
    if ((((A & 0xf) + (reg & 0xf) + carry) & 0xF0) != 0) F |= F_H;

    A += d;
    if (A > 0xFF)
    {
      F |= F_C;
      A &= 0xFF;
    }
    if (A == 0) F |= F_Z;
  }

  static void ADD(CPU cpu, int n)
  {
    F = 0;
    if ((((A & 0xf) + (n & 0xf)) & 0xF0) != 0) F |= F_H;
    A += n;
    if (A > 0xFF)
    {
      F |= F_C;
      A &= 0xFF;
    }
    if (A == 0) F |= F_Z;
  }

  static void ADD_r(CPU cpu, int op)
  {
    int n = getRegister(op & 0b111) & 0xff;
    ADD(n);
  }

  static void ADD_n(CPU cpu)
  {
    int n = nextUByte();
    ADD(n);
  }

  static void SUB(CPU cpu, int n)
  {
    F = F_N;
    if ((A & 0xf) - (n & 0xf) < 0) F |= F_H;
    A -= n;
    if ((A & 0xFF00) != 0) F |= F_C;
    A &= 0xFF;
    if (A == 0) F |= F_Z;
  }

  static void SUB_r(CPU cpu, int op)
  {
    int n = getRegister(op & 0b111) & 0xff;
    SUB(n);
  }

  static void SUB_n(CPU cpu)
  {
    int n = nextUByte();
    SUB(n);
  }

  static void SBC_n(CPU cpu)
  {
    int val = nextUByte();
    int carry = ((F & F_C) != 0 ? 1 : 0);
    int n = val + carry;

    F = F_N;
    if ((A & 0xf) - (val & 0xf) - carry < 0) F |= F_H;
    A -= n;
    if (A < 0)
    {
      F |= F_C;
      A &= 0xff;
    }
    if (A == 0) F |= F_Z;
  }

  static void JP_HL(CPU cpu)
  {
    cpu.pc = getRegisterPair(RegisterPair.HL) & 0xFFFF;
  }

  static void ADD_HL_rr(CPU cpu, int op)
  {
    /**
     * Z is not affected
     * H is set if carry out of bit 11; reset otherwise
     * N is reset
     * C is set if carry from bit 15; reset otherwise
     */
    int ss = getRegisterPair(RegisterPair.byValue[(op >> 4) & 0x3]);
    int hl = getRegisterPair(RegisterPair.HL);

    F &= F_Z;

    if (((hl & 0xFFF) + (ss & 0xFFF)) > 0xFFF)
    {
      F |= F_H;
    }

    hl += ss;

    if (hl > 0xFFFF)
    {
      F |= F_C;
      hl &= 0xFFFF;
    }

    setRegisterPair(RegisterPair.HL, hl);
  }

  static void CP(CPU cpu, int n)
  {
    F = F_N;
    if (A < n) F |= F_C;
    if (A == n) F |= F_Z;
    if ((A & 0xf) < ((A - n) & 0xf)) F |= F_H;
  }

  static void CP_n(CPU cpu)
  {
    int n = nextUByte();
    CP(n);
  }

  static void CP_rr(CPU cpu, int op)
  {
    int n = getRegister(op & 0x7) & 0xFF;
    CP(n);
  }

  static void INC_rr(CPU cpu, int op)
  {
    RegisterPair pair = RegisterPair.byValue[(op >> 4) & 0x3];
    int o = getRegisterPair(pair) & 0xffff;
    setRegisterPair(pair, o + 1);
  }

  static void DEC_r(CPU cpu, int op)
  {
    int reg = (op >> 3) & 0x7;
    int a = getRegister(reg) & 0xff;

    F = (F & F_C) | Tables.DEC[a];

    a = (a - 1) & 0xff;

    setRegister(reg, a);
  }

  static void INC_r(CPU cpu, int op)
  {
    int reg = (op >> 3) & 0x7;
    int a = getRegister(reg) & 0xff;

    F = (F & F_C) | Tables.INC[a];

    a = (a + 1) & 0xff;

    setRegister(reg, a);
  }

  static void RLCA(CPU cpu)
  {
    boolean carry = (A & 0x80) != 0;
    A <<= 1;
    F = 0; // &= F_Z?
    if (carry)
    {
      F |= F_C;
      A |= 1;
    } else F = 0;
    A &= 0xff;
  }

  static int JP_nn(CPU cpu)
  {
    cpu.pc = (nextUByte()) | (nextUByte() << 8);
    return 4;
  }

  static int RETI(CPU cpu)
  {
    cpu.interruptsEnabled = true;
    cpu.pc = (getUByte(SP + 1) << 8) | getUByte(SP);
    SP += 2;
    return 4;
  }

  static int LD_a16_SP()
  {
    int pos = ((nextUByte()) | (nextUByte() << 8));
    setByte(pos + 1, (SP & 0xFF00) >> 8);
    setByte(pos, (SP & 0x00FF));
    return 0;
  }

  static int POP_rr(CPU cpu, int op)
  {
    setRegisterPair2(RegisterPair.byValue[(op >> 4) & 0x3], getByte(SP + 1), getByte(SP));
    SP += 2;
    return 0;
  }

  static int PUSH_rr(CPU cpu, int op)
  {
    int val = getRegisterPair2(RegisterPair.byValue[(op >> 4) & 0x3]);
    pushWord(val);
    return 4;
  }
}