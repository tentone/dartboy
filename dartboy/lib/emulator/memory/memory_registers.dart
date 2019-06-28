class MemoryRegisters
{
  static const int DOUBLE_SPEED = 0x4d;
  static const int HDMA_START = 0x55;

  static const int GAMEPAD = 0x00;
  static const int SERIAL = 0x02;
  static const int DIV = 0x04;
  static const int TIMA = 0x05;
  static const int TMA = 0x06;
  static const int TAC = 0x07;
  static const int NR10 = 0x10;
  static const int NR11 = 0x11;
  static const int NR12 = 0x12;
  static const int NR13 = 0x13;
  static const int NR14 = 0x14;
  static const int NR21 = 0x16;
  static const int NR22 = 0x17;
  static const int NR23 = 0x18;
  static const int NR24 = 0x19;
  static const int NR30 = 0x1A;
  static const int NR31 = 0x1B;
  static const int NR32 = 0x1C;
  static const int NR33 = 0x1D;
  static const int NR34 = 0x1E;
  static const int NR41 = 0x20;
  static const int NR42 = 0x21;
  static const int NR43 = 0x22;
  static const int NR44 = 0x23;
  static const int NR51 = 0x25;
  static const int NR52 = 0x26;
  static const int WRAM_BANK = 0x70;
  static const int VRAM_BANK = 0x4f;

  /// The Tile Data Table address for the background can be selected via LCDC register.
  static const int LCDC = 0x40;

  static const int LCD_STAT = 0x41;
  static const int SCY = 0x42;
  static const int SCX = 0x43;

  /// The LY indicates the vertical line to which the present data is transferred to the LCD Driver.
  /// The LY can take on any value between 0 through 153. The values between 144 and 153 indicate the V-Blank period.
  static const int LY = 0x44;

  static const int LYC = 0x45;

  /// This register allows to read/write data to the CGBs Background Palette Memory, addressed through Register FF68.
  static const int BGP = 0x47;

  static const int OBP0 = 0x48;
  static const int OBP1 = 0x49;
  static const int TRIGGERED_INTERRUPTS = 0x0F; // IF
  static const int ENABLED_INTERRUPTS = 0xFF;
  static const int DMA = 0x46;
  static const int WY = 0x4a;
  static const int WX = 0x4b;

  // Masks for TRIGGERED_INTERRUPTS and ENABLED_INTERRUPTS.
  static const int VBLANK_BIT = 0x1;
  static const int LCDC_BIT = 0x2;
  static const int TIMER_OVERFLOW_BIT = 0x4;
  static const int SERIAL_TRANSFER_BIT = 0x8;
  static const int HILO_BIT = 0x10;

  // The addresses to jump to when an interrupt is triggered.
  static const int VBLANK_HANDLER_ADDRESS = 0x40;
  static const int LCDC_HANDLER_ADDRESS = 0x48;
  static const int TIMER_OVERFLOW_HANDLER_ADDRESS = 0x50;
  static const int SERIAL_TRANSFER_HANDLER_ADDRESS = 0x58;
  static const int HILO_HANDLER_ADDRESS = 0x60;

  // LCD Related values
  static const int LCDC_BGWINDOW_DISPLAY_BIT = 0x01;
  static const int LCDC_SPRITE_DISPLAY_BIT = 0x02;
  static const int LCDC_SPRITE_SIZE_BIT = 0x04;
  static const int LCDC_BG_TILE_MAP_DISPLAY_SELECT_BIT = 0x08;
  static const int LCDC_BGWINDOW_TILE_DATA_SELECT_BIT = 0x10;
  static const int LCDC_WINDOW_DISPLAY_BIT = 0x20;
  static const int LCDC_WINDOW_TILE_MAP_DISPLAY_SELECT_BIT = 0x40;
  static const int LCDC_CONTROL_OPERATION_BIT = 0x80;

  static const int LCD_STAT_OAM_MODE_BIT = 0x20;
  static const int LCD_STAT_VBLANK_MODE_BIT = 0x10;
  static const int LCD_STAT_HBLANK_MODE_BIT = 0x8;
  static const int LCD_STAT_COINCIDENCE_BIT = 0x4;
  static const int LCD_STAT_COINCIDENCE_INTERRUPT_ENABLED_BIT = 0x40;
  static const int LCD_STAT_MODE_MASK = 0x3;

  static const int LCD_STAT_MODE_HBLANK_BIT = 0x0;
  static const int LCD_STAT_MODE_VBLANK_BIT = 0x1;
  static const int LCD_STAT_MODE_OAM_RAM_SEARCH_BIT = 0x2;
  static const int LCD_STAT_MODE_DATA_TRANSFER_BIT = 0x3;
}

