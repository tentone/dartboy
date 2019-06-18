import '../cpu/cpu.dart';

/// LCD class handles all the screen drawing tasks.
///
/// Is responsible for managing the sprites and background layers.
class LCD
{
  static const int W = 160;
  static const int H = 144;

  CPU cpu;

  LCD(CPU cpu)
  {
    this.cpu = cpu;
  }

}