
/// Stored the address layout of the gameboy in constants.
///
/// Interrupt Enable Register FF80 - FFFF
/// Internal RAM FF4C - FF80
/// Empty but unusable for I/O FF4C - FF80
/// I/O ports FEA0 - FF00 - FF4C
/// Empty but unusable for I/O FEA0 - FF00
/// Sprite attrib Memory (OAM) FE00 - FEA0
/// Echo of 8kB Internal RAM E000 - FE00
/// 8kB Internal RAM C000 - E000
/// 8kB switchable RAM bank A000 - C000
/// 8kB Video RAM 8000 - A000
/// 16kB switchable ROM bank 4000 - 8000 (32kB Cartridge)
/// 16kB ROM bank #0 0000 - 4000
class MemoryAddresses
{
  /// Total memory addressable size
  static const ADDRESS_SIZE = 65536;

  // Cartridge ROM
  static const CARTRIDGE_ROM_START = 0x0000;
  static const CARTRIDGE_SWITCHABLE_START = 0x4000;
  static const CARTRIDGE_ROM_END = 0x8000;

  // Video RAM
  static const VIDEO_RAM_START = 0x8000;
  static const VIDEO_RAM_END = 0xA000;

  // Switchable RAM (Cartridge)
  static const SWITCHABLE_RAM_START = 0xA000;
  static const SWITCHABLE_RAM_END = 0xC000;

  // 8Kb Internal RAM
  static const INTERNAL_RAM_A_START = 0xC000;
  static const INTERNAL_RAM_A_END = 0xE000;
  static const INTERNAL_RAM_A_ECHO_START = 0xE000;
  static const INTERNAL_RAM_A_ECHO_END = 0xFE00;

  // Sprite attribute
  static const OAM_START = 0xFE00;
  static const OAM_END = 0xFEA0;

  // IO ports
  static const IO_START = 0xFF00;
  static const IO_END = 0xFF4C;

  // RAM
  static const INTERNAL_RAM_B_START = 0xFF4C;
  static const INTERNAL_RAM_B_END = 0xFF80;

  // Interrupt registers
  static const INTERRUPT_REGISTERS_START = 0xFF80;
  static const INTERRUPT_REGISTERS_END = 0xFFFF;
}

