import 'cpu.dart';
import '../memory/cartridge.dart';

/// CPU registers, each register has 8 bits
///
/// Represents in dart as int values (dart does not support byte).
///
class Registers
{
  // The DMG has 4 flag registers, zero, subtract, half-carry and carry.
  static const int F_ZERO = 0x80;
  // Half-carry is only ever used for the DAA instruction. Half-carry is usually carry over lower nibble, and carry is over bit 7.
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
  int _a, _f;

  set f(int value){this._f = value & 0xFF;}
  int get f {return this._f & 0xFF;}

  set a(int value) {this._a = value & 0xFF;}
  int get a {return this._a & 0xFF;}

  int _b, _c;

  set b(int value) {this._b = value & 0xFF;}
  int get b {return this._b & 0xFF;}

  set c(int value) {this._c = value & 0xFF;}
  int get c {return this._c & 0xFF;}

  int _d, _e;

  set d(int value) {this._d = value & 0xFF;}
  int get d {return this._d & 0xFF;}

  set e(int value) {this._e = value & 0xFF;}
  int get e {return this._e & 0xFF;}

  int _h, _l;

  set h(int value) {this._h = value & 0xFF;}
  int get h {return this._h & 0xFF;}

  set l(int value) {this._l = value & 0xFF;}
  int get l {return this._l & 0xFF;}

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
    if(r == 0x7) {return this.a;}
    if(r == 0x0) {return this.b;}
    if(r == 0x1) {return this.c;}
    if(r == 0x2) {return this.d;}
    if(r == 0x3) {return this.e;}
    if(r == 0x4) {return this.h;}
    if(r == 0x5) {return this.l;}
    if(r == 0x6) {return this.cpu.mmu.readByte((h << 8) | l);}

    throw new Exception('Unknown register address getRegister().');
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// Returns the value of the register
  int getRegisterPair(int r)
  {
    if(r == 0x0) {return this.bc;}
    if(r == 0x1) {return this.de;}
    if(r == 0x2) {return this.hl;}
    if(r == 0x3) {return this.af;}

    throw new Exception('Unknown register pair address getRegisterPair().');
  }

  /// Alters the byte value contained in a register, r is the register id as encoded by opcode.
  void setRegister(int r, int value)
  {
    value &= 0xff;

    if(r == 0x7) {this.a = value;}
    else if(r == 0x0) {this.b = value;}
    else if(r == 0x1) {this.c = value;}
    else if(r == 0x2) {this.d = value;}
    else if(r == 0x3) {this.e = value;}
    else if(r == 0x4) {this.h = value;}
    else if(r == 0x5) {this.l = value;}
    else if(r == 0x6) {this.cpu.mmu.writeByte((this.h << 8) | this.l, value);}
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

    if(r == 0x0) {this.b = hi; this.c = lo;}
    else if(r == 0x1) {this.d = hi; this.e = lo;}
    else if(r == 0x2) {this.h = hi; this.l = lo;}
    else if(r == 0x3) {this.a = hi; this.f = lo & 0xF;}
  }


  /// Reset the registers to default values
  ///
  /// (Check page 17 and 18 of the GB CPU manual)
  void reset()
  {
    this.a = this.cpu.cartridge.gameboyType == GameboyType.COLOR ? 0x11 : 0x01;
    this.f = 0xB0;
    this.b = 0x00;
    this.c = 0x13;
    this.d = 0x00;
    this.e = 0xD8;
    this.h = 0x01;
    this.l = 0x4D;

    //TODO <FOR SOME REASON THERE ARE INITIALIZED DIFERENTLY IN SOME EMULATORS FOR SOME ROMS>
    /*
    this.f = 0x80;
    this.b = 0x00;
    this.c = 0x00;
    this.d = 0xFF;
    this.e = 0x56;
    this.h = 0x00;
    this.l = 0x0D;
    */
  }

  ///Checks a condition from an opcode.
  ///Returns a boolean based off the result of the conditional.
  bool getFlag(int flag)
  {
    flag &= 0x7;

    // Condition code is in last 3 bits
    if(flag == 0x4) {return (this.f & F_ZERO) == 0;}
    if(flag == 0x5) {return (this.f & F_ZERO) != 0;}
    if(flag == 0x6) {return (this.f & F_CARRY) == 0;}
    if(flag == 0x7) {return (this.f & F_CARRY) != 0;}

    return false;
  }

  /// Set the flags on the flag register.
  ///
  /// There are four values on the upper bits of the register that are set depending on the instruction being executed.
  void setFlags(bool zero, bool subtract, bool halfCarry, bool carry)
  {
    this.f = zero ? this.f | 0x80 : this.f & 0x7F;
    this.f = subtract ? this.f | 0x40 : this.f & 0xBF;
    this.f = halfCarry ? this.f | 0x20 : this.f & 0xDF;
    this.f = carry ? this.f | 0x10 : this.f & 0xEF;
  }

  /// 16 bit mixed af register
  int get af
  {
    return ((this.a & 0xFF) << 8) | (this.f & 0xFF);
  }

  set af(int value)
  {
    this.a = ((value & 0xFF00) >> 8);
    this.f = (value & 0xFF);
  }

  /// 16 bit mixed bc register
  int get bc
  {
    return ((this.b & 0xFF) << 8) | (this.c & 0xFF);
  }

  set bc(int value)
  {
    this.b = ((value & 0xFF00) >> 8);
    this.c = (value & 0xFF);
  }

  /// 16 bit mixed de register
  int get de
  {
    return ((this.d & 0xFF) << 8) | (this.e & 0xFF);
  }

  set de(int value)
  {
    this.d = ((value & 0xFF00) >> 8);
    this.e = (value & 0xFF);
  }

  /// 16 bit mixed hl register
  int get hl
  {
    return ((this.h & 0xFF) << 8) | (this.l & 0xFF);
  }

  set hl(int value)
  {
    this.h = ((value & 0xFF00) >> 8);
    this.l = (value & 0xFF);
  }
}