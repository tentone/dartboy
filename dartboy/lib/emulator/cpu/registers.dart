import 'cpu.dart';

/// CPU registers, each register has 8 bits
///
/// Represents in dart as int values (dart does not support byte).
///
class Registers
{
  /// The DMG has 4 flag registers, zero, subtract, half-carry and carry.
  /// Half-carry is only ever used for the DAA instruction. Half-carry is usually carry over lower nibble, and carry is over bit 7.
  static const int F_ZERO = 0x80;
  static const int F_SUBTRACT = 0x40;
  static const int F_HALF_CARRY = 0x20;
  static const int F_CARRY = 0x10;

  static const int ADDR_BC = 0x0;
  static const int ADDR_DE = 0x1;
  static const int ADDR_HL = 0x2;
  static const int ADDR_AF = 0x3;
  static const int ADDR_SP = 0x3;

  /// CPU registers store temporally the result of the instructions.
  ///
  /// F is the flag register.
  int a, f;
  int b, c;
  int d, e;
  int h, l;

  /// Pointer to the CPU object
  CPU cpu;

  Registers(CPU cpu)
  {
    this.cpu = cpu;
    this.reset();
  }

  /// Fetches the byte value contained in a register, r is the register id as encoded by opcode.
  /// Returns the value of the register
  int getRegister(int r)
  {
    if(r == 0x7) {return a;}
    if(r == 0x0) {return b;}
    if(r == 0x1) {return c;}
    if(r == 0x2) {return d;}
    if(r == 0x3) {return e;}
    if(r == 0x4) {return h;}
    if(r == 0x5) {return l;}
    if(r == 0x6) {return cpu.mmu.readByte((h << 8) | l);}

    throw new Exception('Unknown register address getRegister().');
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// Returns the value of the register
  int getRegisterPair(int r)
  {
    if(r == 0x0) {return bc;}
    if(r == 0x1) {return de;}
    if(r == 0x2) {return hl;}
    if(r == 0x3) {return af;}

    throw new Exception('Unknown register pair address getRegisterPair().');
  }

  /// Alters the byte value contained in a register, r is the register id as encoded by opcode.
  void setRegister(int r, int value)
  {
    value &= 0xff;

    if(r == 0x7) {a = value;}
    else if(r == 0x0) {b = value;}
    else if(r == 0x1) {c = value;}
    else if(r == 0x2) {d = value;}
    else if(r == 0x3) {e = value;}
    else if(r == 0x4) {h = value;}
    else if(r == 0x5) {l = value;}
    else if(r == 0x6) {cpu.mmu.writeByte((h << 8) | l, value);}
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// Can be used with a single word value as the second argument.
  /// Returns the value of the register
  void setRegisterPair(int r, int hi, {int lo})
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

    if(r == 0x0) {b = hi; c = lo;}
    else if(r == 0x1) {d = hi; e = lo;}
    else if(r == 0x2) {h = hi; l = lo;}
    else if(r == 0x3) {a = hi; f = lo & 0xF;}
  }


  /// Reset the registers to default values
  ///
  /// (Check page 17 and 18 of the GB CPU manual)
  void reset()
  {
    a = 0x01;
    f = 0xB0;
    b = 0x00;
    c = 0x13;
    d = 0x00;
    e = 0xD8;
    h = 0x01;
    l = 0x4D;
  }

  ///Checks a condition from an opcode.
  ///Returns a boolean based off the result of the conditional.
  bool getFlag(int flag)
  {
    flag &= 0x7;

    // Condition code is in last 3 bits
    if(flag == 0x4) {return (f & F_ZERO) == 0;}
    if(flag == 0x5) {return (f & F_ZERO) != 0;}
    if(flag == 0x6) {return (f & F_CARRY) == 0;}
    if(flag == 0x7) {return (f & F_CARRY) != 0;}

    return false;
  }

  /// Set the flags on the flag register.
  ///
  /// There are four values on the upper bits of the register that are set depending on the instruction being executed.
  void setFlags(bool zero, bool subtract, bool halfCarry, bool carry)
  {
    f = zero ? f | 0x80 : f & 0x7F;
    f = subtract ? f | 0x40 : f & 0xBF;
    f = halfCarry ? f | 0x20 : f & 0xDF;
    f = carry ? f | 0x10 : f & 0xEF;
  }

  /// 16 bit mixed af register
  get af
  {
    return ((a & 0xFF) << 8) | (f & 0xFF);
  }

  set af(int value)
  {
    a = ((value & 0xFF00) >> 8);
    f = (value & 0xFF);
  }

  /// 16 bit mixed bc register
  get bc
  {
    return ((b & 0xFF) << 8) | (c & 0xFF);
  }

  set bc(int value)
  {
    b = ((value & 0xFF00) >> 8);
    c = (value & 0xFF);
  }

  /// 16 bit mixed de register
  get de
  {
    return ((d & 0xFF) << 8) | (e & 0xFF);
  }

  set de(int value)
  {
    d = ((value & 0xFF00) >> 8);
    e = (value & 0xFF);
  }

  /// 16 bit mixed hl register
  get hl
  {
    return ((h & 0xFF) << 8) | (l & 0xFF);
  }

  set hl(int value)
  {
    h = ((value & 0xFF00) >> 8);
    l = (value & 0xFF);
  }
}