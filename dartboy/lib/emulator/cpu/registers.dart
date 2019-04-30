
/// CPU registers, each register has 8 bits
///
/// Represents in dart as int values (dart does not support byte).
///
class Registers
{
  int a, b;
  int c, d;
  int e, f;
  int h, l;

  get af
  {
    return ((a & 0xFF) << 8) | (f & 0xFF);
  }

  set af(int value)
  {
    a = ((value & 0xFF00) >> 8);
    f = (value & 0xFF);
  }

  get bc
  {
    return ((b & 0xFF) << 8) | (c & 0xFF);
  }

  set bc(int value)
  {
    b = ((value & 0xFF00) >> 8);
    c = (value & 0xFF);
  }

  get de
  {
    return ((d & 0xFF) << 8) | (e & 0xFF);
  }

  set de(int value)
  {
    d = ((value & 0xFF00) >> 8);
    e = (value & 0xFF);
  }

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