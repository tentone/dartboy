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
  List<int> registers;

  int get a{return this.registers[A];}
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
  set l(int value){this.registers[L] = value;}

  /// Pointer to the CPU object
  CPU cpu;

  Registers(CPU cpu)
  {
    this.cpu = cpu;
    this.registers = new List<int>(8);
  }

  /// Fetches the byte value contained in a register, r is the register id as encoded by opcode.
  /// Returns the value of the register
  int getRegister(int r)
  {
    if(r == A) {return this.a;}
    if(r == B) {return this.b;}
    if(r == C) {return this.c;}
    if(r == D) {return this.d;}
    if(r == E) {return this.e;}
    if(r == H) {return this.h;}
    if(r == L) {return this.l;}
    if(r == 0x6) {return this.cpu.mmu.readByte(this.getRegisterPair(HL));}

    throw new Exception('Unknown register address getRegister().');
  }

  /// Alters the byte value contained in a register, r is the register id as encoded by opcode.
  void setRegister(int r, int value)
  {
    value &= 0xFF;

    if(r == A) {this.a = value;}
    else if(r == B) {this.b = value;}
    else if(r == C) {this.c = value;}
    else if(r == D) {this.d = value;}
    else if(r == E) {this.e = value;}
    else if(r == H) {this.h = value;}
    else if(r == L) {this.l = value;}
    else if(r == 0x6) {this.cpu.mmu.writeByte(this.getRegisterPair(HL), value);}
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// Returns the value of the register
  int getRegisterPair(int r)
  {
    if(r == BC) {return (this.b << 8) | this.c;}
    if(r == DE) {return (this.d << 8) | this.e;}
    if(r == HL) {return (this.h << 8) | this.l;}
    if(r == AF) {return (this.a << 8) | this.f;}

    throw new Exception('Unknown register pair address getRegisterPair().');
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode.
  /// It can return a register pair or the CPU SP value.
  /// Returns the value of the register
  int getRegisterPairSP(int r)
  {
    if(r == BC) {return (this.b << 8) | this.c;}
    if(r == DE) {return (this.d << 8) | this.e;}
    if(r == HL) {return (this.h << 8) | this.l;}
    if(r == Registers.SP) {return this.cpu.sp;}

    throw new Exception('Unknown register pair address getRegisterPairSP().');
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// Can be used with a single word value as the second argument.
  /// Returns the value of the register
  void setRegisterPair(int r, int hi, int lo)
  {
    hi &= 0xFF;
    lo &= 0xFF;

    if(r == BC) {this.b = hi; this.c = lo;}
    else if(r == DE) {this.d = hi; this.e = lo;}
    else if(r == HL) {this.h = hi; this.l = lo;}
    else if(r == AF) {this.a = hi; this.f = lo & 0xF;}
  }

  /// Fetches the world value of a registers pair, r is the register id as encoded by opcode (PUSH_rr).
  /// It can set a register pair or the CPU SP value.
  /// Returns the value of the register
  void setRegisterPairSP(int r, int value)
  {
    int hi = (value >> 8) & 0xFF;
    int lo = value & 0xFF;

    if(r == Registers.BC)
    {
      this.b = hi;
      this.c = lo;
    }
    else if(r == Registers.DE)
    {
      this.d = hi;
      this.e = lo;
    }
    else if(r == Registers.HL)
    {
      this.h = hi;
      this.l = lo;
    }
    else if(r == Registers.SP)
    {
      this.cpu.sp = (hi << 8) | lo;
    }
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
    if(flag == 0x4) {return (this.f & ZERO) == 0;}
    if(flag == 0x5) {return (this.f & ZERO) != 0;}
    if(flag == 0x6) {return (this.f & CARRY) == 0;}
    if(flag == 0x7) {return (this.f & CARRY) != 0;}

    return false;
  }

  /// Set the flags on the flag register.
  ///
  /// There are four values on the upper bits of the register that are set depending on the instruction being executed.
  void setFlags(bool zero, bool subtract, bool halfCarry, bool carry)
  {
    this.f = zero ? (this.f | ZERO) : (this.f & 0x7F);
    this.f = subtract ? (this.f | SUBTRACT) : (this.f & 0xBF);
    this.f = halfCarry ? (this.f | HALF_CARRY) : (this.f & 0xDF);
    this.f = carry ? (this.f | CARRY) : (this.f & 0xEF);
  }
}