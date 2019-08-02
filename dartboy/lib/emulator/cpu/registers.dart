import 'dart:typed_data';

import 'cpu.dart';
import '../memory/cartridge.dart';

/// CPU registers, each register has 8 bits
///
/// Represents in dart as int values (dart does not support byte).
///
class Registers
{
  // The DMG has 4 flag registers, zero, subtract, half-carry and carry.
  static const int ZERO = 0x80;
  // Half-carry is only ever used for the DAA instruction. Half-carry is usually carry over lower nibble, and carry is over bit 7.
  static const int SUBTRACT = 0x40;
  static const int HALF_CARRY = 0x20;
  static const int CARRY = 0x10;

  // Register pair addressing
  static const int BC = 0x0;
  static const int DE = 0x1;
  static const int HL = 0x2;
  static const int AF = 0x3;
  static const int SP = 0x3;

  // Register addressing
  static const int B = 0x00;
  static const int C = 0x01;
  static const int D = 0x02;
  static const int E = 0x03;
  static const int H = 0x04;
  static const int L = 0x05;
  static const int F = 0x06;
  static const int A = 0x07;

  // CPU registers store temporally the result of the instructions.
  //
  // F is the flag register.
  Uint8List registers;

  /*int get a{return this.registers[A];}
  int get b{return this.registers[B];}
  int get c{return this.registers[C];}
  int get d{return this.registers[D];}
  int get e{return this.registers[E];}
  int get f{return this.registers[F];}
  int get h{return this.registers[H];}
  int get l{return this.registers[L];}

  set a(int value){this.registers[A] = value;}
  set b(int value){this.registers[B] = value;}
  set c(int value){this.registers[C] = value;}
  set d(int value){this.registers[D] = value;}
  set e(int value){this.registers[E] = value;}
  set f(int value){this.registers[F] = value;}
  set h(int value){this.registers[H] = value;}
  set l(int value){this.registers[L] = value;}*/

  int a, f;
  int b, c;
  int d, e;
  int h, l;

  /// Pointer to the CPU object
  CPU cpu;

  Registers(CPU cpu)
  {
    this.cpu = cpu;
    this.registers = new Uint8List(8);
    this.reset();
  }

  /// 16 bit mixed AF register
  int get af
  {
    return (this.a << 8) | this.f;
  }

  set af(int value)
  {
    this.a = (value >> 8) & 0xFF;
    this.f = value & 0xFF;
  }

  /// 16 bit mixed BC register
  int get bc
  {
    return (this.b << 8) | this.c;
  }

  set bc(int value)
  {
    this.b = (value >> 8) & 0xFF;
    this.c = value & 0xFF;
  }

  /// 16 bit mixed DE register
  int get de
  {
    return (this.d << 8) | this.e;
  }

  set de(int value)
  {
    this.d = (value >> 8) & 0xFF;
    this.e = value & 0xFF;
  }

  /// 16 bit mixed HL register
  int get hl
  {
    return (this.h << 8) | this.l;
  }

  set hl(int value)
  {
    this.h = (value >> 8) & 0xFF;
    this.l = value & 0xFF;
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
    if(r == 0x6) {return this.cpu.mmu.readByte(this.hl);}

    throw new Exception('Unknown register address getRegister().');
  }

  /// Alters the byte value contained in a register, r is the register id as encoded by opcode.
  void setRegister(int r, int value)
  {
    value &= 0xFF;

    if(r == 0x7) {this.a = value;}
    else if(r == 0x0) {this.b = value;}
    else if(r == 0x1) {this.c = value;}
    else if(r == 0x2) {this.d = value;}
    else if(r == 0x3) {this.e = value;}
    else if(r == 0x4) {this.h = value;}
    else if(r == 0x5) {this.l = value;}
    else if(r == 0x6) {this.cpu.mmu.writeByte(this.hl, value);}
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// Returns the value of the register
  int getRegisterPair(int r)
  {
    if(r == Registers.BC) {return this.bc;}
    if(r == Registers.DE) {return this.de;}
    if(r == Registers.HL) {return this.hl;}
    if(r == Registers.AF) {return this.af;}

    throw new Exception('Unknown register pair address getRegisterPair().');
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// Can be used with a single word value as the second argument.
  /// Returns the value of the register
  void setRegisterPair(int r, int hi, int lo)
  {
    hi &= 0xFF;
    lo &= 0xFF;

    if(r == Registers.BC) {this.b = hi; this.c = lo;}
    else if(r == Registers.DE) {this.d = hi; this.e = lo;}
    else if(r == Registers.HL) {this.h = hi; this.l = lo;}
    else if(r == Registers.AF) {this.a = hi; this.f = lo & 0xF;}
  }


  /// Reset the registers to default values
  ///
  /// (Check page 17 and 18 of the GB CPU manual)
  void reset()
  {
    //AF=$01-GB/SGB, $FF-GBP, $11-GBC
    this.a = this.cpu.cartridge.gameboyType == GameboyType.COLOR ? 0x11 : 0x01;
    this.f = 0xB0;
    this.b = 0x00;
    this.c = 0x13;
    this.d = 0x00;
    this.e = 0xD8;
    this.h = 0x01;
    this.l = 0x4D;
  }

  ///Checks a condition from an opcode.
  ///Returns a boolean based off the result of the conditional.
  bool getFlag(int flag)
  {
    flag &= 0x7;

    // Condition code is in last 3 bits
    if(flag == 0x4) {return (this.f & Registers.ZERO) == 0;}
    if(flag == 0x5) {return (this.f & Registers.ZERO) != 0;}
    if(flag == 0x6) {return (this.f & Registers.CARRY) == 0;}
    if(flag == 0x7) {return (this.f & Registers.CARRY) != 0;}

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
}