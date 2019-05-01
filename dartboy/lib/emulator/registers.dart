
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

  Registers()
  {
    this.reset();
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