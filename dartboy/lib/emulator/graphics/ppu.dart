import '../cpu/cpu.dart';
import '../memory/memory_registers.dart';
import '../memory/memory_addresses.dart';
import '../memory/cartridge.dart';
import './palette_colors.dart';
import './palette.dart';

/// LCD class handles all the screen drawing tasks.
///
/// Is responsible for managing the sprites and background layers.
class PPU
{
  static const int LCD_WIDTH = 160;
  static const int LCD_HEIGHT = 144;
  static const double LCD_RATIO = LCD_WIDTH / LCD_HEIGHT;

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
  List<int> screenBuffer = new List<int>(LCD_WIDTH * LCD_HEIGHT);

  /// Background palettes. On CGB, 0-7 are used. On GB, only 0 is used.
  List<Palette> bgPalettes = new List<Palette>(8);

  /// Sprite palettes. 0-7 used on CGB, 0-1 used on GB.
  List<Palette> spritePalettes = new List<Palette>(8);

  /// Background palette memory on the CGB, indexed through $FF69.
  List<int> gbcBackgroundPaletteMemory = new List<int>(0x40);

  /// Sprite palette memory on the CGB, indexed through $FF6B.
  List<int> gbcSpritePaletteMemory = new List<int>(0x40);

  /// Stores number of sprites drawn per each of the 144 scanlines this frame.
  ///
  /// Actual Gameboy hardware can only draw 10 sprites/line, so we artificially introduce this limitation using this array.
  List<int> spritesDrawnPerLine = new List<int>(144);

  /// A counter for the number of cycles elapsed since the last LCD event.
  int lcdCycles = 0;

  /// Accumulator for how many VBlanks have been performed since the last reset.
  int currentVBlankCount = 0;

  /// The timestamp of the last second, in nanoseconds.
  int lastSecondTime = -1;

  /// The last measured Emulator.cycle.
  int lastCoreCycle;

  PPU(CPU core)
  {
    this.cpu = core;
  }

  /// Initializes all palette RAM to the default on Gameboy boot.
  void initializePalettes()
  {
    if(this.cpu.mmu.cartridge.gameboyType == GameboyType.COLOR)
    {
      this.gbcBackgroundPaletteMemory.fillRange(0, this.gbcBackgroundPaletteMemory.length, 0x1f);

      // Create palette structures
      for (int i = 0; i < this.spritePalettes.length; i++)
      {
        this.spritePalettes[i] = new GBCPalette(new List<int>(4));
      }

      for (int i = 0; i < this.bgPalettes.length; i++)
      {
        this.bgPalettes[i] = new GBCPalette(new List<int>(4));
      }

      // And "load" them from RAM
      loadPalettesFromMemory(this.gbcSpritePaletteMemory, this.spritePalettes);
      loadPalettesFromMemory(this.gbcBackgroundPaletteMemory, this.bgPalettes);
    }
    else
    {
      /// FF69 - BCPD/BGPD - CGB Mode Only - Background Palette Data
      /// This register allows to read/write data to the CGBs Background Palette Memory, addressed through Register FF68.
      /// Each color is defined by two ints (Bit 0-7 in first int).
      ///
      /// Bit 0-4   Red Intensity   (00-1F)
      /// Bit 5-9   Green Intensity (00-1F)
      /// Bit 10-14 Blue Intensity  (00-1F)
      ///
      /// Much like VRAM, Data in Palette Memory cannot be read/written during the time when the LCD Controller is
      /// reading from it. (That is when the STAT register indicates Mode 3).
      /// Note: Initially all background colors are initialized as white.
      PaletteColors colors = PaletteColors.getByHash(this.cpu.mmu.cartridge.checksum);

      this.bgPalettes[0] = new GBPalette(this.cpu, colors.bg, MemoryRegisters.R_BGP);
      this.spritePalettes[0] = new GBPalette(this.cpu, colors.obj0, MemoryRegisters.R_OBP0);
      this.spritePalettes[1] = new GBPalette(this.cpu, colors.obj1, MemoryRegisters.R_OBP1);
    }
  }

  /// Reloads all Gameboy Color palettes.
  ///
  /// @param from Palette RAM to load from.
  /// @param to   Reference to an array of Palettes to populate.
  void loadPalettesFromMemory(List<int> from, List<Palette> to)
  {
    // 8 palettes
    for (int i = 0; i < 8; i++)
    {
      // 4 ints per palette
      for (int j = 0; j < 4; ++j)
      {
        updatePalette(from, to[i], i, j);
      }
    }
  }

  /// Performs an update to a int of palette RAM.
  ///
  /// @param from The palette RAM to read from.
  /// @param to   Reference to an array of Palettes to update.
  /// @param i    The palette index being updated.
  /// @param j    The int index of the palette being updated.
  void updatePalette(List<int> from, Palette to, int i, int j)
  {
    /// This register allows to read/write data to the CGBs Background Palette Memory, addressed through Register FF68.
    /// Each color is defined by two ints (Bit 0-7 in first int).
    ///
    /// Bit 0-4   Red Intensity   (00-1F)
    /// Bit 5-9   Green Intensity (00-1F)
    /// Bit 10-14 Blue Intensity  (00-1F)
    
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
    to.colors[j] = r | g | b;
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
  /// #method
  ///
  /// @param cycles The number of CPU cycles elapsed since the last call to tick.
  void tick(int cycles)
  {
    // Accumulate to an internal counter
    lcdCycles += cycles;

    // 4.194304MHz clock, 154 scanlines per frame, 59.7 frames/second = ~456 cycles / line
    if (lcdCycles >= 456)
    {
      lcdCycles -= 456;

      /// The LY indicates the vertical line to which the present data is transferred to the LCD Driver.
      /// The LY can take on any value between 0 through 153. The values between 144 and 153 indicate the V-Blank period.
      int LY = cpu.mmu.readRegisterByte(MemoryRegisters.R_LY) & 0xFF;

      // draw the scanline
      bool displayEnabled = this.displayEnabled();

      // We may be running headlessly, so we must check before drawing
      if (displayEnabled)
      {
        draw(LY);
      }

      // Increment LY, and wrap at 154 lines
      this.cpu.mmu.writeRegisterByte(MemoryRegisters.R_LY, (((LY + 1) % 154) & 0xff));
      
      if (LY == 0)
      {
        if (this.lastSecondTime == -1)
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

      bool isVBlank = 144 <= LY;

      if (!isVBlank && this.cpu.mmu.hdma != null)
      {
        //System.err.println(LY);
        this.cpu.mmu.hdma.tick();
      }

      this.cpu.mmu.writeRegisterByte(MemoryRegisters.R_LCD_STAT, this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCD_STAT) & ~0x03);

      int mode = 0;
      if (isVBlank)
      {
        mode = 0x01;
      }

      this.cpu.mmu.writeRegisterByte(MemoryRegisters.R_LCD_STAT, this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCD_STAT) | mode);

      int lcdStat = this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCD_STAT);

      if (displayEnabled && !isVBlank)
      {
        /// INT 48 - LCDC Status Interrupt
        ///
        /// There are various reasons for this interrupt to occur as described by the STAT register ($FF40).
        /// One very popular reason is to indicate to the user when the video hardware is about to redraw
        /// a given LCD line.
        ///
        /// This is determined with an LY == LYC comparison.
        ///
        /// @{see http://bgb.bircd.org/pandocs.htm#lcdstatusregister}
        if ((lcdStat & MemoryRegisters.LCD_STAT_COINCIDENCE_INTERRUPT_ENABLED_BIT) != 0)
        {
          int lyc = (this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LYC) & 0xff);

          // Fire when LYC == LY
          if (lyc == LY)
          {
            this.cpu.setInterruptTriggered(MemoryRegisters.LCDC_BIT);
            this.cpu.mmu.writeRegisterByte(MemoryRegisters.R_LCD_STAT, this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCD_STAT) | MemoryRegisters.LCD_STAT_COINCIDENCE_BIT);
          }
          else
          {
            this.cpu.mmu.writeRegisterByte(MemoryRegisters.R_LCD_STAT, this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCD_STAT) & ~MemoryRegisters.LCD_STAT_COINCIDENCE_BIT);
          }
        }

        if ((lcdStat & MemoryRegisters.LCD_STAT_HBLANK_MODE_BIT) != 0)
        {
          this.cpu.setInterruptTriggered(MemoryRegisters.LCDC_BIT);
        }
      }

      /// INT 40 - V-Blank Interrupt
      ///
      /// The V-Blank interrupt occurs ca. 59.7 times a second on a regular GB and ca. 61.1 times a second
      /// on a Super GB (SGB). This interrupt occurs at the beginning of the V-Blank period (LY=144).
      /// During this period video hardware is not using video ram so it may be freely accessed.
      /// This period lasts approximately 1.1 milliseconds.
      ///
      /// @{see http://bgb.bircd.org/pandocs.htm#lcdinterrupts}
      // use 143 here as we've just finished processing line 143 and will start 144
      if (LY == 143)
      {
        // Draw image into the display
        // TODO <ADD CODE HERE>
        //graphics.drawImage(screenBuffer, 0, 0, core.display.getWidth(), core.display.getHeight(), null);
        //this.core.lcdWidget.


        // Trigger interrupts if the display is enabled
        if (displayEnabled)
        {
          // Trigger VBlank
          cpu.setInterruptTriggered(MemoryRegisters.VBLANK_BIT);

          // Trigger LCDC if enabled
          if ((lcdStat & MemoryRegisters.LCD_STAT_VBLANK_MODE_BIT) != 0)
          {
            cpu.setInterruptTriggered(MemoryRegisters.LCDC_BIT);
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
    if (!displayEnabled()) return;

    // We still receive these calls for scanlines in vblank, but we can just ignore them
    if (scanline >= 144 || scanline < 0) return;

    // Reset our sprite counter
    this.spritesDrawnPerLine[scanline] = 0;

    // If we've reached the start of a frame, clear the current buffer
    if (scanline == 0)
    {
      for(var i = 0; i < this.screenBuffer.length; i++)
      {
        this.screenBuffer[i] = 0;
      }
    }

    // Draw the background if it's enabled
    if (backgroundEnabled())
    {
      drawBackgroundTiles(this.screenBuffer, scanline);
    }

    // If sprites are enabled, draw them.
    if (spritesEnabled())
    {
      drawSprites(this.screenBuffer, scanline);
    }

    // If the window appears in this scanline, draw it
    if (windowEnabled() && scanline >= getWindowPosY() && getWindowPosX() < LCD_WIDTH && getWindowPosY() >= 0)
    {
      drawWindow(this.screenBuffer, scanline);
    }
  }


  /// Attempt to draw background tiles.
  ///
  /// @param data The raster to write to.
  /// @param scanline The current scanline.
  void drawBackgroundTiles(List<int> data, int scanline)
  {
    // Local reference to save time
    int tileDataOffset = getTileDataOffset();

    // The background is scrollable
    int scrollY = getScrollY();
    int scrollX = getScrollX();

    int y = (scanline + getScrollY() % 8) ~/ 8;

    // Determine the offset into the VRAM tile bank
    int offset = getBackgroundTileMapOffset();

    /// BG Map Tile Numbers
    /// <pre>
    ///      An area of VRAM known as Background Tile Map contains the numbers of tiles to
    ///      be displayed. It is organized as 32 rows of 32 ints each. Each int contains a number
    ///      of a tile to be displayed. Tile patterns are taken from the Tile Data Table located either
    ///      at $8000-8FFF or $8800-97FF. In the first case, patterns are numbered with
    ///      unsigned numbers from 0 to 255 (i.e. pattern #0 lies at address $8000). In the second case,
    ///      patterns have signed numbers from -128 to 127 (i.e. pattern #0 lies at address $9000).
    ///      The Tile Data Table address for the background can be selected via LCDC register.
    /// </pre>
    ///
    /// @{see http://bgb.bircd.org/pandocs.htm#vrambackgroundmaps}

    // 20 8x8 tiles fit in a 160px-wide screen
    for (int x = 0; x < 21; x++)
    {
      int addressBase = (offset + ((y + scrollY / 8) % 32 * 32) + ((x + scrollX / 8) % 32)).toInt();

      // add 256 to jump into second tile pattern table
      int tile = tileDataOffset == 0 ? this.cpu.mmu.readVRAM(addressBase) & 0xff : this.cpu.mmu.readVRAM(addressBase) + 256;

      // Tile attributes
      int gbcVramBank = 0;
      int gbcPalette = 0;

      bool flipX = false;
      bool flipY = false;

      /// BG Map Attributes (CGB Mode only)
      /// <pre>
      ///      In CGB Mode, an additional map of 32x32 ints is stored in VRAM Bank 1 (each int defines attributes for the corresponding tile-number map entry in VRAM Bank 0):
      ///
      ///      Bit 0-2  Background Palette number  (BGP0-7)
      ///      Bit 3    Tile VRAM Bank number      (0=Bank 0, 1=Bank 1)
      ///      Bit 4    Not used
      ///      Bit 5    Horizontal Flip            (0=Normal, 1=Mirror horizontally)
      ///      Bit 6    Vertical Flip              (0=Normal, 1=Mirror vertically)
      ///      Bit 7    BG-to-OAM Priority         (0=Use OAM priority bit, 1=BG Priority)
      /// </pre>
      ///
      /// @{see http://bgb.bircd.org/pandocs.htm#vrambackgroundmaps}

      if (this.cpu.mmu.cartridge.gameboyType == GameboyType.COLOR)
      {
        int attribs = this.cpu.mmu.readVRAM(MemoryAddresses.VRAM_PAGESIZE + addressBase);

        if ((attribs & 0x8) != 0)
        {
          gbcVramBank = 1;
        }

        flipX = (attribs & 0x20) != 0;
        flipY = (attribs & 0x40) != 0;
        gbcPalette = (attribs & 0x7);
      }

      // Delegate tile drawing
      drawTile(this.bgPalettes[gbcPalette], data, -(scrollX % 8) + x * 8, -(scrollY % 8) + y * 8, tile, scanline, flipX, flipY, gbcVramBank, 0, false);
    }
  }


  /// Attempt to draw window tiles.
  ///
  /// @param data     The raster to write to.
  /// @param scanline The current scanline.

  void drawWindow(List<int> data, int scanline)
  {
    int tileDataOffset = getTileDataOffset();

    // The window layer is offset-able from 0,0
    int posX = getWindowPosX();
    int posY = getWindowPosY();

    int tileMapOffset = getWindowTileMapOffset();

    int y = (scanline - posY) ~/ 8;
    for (int x = getWindowPosX() ~/ 8; x < 21; x++)
    {
      // 32 tiles a row
      int addressBase = tileMapOffset + (x + y * 32);

      // add 256 to jump into second tile pattern table
      int tile = tileDataOffset == 0 ? this.cpu.mmu.readVRAM(addressBase) & 0xff : this.cpu.mmu.readVRAM(addressBase) + 256;

      int gbcVramBank = 0;
      bool flipX = false;
      bool flipY = false;
      int gbcPalette = 0;


      /// Same rules apply here as for background tiles.
      ///
      /// @{see http://bgb.bircd.org/pandocs.htm#vrambackgroundmaps}
      if (this.cpu.mmu.cartridge.gameboyType == GameboyType.COLOR)
      {
        int attribs = this.cpu.mmu.readVRAM(MemoryAddresses.VRAM_PAGESIZE + addressBase);

        if ((attribs & 0x8) != 0)
        {
          gbcVramBank = 1;
        }
        flipX = (attribs & 0x20) != 0;
        flipY = (attribs & 0x40) != 0;
        gbcPalette = (attribs & 0x07);
      }

      drawTile(this.bgPalettes[gbcPalette], data, posX + x * 8, posY + y * 8, tile, scanline, flipX, flipY, gbcVramBank, P_6, false);
    }
  }

  /// Attempt to draw a single line of a tile.
  ///
  /// @param palette The palette currently in use.
  /// @param data An array of W/// H elements, representing the LCD raster.
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
    for (int px = 0; px < 8; px++)
    {
      // Destination pixels
      int dx = x + px;

      // If we're out of bounds, continue iteration
      if (dx < 0 || dx >= LCD_WIDTH || scanline >= LCD_HEIGHT)
      {
        continue;
      }

      // Check if our current priority should overwrite the current priority
      int index = dx + scanline * LCD_WIDTH;
      if (basePriority != 0 && basePriority < (data[index] & 0xFF000000))
      {
        continue;
      }

      // For each line, the first int defines the least significant bits of the color numbers for each pixel, and the second int defines the upper bits of the color numbers.
      // In either case, Bit 7 is the leftmost pixel, and Bit 0 the rightmost.

      // here we handle the x and y flipping by tweaking the indexes we are accessing
      int logicalLine = (flipY ? 7 - line : line);
      int logicalX = (flipX ? 7 - px : px);

      int address = addressBase + logicalLine * 2;

      // each tile takes up 16 ints, and each line takes 2 ints
      int paletteIndex = (((this.cpu.mmu.readVRAM(address + 1) & (0x80 >> logicalX)) >> (7 - logicalX)) << 1) // this is the upper bit of the color number
      | ((this.cpu.mmu.readVRAM(address) & (0x80 >> logicalX)) >> (7 - logicalX)); // << 0, this is the lower bit of the color number

      bool index0 = paletteIndex == 0;
      int priority = basePriority == 0 ? (index0 ? P_1 : P_3) : basePriority;

      if (sprite && index0)
      {
        continue;
      }

      if (priority >= (data[index] & 0xFF000000))
      {
        data[index] = priority | palette.getColor(paletteIndex);
      }
    }
  }

  /// Attempts to draw all sprites.
  ///
  /// @param data     The raster to write to.
  /// @param scanline The current scanline.
  void drawSprites(List<int> data, int scanline)
  {
    // Hold local references to save a lot of load opcodes
    bool tall = isUsingTallSprites();
    bool isColorGB = this.cpu.mmu.cartridge.gameboyType == GameboyType.COLOR;

    // Actual GameBoy hardware can only handle drawing 10 sprites per line
    for(int i = 0; i < MemoryAddresses.OAM_SIZE && this.spritesDrawnPerLine[scanline] < 10; i += 4)
    {
      /// Sprite attributes reside in the Sprite Attribute Table (OAM - Object Attribute Memory) at $FE00-FE9F.
      /// Each of the 40 entries consists of four ints with the following meanings:
      ///
      /// int0 - Y Position
      /// <pre>
      ///      Specifies the sprites vertical position on the screen (minus 16).
      ///      An offscreen value (for example, Y=0 or Y>=160) hides the sprite.
      /// </pre>
      ///
      /// int1 - X Position
      /// <pre>
      ///      Specifies the sprites horizontal position on the screen (minus 8).
      ///      An offscreen value (X=0 or X>=168) hides the sprite, but the sprite
      ///      still affects the priority ordering - a better way to hide a sprite is to set its Y-coordinate offscreen.
      /// </pre>
      ///
      /// int2 - Tile/Pattern Number
      /// <pre>
      ///      Specifies the sprites Tile Number (00-FF). This (unsigned) value selects a tile from memory at 8000h-8FFFh.
      ///      In CGB Mode this could be either in VRAM Bank 0 or 1, depending on Bit 3 of the following int.
      ///      In 8x16 mode, the lower bit of the tile number is ignored. Ie. the upper 8x8 tile is "NN AND FEh", and
      ///      the lower 8x8 tile is "NN OR 01h".
      /// </pre>
      ///
      /// int3 - Attributes/Flags:
      /// <pre>
      ///      Bit7   OBJ-to-BG Priority (0=OBJ Above BG, 1=OBJ Behind BG color 1-3)
      ///      (Used for both BG and Window. BG color 0 is always behind OBJ)
      ///      Bit6   Y flip          (0=Normal, 1=Vertically mirrored)
      ///      Bit5   X flip          (0=Normal, 1=Horizontally mirrored)
      ///      Bit4   Palette number ///*Non CGB Mode Only** (0=OBP0, 1=OBP1)
      ///      Bit3   Tile VRAM-Bank ///*CGB Mode Only**     (0=Bank 0, 1=Bank 1)
      ///      Bit2-0 Palette number ///*CGB Mode Only**     (OBP0-7)
      /// </pre>
      ///
      /// {@see http://bgb.bircd.org/pandocs.htm#vramspriteattributetableoam}

      int y = this.cpu.mmu.readOAM(i) & 0xff;

      // Have we exited our bounds?
      if (!tall && !(y - 16 <= scanline && scanline < y - 8))
      {
        continue;
      }

      int attribs = this.cpu.mmu.readOAM(i + 3);
      int vrambank = (attribs & 0x8) != 0 && isColorGB ? 1 : 0;
      int priority = (attribs & 0x80) != 0 ? P_2 : P_5;

      int x = this.cpu.mmu.readOAM(i + 1) & 0xff;
      int tile = this.cpu.mmu.readOAM(i + 2) & 0xff;
      bool flipX = (attribs & 0x20) != 0;
      bool flipY = (attribs & 0x40) != 0;
      int obp = isColorGB ? (attribs & 0x7) : (attribs >> 4) & 0x1;

      Palette pal = this.spritePalettes[obp];

      // Handle drawing double sprites
      if (tall)
      {
        // If we're using tall sprites we actually have to flip the order that we draw the top/bottom tiles
        int hi = flipY ? (tile | 0x01) : (tile & 0xFE);
        int lo = flipY ? (tile & 0xFE) : (tile | 0x01);

        if (y - 16 <= scanline && scanline < y - 8)
        {
          drawTile(pal, data, x - 8, y - 16, hi, scanline, flipX, flipY, vrambank, priority, true);
          this.spritesDrawnPerLine[scanline]++;
        }

        if (y - 8 <= scanline && scanline < y)
        {
          drawTile(pal, data, x - 8, y - 8, lo, scanline, flipX, flipY, vrambank, priority, true);
          this.spritesDrawnPerLine[scanline]++;
        }
      }
      else
      {
        drawTile(pal, data, x - 8, y - 16, tile, scanline, flipX, flipY, vrambank, priority, true);
        this.spritesDrawnPerLine[scanline]++;
      }
    }
  }
  
  /// Determines whether the display is enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool displayEnabled()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCDC) & MemoryRegisters.LCDC_CONTROL_OPERATION_BIT) != 0;
  }

  /// Determines whether the background layer is enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool backgroundEnabled()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCDC) & MemoryRegisters.LCDC_BGWINDOW_DISPLAY_BIT) != 0;
  }

  /// Determines the window tile map offset from the LCDC register.
  ///
  /// @return The offset.
  int getWindowTileMapOffset()
  {
    if ((this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCDC) & MemoryRegisters.LCDC_WINDOW_TILE_MAP_DISPLAY_SELECT_BIT) != 0)
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
    if ((this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCDC) & MemoryRegisters.LCDC_BG_TILE_MAP_DISPLAY_SELECT_BIT) != 0)
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
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCDC) & MemoryRegisters.LCDC_SPRITE_SIZE_BIT) != 0;
  }

  /// Determines whether sprites are enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool spritesEnabled()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCDC) & MemoryRegisters.LCDC_SPRITE_DISPLAY_BIT) != 0;
  }

  /// Determines whether the window is enabled from the LCDC register.
  ///
  /// @return The enabled state.
  bool windowEnabled()
  {
    return (this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCDC) & MemoryRegisters.LCDC_WINDOW_DISPLAY_BIT) != 0;
  }
  
  /// Tile patterns are taken from the Tile Data Table located either at $8000-8FFF or $8800-97FF.
  /// In the first case, patterns are numbered with unsigned numbers from 0 to 255 (i.e. pattern #0 lies at address $8000).
  /// In the second case, patterns have signed numbers from -128 to 127 (i.e. pattern #0 lies at address $9000).
  /// 
  /// The Tile Data Table address for the background can be selected via LCDC register.
  int getTileDataOffset()
  {
    if ((this.cpu.mmu.readRegisterByte(MemoryRegisters.R_LCDC) & MemoryRegisters.LCDC_BGWINDOW_TILE_DATA_SELECT_BIT) != 0)
    {
      return 0;
    }

    return 0x0800;
  }

  /// Fetches the current background X-coordinate from the WX register.
  ///
  /// @return The signed offset.
  int getScrollX()
  {
    return (cpu.mmu.readRegisterByte(MemoryRegisters.R_SCX) & 0xFF);
  }
  
  /// Fetches the current background Y-coordinate from the SCY register.
  ///
  /// @return The signed offset.
  int getScrollY()
  {
    return (cpu.mmu.readRegisterByte(MemoryRegisters.R_SCY) & 0xff);
  }

  /// Fetches the current window X-coordinate from the WX register.
  ///
  /// @return The unsigned offset.
  int getWindowPosX()
  {
    return (cpu.mmu.readRegisterByte(MemoryRegisters.R_WX) & 0xFF) - 7;
  }
  
  /// Fetches the current window Y-coordinate from the WY register.
  ///
  /// @return The unsigned offset.
  int getWindowPosY()
  {
    return (cpu.mmu.readRegisterByte(MemoryRegisters.R_WY) & 0xFF);
  }
}