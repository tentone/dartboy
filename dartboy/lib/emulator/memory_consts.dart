class MemoryConsts
{
  static const int R_DIV = 0x04;
  static const int R_JOYPAD = 0x00;
  static const int R_SERIAL = 0x02;
  static const int R_TAC = 0x07;
  static const int R_TIMA = 0x05;
  static const int R_TMA = 0x06;
  static const int R_NR10 = 0x10;
  static const int R_NR11 = 0x11;
  static const int R_NR12 = 0x12;
  static const int R_NR13 = 0x13;
  static const int R_NR14 = 0x14;
  static const int R_NR21 = 0x16;
  static const int R_NR22 = 0x17;
  static const int R_NR23 = 0x18;
  static const int R_NR24 = 0x19;
  static const int R_NR30 = 0x1A;
  static const int R_NR31 = 0x1B;
  static const int R_NR32 = 0x1C;
  static const int R_NR33 = 0x1D;
  static const int R_NR34 = 0x1E;
  static const int R_NR41 = 0x20;
  static const int R_NR42 = 0x21;
  static const int R_NR43 = 0x22;
  static const int R_NR44 = 0x23;
  static const int R_NR51 = 0x25;
  static const int R_NR52 = 0x26;
  static const int R_WRAM_BANK = 0x70;
  static const int R_VRAM_BANK = 0x4f;
  static const int R_LCDC = 0x40;
  static const int R_LCD_STAT = 0x41;
  static const int R_SCY = 0x42;
  static const int R_SCX = 0x43;
  static const int R_LY = 0x44;
  static const int R_LYC = 0x45;
  static const int R_BGP = 0x47;
  static const int R_OBP0 = 0x48;
  static const int R_OBP1 = 0x49;
  static const int R_TRIGGERED_INTERRUPTS = 0x0F; // IF
  static const int R_ENABLED_INTERRUPTS = 0xFF;
  static const int R_DMA = 0x46;
  static const int R_WY = 0x4a;
  static const int R_WX = 0x4b;

  /// Masks for R_TRIGGERED_INTERRUPTS and R_ENABLED_INTERRUPTS.
  static const int VBLANK_BIT = 0x1;
  static const int LCDC_BIT = 0x2;
  static const int TIMER_OVERFLOW_BIT = 0x4;
  static const int SERIAL_TRANSFER_BIT = 0x8;
  static const int HILO_BIT = 0x10;

  /// The addresses to jump to when an interrupt is triggered.
  static const int VBLANK_HANDLER_ADDRESS = 0x40;
  static const int LCDC_HANDLER_ADDRESS = 0x48;
  static const int TIMER_OVERFLOW_HANDLER_ADDRESS = 0x50;
  static const int SERIAL_TRANSFER_HANDLER_ADDRESS = 0x58;
  static const int HILO_HANDLER_ADDRESS = 0x60;
  static const int W = 160;
  static const int H = 144;

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

