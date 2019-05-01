
/// CPU registers, each register has 8 bits
///
/// Represents in dart as int values (dart does not support byte).
///
class Registers
{
  /// Generic CPU registers
  int a = 0;
  int b = 0, c = 0;
  int d = 0, e = 0;
  int h = 0, l = 0;

  /// Flags register
  int f = 0;

  /// Reset the registers to default values
  void reset()
  {
    a = b = c = d = e = f = h = l = 0;
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