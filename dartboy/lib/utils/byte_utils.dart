class ByteUtils
{
  /// Make a byte stored in a int value signed.
  static int toSignedByte(int value)
  {
    if(value & 0x80 != 0)
    {
      value = value & 0x7F;
      value -= 0x80;
    }

    return value;
  }
}
