import 'package:dartboy/emulator/memory/memory.dart';

/// Class to handle the IO function of the GBC
///
/// Handlers gamepad input and serial communication.
class IO
{
  /// System memory used to read and write IO data.
  Memory memory;

  IO(Memory memory)
  {
    this.memory = memory;
  }
}