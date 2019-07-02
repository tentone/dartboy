class ByteUtils
{
  /// Make a byte stored in a int value signed as a 2s complement.
  static int toSignedByte(int value)
  {
    if(value & 0x80 != 0)
    {
      return (value & 0x7F) - 0x80;
    }

    return value;
  }
}
