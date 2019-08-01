/// Configuration contains global emulation configuration.
///
/// Type of system being emulated, debug configuration, etc.
class Configuration
{
  /// Debug variable to enable and disable the background rendering.
  static bool drawBackgroundLayer = true;

  /// Debug variable to enable and disable the sprite layer rendering.
  static bool drawSpriteLayer = true;

  /// If true data sent trough the serial port will be printed on the debug terminal.
  ///
  /// Useful for debug codes printed by test ROMs.
  static bool printSerialCharacters = false;

  /// Instructions debug info and registers information is printed to the terminal if set true.
  static bool debugInstructions = false;
}