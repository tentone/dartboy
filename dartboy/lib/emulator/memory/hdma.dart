import './memory.dart';

/// Represents a H-Blank DMA transfer session.
///
/// HDMA transfers 16 bytes from source to dest every H-Blank interval, and can be used for a lot of video effects.
class HDMA
{
  /// Memory of the HDMA
  Memory memory;

  /// The source address.
  int source;

  /// The destination address.
  int destination;

  /// The length of the transfer.
  int length;

  /// The current offset into the source/dest buffers.
  int position;

  /// Creates a new HDMA instance.
  ///
  /// @param source The source address to copy from.
  /// @param dest The destination address to copy to.
  /// @param length How many bytes to copy.
  HDMA(Memory memory, int source, int dest, int length)
  {
    this.memory = memory;
    this.source = source;
    this.destination = dest;
    this.length = length;
  }

  /// The H-Blank DMA transfers 10h bytes of data during each H-Blank, ie. at LY=0-143, no data is transferred during V-Blank (LY=144-153), but the transfer will then continue at LY=00.
  ///
  /// The execution of the program is halted during the separate transfers, but the program execution continues during the 'spaces' between each data block.
  ///
  /// Note that the program may not change the Destination VRAM bank (FF4F), or the Source ROM/RAM bank (in case data is transferred from bankable memory) until the transfer has completed!
  ///
  /// Reading from Register FF55 returns the remaining length (divided by 10h, minus 1), a value of 0FFh ndicates that the transfer has completed.
  ///
  /// It is also possible to terminate an active H-Blank transfer by writing zero to Bit 7 of FF55.
  ///
  /// In that case reading from FF55 may return any value for the lower 7 bits, but Bit 7 will be read as "1".
  void tick()
  {
    for(int i = this.position; i < this.position + 0x10; i++)
    {
      this.memory.vram[this.memory.vramPageStart + this.destination + i] = this.memory.readByte(source + i);
    }

    this.position += 0x10;
    this.length -= 0x10;

    if(this.length == 0)
    {
      this.memory.hdma = null;
      this.memory.registers[0x55] = 0xff;

      //TODO <DEBUG PRINT>
      print("Finished HDMA from " + this.source.toString() + " to " + this.destination.toString());
    }
    else
    {
      this.memory.registers[0x55] = (this.length ~/ 0x10 - 1);
    }
  }
}