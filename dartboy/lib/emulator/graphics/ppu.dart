import 'package:dartboy/gui/main_screen.dart';

import '../configuration.dart';
import '../memory/memory_registers.dart';
import '../memory/memory_addresses.dart';
import '../memory/cartridge.dart';
import './palette_colors.dart';
import '../cpu/cpu.dart';
import './palette.dart';

/// LCD class handles all the screen drawing tasks.
///
/// Is responsible for managing the sprites and background layers.
class PPU
{
  /// Width in pixels of the physical gameboy LCD.
  static const int LCD_WIDTH = 160;

  /// Height in pixels of the physical gameboy LCD.
  static const int LCD_HEIGHT = 144;

  /// Draw layer priority constants.
  ///
  /// We can only draw over pixels with equal or greater priority.
  static const int P_0 = 0 << 24;
  static const int P_1 = 1 << 24;
  static const int P_2 = 2 << 24;
  static const int P_3 = 3 << 24;
  static const int P_4 = 4 << 24;
  static const int P_5 = 5 << 24;
  static const int P_6 = 6 << 24;

  /// The Emulator on which to operate.
  CPU cpu;

  /// A buffer to hold the current rendered frame that can be directly copied to the canvas on the widget.
  ///
  /// Each position stores RGB encoded color value. The data is stored by rows.
  List<int> buffer;

  /// Current rendered image to be displayed on screen.
  ///
  /// This buffer is swapped with the main drawing buffer.
  List<int> current;

  /// Background palettes. On CGB, 0-7 are used. On GB, only 0 is used.
  List<Palette> bgPalettes;

  /// Sprite palettes. 0-7 used on CGB, 0-1 used on GB.
  List<Palette> spritePalettes;

  /// Background palette memory on the CGB, indexed through $FF69.
  List<int> gbcBackgroundPaletteMemory;

  /// Sprite palette memory on the CGB, indexed through $FF6B.
  List<int> gbcSpritePaletteMemory;

  /// Stores number of sprites drawn per each of the 144 scanlines this frame.
  ///
  /// Actual Gameboy hardware can only draw 10 sprites/line, so we artificially introduce this limitation using this array.
  List<int> spritesDrawnPerLine;

  /// A counter for the number of cycles elapsed since the last LCD event.
  int lcdCycles;

  /// Accumulator for how many VBlanks have been performed since the last reset.
  int currentVBlankCount;

  /// The timestamp of the last second, in nanoseconds.
  int lastSecondTime;

  /// The last measured Emulator.cycle.
  int lastCoreCycle;

  PPU(CPU cpu)
  {
    this.cpu = cpu;
  }

  /// Initializes all palette RAM to the default on Gameboy boot.
  void reset()
  {
    this.lcdCycles = 0;
    this.currentVBlankCount = 0;
    this.lastSecondTime = -1;

    this.bgPalettes = new List<Palette>(8);
    this.spritePalettes = new List<Palette>(8);
    this.gbcBackgroundPaletteMemory = new List<int>(0x40);

    this.buffer = new List<int>(PPU.LCD_WIDTH * PPU.LCD_HEIGHT);
    this.buffer.fillRange(0, this.buffer.length, 0);

    this.current = new List<int>(PPU.LCD_WIDTH * PPU.LCD_HEIGHT);
    this.current.fillRange(0, this.current.length, 0);

    this.gbcSpritePaletteMemory = new List<int>(0x40);
    this.gbcSpritePaletteMemory.fillRange(0, this.gbcSpritePaletteMemory.length, 0);

    this.spritesDrawnPerLine = new List<int>(PPU.LCD_HEIGHT);
    this.spritesDrawnPerLine.fillRange(0, this.spritesDrawnPerLine.length, 0);

    if(this.cpu.cartridge.gameboyType == GameboyType.COLOR)
    {
      this.gbcBackgroundPaletteMemory.fillRange(0, this.gbcBackgroundPaletteMemory.length, 0x1f);

      for(int i = 0; i < this.spritePalettes.length; i++)
      {
        List<int> colors = new List<int>(4);
        colors.fillRange(0, 4, 0);
        this.spritePalettes[i] = new GBCPalette(colors);
      }

      for(int i = 0; i < this.bgPalettes.length; i++)
      {
        List<int> colors = new List<int>(4);
        colors.fillRange(0, 4, 0);
        this.bgPalettes[i] = new GBCPalette(colors);
      }

      // Load palettes from RAM
      loadPalettesFromMemory(this.gbcSpritePaletteMemory, this.spritePalettes);
      loadPalettesFromMemory(this.gbcBackgroundPaletteMemory, this.bgPalettes);
    }
    else
    {
      // Classic gameboy background palette data only
      // Initially all background colors are initialized as white.
      PaletteColors colors = PaletteColors.getByHash(this.cpu.cartridge.checksum);

      this.bgPalettes[0] = new GBPalette(this.cpu, colors.bg, MemoryRegisters.BGP);
      this.spritePalettes[0] = new GBPalette(this.cpu, colors.obj0, MemoryRegisters.OBP0);
      this.spritePalettes[1] = new GBPalette(this.cpu, colors.obj1, MemoryRegisters.OBP1);
    }
  }

  /// Reloads all Gameboy Color palettes.
  ///
  /// @param from Palette RAM to load from.
  /// @param to Reference to an array of Palettes to populate.
  void loadPalettesFromMemory(List<int> from, List<Palette> to)
  {
    // 8 palettes
    for(int i = 0; i < 8; i++)
    {
      // 4 ints per palette
      for(int j = 0; j < 4; ++j)
      {
        updatePalette(from, to[i], i, j);
      }
    }
  }

  /// Performs an update to a int of palette RAM, the colors are stored in two bytes as:
  /// Bit 0-4 Red Intensity (00-1F)
  /// Bit 5-9 Green Intensity (00-1F)
  /// Bit 10-14 Blue Intensity (00-1F)
  ///
  /// @param from The palette RAM to read from.
  /// @param to Reference to an array of Palettes to update.
  /// @param i The palette index being updated.
  /// @param j The int index of the palette being updated.
  void updatePalette(List<int> from, Palette to, int i, int j)
  {
    // Read an RGB value from RAM
    int data = ((from[i * 8 + j * 2 + 1] & 0xff) << 8) | (from[i * 8 + j * 2] & 0xff);

    // Extract components
    int red = (data & 0x1f);
    int green = (data >> 5) & 0x1f;
    int blue = (data >> 10) & 0x1f;

    int r = ((red / 31.0 * 255 + 0.5).toInt() & 0xFF) << 16;
    int g = ((green / 31.0 * 255 + 0.5).toInt() & 0xFF) << 8;
    int b = (blue / 31.0 * 255 + 0.5).toInt() & 0xFF;

    // Convert from [0, 1Fh] to [0, FFh], and recombine
    to.colors[j] = (r | g | b);
  }

  /// Updates an entry of background palette RAM. Internal function for use in a Memory controller.
  ///
  /// @param reg  The register written to.
  /// @param data The data written.
  void setBackgroundPalette(int reg, int data)
  {
    this.gbcBackgroundPaletteMemory[reg] = data;

    int palette = reg >> 3;
    updatePalette(this.gbcBackgroundPaletteMemory, this.bgPalettes[palette], palette, (reg >> 1) & 0x3);
  }

  /// Updates an entry of sprite palette RAM. Internal function for use in a Memory controller.
  ///
  /// @param reg  The register written to.
  /// @param data The data written.
  void setSpritePalette(int reg, int data)
  {
    this.gbcSpritePaletteMemory[reg] = data;

    int palette = reg >> 3;
    updatePalette(this.gbcSpritePaletteMemory, this.spritePalettes[palette], palette, (reg >> 1) & 0x3);
  }

  /// Tick the LCD.
  ///
  /// @param cycles The number of CPU cycles elapsed since the last call to tick.
  void tick(int cycles)
  {
    // Accumulate to an internal counter
    this.lcdCycles += cycles;

    // At 4.194304MHz clock, 154 scanlines per frame, 59.7 frames/second = ~456 cycles / line
    if(this.lcdCycles >= 456)
    {
      this.lcdCycles -= 456;

      int ly = this.cpu.mmu.readRegisterByte(MemoryRegisters.LY) & 0xFF;

      // Draw the scanline
      bool displayEnabled = this.displayEnabled();

      // We may be running headlessly, so we must check before drawing
      if(displayEnabled)
      {
        this.draw(ly);
      }

      // Increment LY, and wrap at 154 lines
      this.cpu.mmu.writeRegisterByte(MemoryRegisters.LY, (((ly + 1) % 154) & 0xff));

      if(ly == 0)
      {
        if(this.lastSecondTime == -1)
        {
          this.lastSecondTime = DateTime.now().millisecondsSinceEpoch;
          this.lastCoreCycle = this.cpu.clocks;
        }

        this.currentVBlankCount++;

        if(currentVBlankCount == 60)
        {
          //print("Took " + ((DateTime.now().millisecondsSinceEpoch - lastSecondTime) / 1000.0) + " seconds for 60 frames - " + (core.clocks - lastCoreCycle) / 60 + " clks/frames");
          this.lastCoreCycle = this.cpu.clocks;
          this.currentVBlankCount = 0;
          this.lastSecondTime = DateTime.now().millisecondsSinceEpoch;
        }
      }

      bool isVBlank = 144 <= ly;
      if(!isVBlank && this.cpu.mmu.dma != null)
      {
        this.cpu.mmu.dma.tick();
      }

      this.cpu.mmu.writeRegisterByte(MemoryRegisters.LCD_STAT, this.cpu.mmu.readRegisterByte(MemoryRegisters.LCD_STAT) & ~0x03);

      int mode = 0;
      if(isVBlank)
      {
        mode = 0x01;
      }

      this.cpu.mmu.writeRegisterByte(MemoryRegisters.LCD_STAT, this.cpu.mmu.readRegisterByte(MemoryRegisters.LCD_STAT) | mode);

      int lcdStat = this.cpu.mmu.readRegisterByte(MemoryRegisters.LCD_STAT);

      if(displayEnabled && !isVBlank)
      {
        // LCDC Status Interrupt (To indicate to the user when the video hardware is about to redraw a given LCD line)
        if((lcdStat & MemoryRegisters.LCD_STAT_COINCIDENCE_INTERRUPT_ENABLED_BIT) != 0)
        {
          int lyc = (this.cpu.mmu.readRegisterByte(MemoryRegisters.LYC) & 0xff);

          // Fire when LYC == LY
          if(lyc == ly)
          {
            this.cpu.setInterruptTriggered(MemoryRegisters.LCDC_BIT);
            this.cpu.mmu.writeRegisterByte(MemoryRegisters.LCD_STAT, this.cpu.mmu.readRegisterByte(MemoryRegisters.LCD_STAT) | MemoryRegisters.LCD_STAT_COINCIDENCE_BIT);
          }
          else
          {
            this.cpu.mmu.writeRegisterByte(MemoryRegisters.LCD_STAT, this.cpu.mmu.readRegisterByte(MemoryRegisters.LCD_STAT) & ~MemoryRegisters.LCD_STAT_COINCIDENCE_BIT);
          }
        }

        if((lcdStat & MemoryRegisters.LCD_STAT_HBLANK_MODE_BIT) != 0)
        {
          this.cpu.setInterruptTriggered(MemoryRegisters.LCDC_BIT);
        }
      }

      // V-Blank Interrupt
      if(ly == 143)
      {
        // Trigger interrupts if the display is enabled
        if(displayEnabled)
        {
          // Trigger VBlank
          this.cpu.setInterruptTriggered(MemoryRegisters.VBLANK_BIT);

          // Trigger LCDC if enabled
          if((lcdStat & MemoryRegisters.LCD_STAT_VBLANK_MODE_BIT) != 0)
          {
            this.cpu.setInterruptTriggered(MemoryRegisters.LCDC_BIT);
          }
        }
      }
    }
  }

  /// Draws a scanline.
  ///
  /// @param scanline The scanline to draw.
  void draw(int scanline)
  {
    // Don't even bother if the display is not enabled
    if(!displayEnabled())
    {
      return;
    }

    // We still receive these calls for scanlines in vblank, but we can just ignore them
    if(scanline >= 144 || scanline < 0)
    {
      return;
    }

    // Reset our sprite counter
    this.spritesDrawnPerLine[scanline] = 0;

    // Start of a new frame
    if(scanline == 0)
    {
      // Swap buffer and current
      List<int> temp = this.buffer;
      this.buffer = this.current;
      this.current = temp;

      // ignore: invalid_use_of_protected_member
      MainScreen.lcdState.setState((){});

      //Clear drawing buffer
      this.buffer.fillRange(0, this.buffer.length, 0);
    }

    // Draw the background if it's enabled
    if(this.backgroundEnabled())
    {
      this.drawBackgroundTiles(this.buffer, scanline);
    }

    // If sprites are enabled, draw them.
    if(this.spritesEnabled())
    {
      this.drawSprites(this.buffer, scanline);
    }

    // If the window appears in this scanline, draw it
    if(this.windowEnabled() && scanline >= this.getWindowPosY() && this.getWindowPosX() < LCD_WIDTH && this.getWindowPosY() >= 0)
    {
      this.drawWindow(this.buffer, scanline);
    }
  }

  /// Attempt to draw background tiles.
  ///
  /// @param data The raster to write to.
  /// @param scanline The current scanline.
  void drawBackgroundTiles(List<int> data, int scanline)
  {
    if(!Configuration.drawBackgroundLayer)
    {
      return;
    }

    // Local reference to save time
    int tileDataOffset = this.getTileDataOffset();

    // The background is scrollable
    int scrollY = this.getScrollY();
    int scrollX = this.getScrollX();

    int y = (scanline + scrollY % 8) ~/ 8;

    // Determine the offset into the VRAM tile bank
    int offset = this.getBackgroundTileMapOffset();

    // BG Map Tile Numbers
    //
    // An area of VRAM known as Background Tile Map contains the numbers of tiles to be displayed.
    // It is organized as 32 rows of 32 ints each. Each int contains a number of a tile to be displayed.

    // Tile patterns are taken from the Tile Data Table located either at $8000-8FFF or $8800-97FF.
    // In the first case, patterns are numbered with unsigned numbers from 0 to 255 (i.e. pattern #0 lies at address $8000).
    // In the second case, patterns have signed numbers from -128 to 127 (i.e. pattern #0 lies at address $9000).

    // 20 8x8 tiles fit in a 160px-wide screen
    for(int x = 0; x < 21; x++)
    {
      int addressBase = offset + ((y + scrollY ~/ 8) % 32 * 32) + ((x + scrollX ~/ 8) % 32);

      // Add 256 to jump into second tile pattern table
      int tile = tileDataOffset == 0 ? (this.cpu.mmu.readVRAM(addressBase) & 0xFF) : (this.cpu.mmu.readVRAM(addressBase) + 256);

      int gbcVramBank = 0;
      int gbcPalette = 0;
      bool flipX = false;
      bool flipY = false;

      // BG Map Attributes, in CGB Mode, an additional map of 32x32 ints is stored in VRAM Bank 1
      if(this.cpu.cartridge.gameboyType == GameboyType.COLOR)
      {
        int attributes = this.cpu.mmu.readVRAM(MemoryAddresses.VRAM_PAGESIZE + addressBase);

        // Tile VRAM Bank number
        if(attributes & 0x8 != 0)
        {
          gbcVramBank = 1;
        }

        // Horizontal Flip
        flipX = (attributes & 0x20) != 0;

        // Vertical Flip
        flipY = (attributes & 0x40) != 0;

        // Background Palette number
        gbcPalette = attributes & 0x7;
      }

      // Delegate tile drawing
      this.drawTile(this.bgPalettes[gbcPalette], data, -(scrollX % 8) + x * 8, -(scrollY % 8) + y * 8, tile, scanline, flipX, flipY, gbcVramBank, 0, false);
    }
  }

  /// Attempt to draw window tiles.
  ///
  /// @param data The raster to write to.
  /// @param scanline The current scanline.
  void drawWindow(List<int> data, int scanline)
  {
    int tileDataOffset = this.getTileDataOffset();

    // The window layer is offset-able from 0,0
    int posX = this.getWindowPosX();
    int posY = this.getWindowPosY();

    int tileMapOffset = this.getWindowTileMapOffset();

    int y = (scanline - posY) ~/ 8;

    for(int x = this.getWindowPosX() ~/ 8; x < 21; x++)
    {
      // 32 tiles a row
      int addressBase = tileMapOffset + (x + y * 32);

      // add 256 to jump into second tile pattern table
      int tile = tileDataOffset == 0 ? this.cpu.mmu.readVRAM(addressBase) & 0xff : this.cpu.mmu.readVRAM(addressBase) + 256;

      int gbcVramBank = 0;
      bool flipX = false;
      bool flipY = false;
      int gbcPalette = 0;

      // Same rules apply here as for background tiles.
      if(this.cpu.cartridge.gameboyType == GameboyType.COLOR)
      {
        int attributes = this.cpu.mmu.readVRAM(MemoryAddresses.VRAM_PAGESIZE + addressBase);

        if((attributes & 0x8) != 0)
        {
          gbcVramBank = 1;
        }

        flipX = (attributes & 0x20) != 0;
        flipY = (attributes & 0x40) != 0;
        gbcPalette = attributes & 0x07;
      }

      this.drawTile(this.bgPalettes[gbcPalette], data, posX + x * 8, posY + y * 8, tile, scanline, flipX, flipY, gbcVramBank, PPU.P_6, false);
    }
  }

  /// Attempt to draw a single line of a tile.
  ///
  /// @param palette The palette currently in use.
  /// @param data An array of elements, representing the LCD raster.
  /// @param x The x-coordinate of the tile.
  /// @param y The y-coordinate of the tile.
  /// @param tile The tile id to draw.
  /// @param scanline The current LCD scanline.
  /// @param flipX Whether the tile should be flipped vertically.
  /// @param flipY Whether the tile should be flipped horizontally.
  /// @param bank The tile bank to use.
  /// @param basePriority The current priority for the given tile.
  /// @param sprite Whether the tile beints to a sprite or not.
  void drawTile(Palette palette, List<int> data, int x, int y, int tile, int scanline, bool flipX, bool flipY, int bank, int basePriority, bool sprite)
  {
    // Store a local copy to save a lot of load opcodes.
    int line = scanline - y;
    int addressBase = MemoryAddresses.VRAM_PAGESIZE * bank + tile * 16;

    // 8 pixel width
    for(int px = 0; px < 8; px++)
    {
      // Destination pixels
      int dx = x + px;

      // Skip if out of bounds
      if(dx < 0 || dx >= PPU.LCD_WIDTH || scanline >= PPU.LCD_HEIGHT)
      {
        continue;
      }

      // Check if our current priority should overwrite the current priority
      int index = dx + scanline * PPU.LCD_WIDTH;
      if(basePriority != 0 && basePriority < (data[index] & 0xFF000000))
      {
        continue;
      }

      // Handle the x and y flipping by tweaking the indexes we are accessing
      int logicalLine = (flipY ? 7 - line : line);
      int logicalX = (flipX ? 7 - px : px);
      int address = addressBase + logicalLine * 2;

      // Upper bit of the color number
      int paletteUpper = (((this.cpu.mmu.readVRAM(address + 1) & (0x80 >> logicalX)) >> (7 - logicalX)) << 1);
      // lower bit of the color number
      int paletteLower = ((this.cpu.mmu.readVRAM(address) & (0x80 >> logicalX)) >> (7 - logicalX));

      int paletteIndex = paletteUpper | paletteLower;
      int priority = (basePriority == 0) ? (paletteIndex == 0 ? PPU.P_1 : PPU.P_3) : basePriority;

      if(sprite && paletteIndex == 0)
      {
        continue;
      }

      if(priority >= (data[index] & 0xFF000000))
      {
        data[index] = priority | palette.getColor(paletteIndex);
      }
    }
  }

  /// Attempts to draw all sprites.
  ///
  /// GameBoy video controller can display up to 40 sprites, but only a maximum of 10 per line.
  ///
  /// @param data The raster to write to.
  /// @param scanline The current scanline.
  void drawSprites(List<int> data, int scanline)
  {
    if(!Configuration.drawSpriteLayer)
    {
      return;
    }

    // Hold local references to save a lot of load opcodes
    bool tall = this.isUsingTallSprites();
    bool isColorGB = this.cpu.cartridge.gameboyType == GameboyType.COLOR;

    // Actual GameBoy hardware can only handle drawing 10 sprites per line
    for(int i = 0; i < this.cpu.mmu.oam.length && this.spritesDrawnPerLine[scanline] < 10; i += 4)
    {
      // Specifies the sprites vertical position on the screen (minus 16). An offscreen value (for example, Y=0 or Y>=160) hides the sprite.
      int y = this.cpu.mmu.readOAM(i) & 0xff;

      // Have we exited our bounds
      if(!tall && !(y - 16 <= scanline && scanline < y - 8))
      {
        continue;
      }

      // Specifies the sprites horizontal position on the screen (minus 8).
      // An offscreen value (X=0 or X>=168) hides the sprite, but the sprite still affects the priority ordering.
      int x = this.cpu.mmu.readOAM(i + 1) & 0xff;

      // Specifies the sprites Tile Number (00-FF). This (unsigned) value selects a tile from memory at 8000h-8FFFh.
      // In CGB Mode this could be either in VRAM Bank 0 or 1, depending on Bit 3 of the following int.
      int tile = this.cpu.mmu.readOAM(i + 2) & 0xff;

      int attributes = this.cpu.mmu.readOAM(i + 3);

      int vrambank = ((attributes & 0x8) != 0 && isColorGB) ? 1 : 0;
      int priority = ((attributes & 0x80) != 0) ? PPU.P_2 : PPU.P_5;
      bool flipX = (attributes & 0x20) != 0;
      bool flipY = (attributes & 0x40) != 0;

      // Palette selection
      Palette pal = this.spritePalettes[isColorGB ? (attributes & 0x7) : ((attributes >> 4) & 0x1)];

      // Handle drawing double sprites
      if(tall)
      {
        // If we're using tall sprites we actually have to flip the order that we draw the top/bottom tiles
        int hi = flipY ? (tile | 0x01) : (tile & 0xFE);
        int lo = flipY ? (tile & 0xFE) : (tile | 0x01);

        if(y - 16 <= scanline && scanline < y - 8)
        {
          this.drawTile(pal, data, x - 8, y - 16, hi, scanline, flipX, flipY, vrambank, priority, true);
          this.spritesDrawnPerLine[scanline]++;
        }

        if(y - 8 <= scanline && scanline < y)
        {
          this.drawTile(pal, data, x - 8, y - 8, lo, scanline, flipX, flipY, vrambank, priority, true);
          this.spritesDrawnPerLine[scanline]++;
        }
      }
      else
      {
        this.drawTile(pal, data, x - 8, y - 16, tile, scanline, flipX, flipY, vrambank, priority, true);
        this.spritesDrawnPerLine[scanline]++;
      }
    }
  }

  /// Determines whether the display is enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool displayEnabled()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.LCDC) & MemoryRegisters.LCDC_CONTROL_OPERATION_BIT) != 0;
  }

  /// Determines whether the background layer is enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool backgroundEnabled()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.LCDC) & MemoryRegisters.LCDC_BGWINDOW_DISPLAY_BIT) != 0;
  }

  /// Determines the window tile map offset from the LCDC register.
  ///
  /// @return The offset.
  int getWindowTileMapOffset()
  {
    if((this.cpu.mmu.readRegisterByte(MemoryRegisters.LCDC) & MemoryRegisters.LCDC_WINDOW_TILE_MAP_DISPLAY_SELECT_BIT) != 0)
    {
      return 0x1c00;
    }

    return 0x1800;
  }

  /// Determines the background tile map offset from the LCDC register.
  ///
  /// @return The offset.
  int getBackgroundTileMapOffset()
  {
    if((this.cpu.mmu.readRegisterByte(MemoryRegisters.LCDC) & MemoryRegisters.LCDC_BG_TILE_MAP_DISPLAY_SELECT_BIT) != 0)
    {
      return 0x1c00;
    }

    return 0x1800;
  }

  /// Determines whether tall sprites are enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool isUsingTallSprites()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.LCDC) & MemoryRegisters.LCDC_SPRITE_SIZE_BIT) != 0;
  }

  /// Determines whether sprites are enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool spritesEnabled()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.LCDC) & MemoryRegisters.LCDC_SPRITE_DISPLAY_BIT) != 0;
  }

  /// Determines whether the window is enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool windowEnabled()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.LCDC) & MemoryRegisters.LCDC_WINDOW_DISPLAY_BIT) != 0;
  }

  /// Tile patterns are taken from the Tile Data Table located either at $8000-8FFF or $8800-97FF.
  /// In the first case, patterns are numbered with unsigned numbers from 0 to 255 (i.e. pattern #0 lies at address $8000).
  /// In the second case, patterns have signed numbers from -128 to 127 (i.e. pattern #0 lies at address $9000).
  ///
  /// The Tile Data Table address for the background can be selected via LCDC register.
  int getTileDataOffset()
  {
    if((this.cpu.mmu.readRegisterByte(MemoryRegisters.LCDC) & MemoryRegisters.LCDC_BGWINDOW_TILE_DATA_SELECT_BIT) != 0)
    {
      return 0x0;
    }

    return 0x0800;
  }

  /// Fetches the current background X-coordinate from the WX register.
  ///
  /// @return The signed offset.
  int getScrollX()
  {
    return this.cpu.mmu.readRegisterByte(MemoryRegisters.SCX) & 0xFF;
  }

  /// Fetches the current background Y-coordinate from the SCY register.
  ///
  /// @return The signed offset.
  int getScrollY()
  {
    return this.cpu.mmu.readRegisterByte(MemoryRegisters.SCY) & 0xff;
  }

  /// Fetches the current window X-coordinate from the WX register.
  ///
  /// @return The unsigned offset.
  int getWindowPosX()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.WX) & 0xFF) - 7;
  }

  /// Fetches the current window Y-coordinate from the WY register.
  ///
  /// @return The unsigned offset.
  int getWindowPosY()
  {
    return this.cpu.mmu.readRegisterByte(MemoryRegisters.WY) & 0xFF;
  }
}