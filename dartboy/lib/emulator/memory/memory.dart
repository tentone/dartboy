import 'dart:math';

import '../cpu/cpu.dart';
import './cartridge.dart';
import './hdma.dart';
import './memory_addresses.dart';
import './memory_registers.dart';

/// Generic memory container used to represent memory spaces in the gameboy system.
///
/// Contains all the memory spaces of the gameboy except for the cartridge data.
///
/// Can be used to represent booth ROM or RAM memory and provides Byte based access.
class Memory
{
  /// Size of a page of Video RAM, in bytes. 8kb.
  static const int VRAM_PAGESIZE = 0x2000;

  /// Size of a page of Work RAM, in bytes. 4kb.
  static const int WRAM_PAGESIZE = 0x1000;

  /// Size of a page of ROM, in bytes. 16kb.
  static const int ROM_PAGESIZE = 0x4000;

  /// Register values, mapped from $FF00-$FF7F + HRAM ($FF80-$FFFE) + Interrupt Enable Register ($FFFF)
  List<int> registers;

  /// Sprite Attribute Table, mapped from $FE00-$FE9F.
  List<int> oam;

  /// Video RAM, mapped from $8000-$9FFF.
  /// On the GBC, this bank is switchable 0-1 by writing to $FF4F.
  List<int> vram;

  /// Work RAM, mapped from $C000-$CFFF and $D000-$DFFF.
  /// On the GBC, this bank is switchable 1-7 by writing to $FF07.
  List<int> wram;

  /// The current page of Video RAM, always multiples of Memory.VRAM_PAGESIZE.
  /// On non-GBC, this is always 0.
  int vramPageStart = 0;

  /// The current page of Work RAM, always multiples of Memory.WRAM_PAGESIZE.
  /// On non-GBC, this is always Memory.VRAM_PAGESIZE.
  int wramPageStart = WRAM_PAGESIZE;

  /// The current page of ROM, always multiples of Memory.ROM_PAGESIZE.
  int romPageStart = ROM_PAGESIZE;

  /// CPU that is using the MMU, useful to trigger changes in other parts affected by memory changes.
  CPU cpu;

  /// HDMA memory controller (only available on gameboy color games).
  ///
  /// Used for direct memory copy operations.
  HDMA hdma;

  Memory(CPU cpu)
  {
    this.cpu = cpu;
    this.hdma = null;
    this.initialize();
  }

  /// Initialize the memory, create the data array with the defined size.
  void initialize()
  {
    this.vramPageStart = 0;
    this.wramPageStart = Memory.WRAM_PAGESIZE;
    this.romPageStart = Memory.ROM_PAGESIZE;

    this.registers = new List<int>(0x100);
    this.registers.fillRange(0, this.registers.length, 0);

    this.oam = new List<int>(0xA0);
    this.oam.fillRange(0, this.oam.length, 0);

    this.wram = new List<int>(Memory.WRAM_PAGESIZE * (this.cpu.cartridge.gameboyType == GameboyType.COLOR ? 8 : 2));
    this.wram.fillRange(0, this.wram.length, 0);

    this.vram = new List<int>(Memory.VRAM_PAGESIZE * (this.cpu.cartridge.gameboyType == GameboyType.COLOR ? 2 : 1));
    this.vram.fillRange(0, this.vram.length, 0);
  }

  /// Write a byte into memory address
  void writeByte(int address, int value)
  {
    value &= 0xFF;
    address &= 0xFFFF;

    int block = address & 0xF000;

    if(address < MemoryAddresses.CARTRIDGE_ROM_END)
    {
      //throw new Exception('Cannot write data into cartridge ROM memory.');
      return;
    }
    else if(address >= MemoryAddresses.VIDEO_RAM_START && address < MemoryAddresses.VIDEO_RAM_END)
    {
      this.vram[this.vramPageStart + address - MemoryAddresses.VIDEO_RAM_START] = value;
    }
    else if(address >= MemoryAddresses.SWITCHABLE_RAM_START && address < MemoryAddresses.SWITCHABLE_RAM_END)
    {
      //throw new Exception('Cannot write data into cartridge RAM memory.');
      return;
    }
    else if(block == MemoryAddresses.RAM_A_START)
    {
      this.wram[address - MemoryAddresses.RAM_A_START] = value;
    }
    else if(block == MemoryAddresses.RAM_A_SWITCHABLE_START)
    {
      this.wram[this.wramPageStart + address - MemoryAddresses.RAM_A_START] = value;
    }
    else if(address >= MemoryAddresses.EMPTY_A_START && address < MemoryAddresses.EMPTY_A_END)
    {
      return;
    }
    else if(address >= MemoryAddresses.RAM_A_ECHO_START && address < MemoryAddresses.RAM_A_ECHO_END)
    {
      this.writeByte(address - MemoryAddresses.RAM_A_ECHO_START, value);
    }
    else if(address >= MemoryAddresses.OAM_START && address < MemoryAddresses.EMPTY_A_END)
    {
      this.oam[address - MemoryAddresses.OAM_START] = value;
    }
    else if(address >= MemoryAddresses.IO_START)
    {
      this.writeIO(address - MemoryAddresses.IO_START, value);
    }
  }

  /// Write data into the IO section of memory space.
  void writeIO(int address, int value)
  {
    switch (address)
    {
      case 0x4d:
        this.cpu.doubleSpeed = (value & 0x01) != 0;
        break;
      case 0x69:
        {
          if(this.cpu.cartridge.gameboyType == GameboyType.CLASSIC)
          {
            break;
          }

          int ff68 = this.registers[0x68];
          int currentRegister = ff68 & 0x3f;

          this.cpu.ppu.setBackgroundPalette(currentRegister, value);

          if ((ff68 & 0x80) != 0)
          {
            currentRegister++;
            currentRegister %= 0x40;
            this.registers[0x68] = (0x80 | currentRegister) & 0xFF;
          }
          break;
        }
      case 0x6b:
        {
          if(this.cpu.cartridge.gameboyType == GameboyType.CLASSIC)
          {
            break;
          }

          int ff6a = this.registers[0x6a];
          int currentRegister = ff6a & 0x3f;
          this.cpu.ppu.setSpritePalette(currentRegister, value);

          if ((ff6a & 0x80) != 0)
          {
            currentRegister++;
            currentRegister %= 0x40;
            this.registers[0x6a] = (0x80 | currentRegister) & 0xFF;
          }
          break;
        }
      case 0x55: // HDMA start
        {
          if(this.cpu.cartridge.gameboyType == GameboyType.CLASSIC)
          {
            break;
          }

          // Get the configuration of the HDMA transfer
          int length = ((value & 0x7f) + 1) * 0x10;
          int source = ((this.registers[0x51] & 0xff) << 8) | (this.registers[0x52] & 0xF0);
          int dest = ((this.registers[0x53] & 0x1f) << 8) | (this.registers[0x54] & 0xF0);

          if ((value & 0x80) != 0)
          {
            // H-Blank DMA
            this.hdma = new HDMA(this, source, dest, length);
            this.registers[0x55] = (length ~/ 0x10 - 1) & 0xFF;
            break;
          }
          else
          {
            if(this.hdma != null)
            {
              //TODO <DEBUG PRINT>
              //print("Terminated HDMA from " + source.toString() + "-" + dest.toString() + ", " + length.toString() + " remaining.");
            }

            // General DMA
            for (int i = 0; i < length; i++)
            {
              this.vram[this.vramPageStart + dest + i] = readByte(source + i) & 0xFF;
            }
            this.registers[0x55] = 0xFF;
          }
          break;
        }
      case MemoryRegisters.R_VRAM_BANK:
        {
          if (this.cpu.cartridge.gameboyType == GameboyType.COLOR)
          {
            this.vramPageStart = Memory.VRAM_PAGESIZE * (value & 0x3);
          }
          break;
        }
      case MemoryRegisters.R_WRAM_BANK:
        {
          if (this.cpu.cartridge.gameboyType == GameboyType.COLOR)
          {
            this.wramPageStart = Memory.WRAM_PAGESIZE * max(1, value & 0x7);
          }
          break;
        }
      case MemoryRegisters.R_NR14:
        if ((this.registers[MemoryRegisters.R_NR14] & 0x80) != 0)
        {
          //this.cpu.sound.channel1.restart();
          value &= 0x7f;
        }
        this.registers[address] = value & 0xFF;
        break;
      case MemoryRegisters.R_NR10:
      case MemoryRegisters.R_NR11:
      case MemoryRegisters.R_NR12:
      case MemoryRegisters.R_NR13:
        this.registers[address] = value & 0xFF;
        //this.cpu.sound.channel1.update();
        break;
      case MemoryRegisters.R_NR24:
        if ((value & 0x80) != 0)
        {
          //this.cpu.sound.channel2.restart();
          value &= 0x7F;
        }
        this.registers[address] = value & 0xFF;
        break;
      case MemoryRegisters.R_NR21:
      case MemoryRegisters.R_NR22:
      case MemoryRegisters.R_NR23:
        this.registers[address] = value & 0xFF;
        //this.cpu.sound.channel2.update();
        break;
      case MemoryRegisters.R_NR34:
        if ((value & 0x80) != 0)
        {
          //this.cpu.sound.channel3.restart();
          value &= 0x7F;
        }
        this.registers[address] = value & 0xFF;
        break;
      case MemoryRegisters.R_NR30:
      case MemoryRegisters.R_NR31:
      case MemoryRegisters.R_NR32:
      case MemoryRegisters.R_NR33:
        this.registers[address] = value & 0xFF;
        //this.cpu.sound.channel3.update();
        break;
      case MemoryRegisters.R_NR44:
        if ((value & 0x80) != 0)
        {
          //this.cpu.sound.channel4.restart();
          value &= 0x7F;
        }
        this.registers[address] = value & 0xFF;
        break;
      case MemoryRegisters.R_NR41:
      case MemoryRegisters.R_NR42:
      case MemoryRegisters.R_NR43:
        this.registers[address] = value & 0xFF;
        //this.cpu.sound.channel4.update();
        break;
      case MemoryRegisters.R_DMA:
        {
          int addressBase = value * 0x100;

          for (int i = 0; i < 0xA0; i++)
          {
            this.writeByte(0xFE00 + i, this.readByte(addressBase + i));
          }
          break;
        }
      case MemoryRegisters.R_DIV:
        value = 0;
        break;
      case MemoryRegisters.R_TAC:
        if (((registers[MemoryRegisters.R_TAC] ^ value) & 0x03) != 0)
        {
          this.cpu.timerCycle = 0;
          this.registers[MemoryRegisters.R_TIMA] = this.registers[MemoryRegisters.R_TMA];
        }
        break;
      case MemoryRegisters.R_LCD_STAT:
        break;
      default:
        if (0x30 <= address && address < 0x40)
        {
          //this.cpu.sound.channel3.updateSample(address - 0x30, (byte) value);
        }
    }

    this.registers[address] = value & 0xFF;
  }

  /// Read a byte from memory address
  ///
  /// If the address falls into the cartridge addressing zone read directly from the cartridge object.
  int readByte(int address)
  {
    address &= 0xFFFF;
    int block = address & 0xF000;

    if(address < MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START)
    {
      return this.cpu.cartridge.data[address];
    }
    if(address >= MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START && address < MemoryAddresses.CARTRIDGE_ROM_END)
    {
      return this.cpu.cartridge.data[this.romPageStart + address - MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START];
    }
    else if(address >= MemoryAddresses.VIDEO_RAM_START && address < MemoryAddresses.VIDEO_RAM_END)
    {
      return this.vram[this.vramPageStart + address - MemoryAddresses.VIDEO_RAM_START];
    }
    else if(address >= MemoryAddresses.SWITCHABLE_RAM_START && address < MemoryAddresses.SWITCHABLE_RAM_END)
    {
      return 0;
    }
    else if(block == MemoryAddresses.RAM_A_START)
    {
      return this.wram[address - MemoryAddresses.RAM_A_START];
    }
    else if(block == MemoryAddresses.RAM_A_SWITCHABLE_START)
    {
      return this.wram[this.wramPageStart + address - MemoryAddresses.RAM_A_START];
    }
    else if(block == 0xE000 || block == 0xF000)
    {
      if(address >= MemoryAddresses.EMPTY_A_START && address < MemoryAddresses.EMPTY_A_END)
      {
        return 0xFF;
      }
      else if(address >= MemoryAddresses.RAM_A_ECHO_START && address < MemoryAddresses.RAM_A_ECHO_END)
      {
        return this.readByte(address - MemoryAddresses.RAM_A_ECHO_START);
      }
      else if(address >= MemoryAddresses.OAM_START && address < MemoryAddresses.EMPTY_A_END)
      {
        return this.oam[address - MemoryAddresses.OAM_START];
      }
      else if(address >= MemoryAddresses.IO_START)
      {
        return this.readIO(address - MemoryAddresses.IO_START);
      }
    }

    return 0xFF;
  }

  // Read IO address
  int readIO(int address)
  {
    if(address == 0x4d)
    {
      return this.cpu.doubleSpeed ? 0x80 : 0x0;
    }

    return this.registers[address];
  }
}
