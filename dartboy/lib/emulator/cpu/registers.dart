import 'cpu.dart';

/// CPU registers, each register has 8 bits
///
/// Represents in dart as int values (dart does not support byte).
///
class Registers
{
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
    if(r == 0x6) {return cpu.memory.readByte((h << 8) | l);}

    return 0;
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
    else if(r == 0x6) {cpu.memory.writeByte((h << 8) | l, value);}
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