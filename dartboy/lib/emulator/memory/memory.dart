import 'dart:math';
import 'dart:typed_data';

import '../configuration.dart';
import '../cpu/cpu.dart';
import './cartridge.dart';
import './dma.dart';
import './memory_addresses.dart';
import './memory_registers.dart';
import './gamepad.dart';

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

  /// Register values contains mostly control flags, mapped from 0xFF00-0xFF7F + HRAM (0xFF80-0xFFFE) + Interrupt Enable Register (0xFFFF)
  List<int> registers;

  /// Sprite Attribute Table, mapped from 0xFE00-0xFE9F.
  /// OAM (Object Attribute Memory)
  List<int> oam;

  /// Video RAM, mapped from 0x8000-0x9FFF.
  /// On the GBC, this bank is switchable 0-1 by writing to 0xFF4F.
  List<int> vram;

  /// Work RAM, mapped from 0xC000-0xCFFF and 0xD000-0xDFFF.
  ///
  /// On the GBC, this bank is switchable 1-7 by writing to 0xFF07.
  List<int> wram;

  /// The current page of Video RAM, always multiples of VRAM_PAGESIZE.
  ///
  /// On non-GBC, this is always 0.
  int vramPageStart;

  /// The current page of Work RAM, always multiples of WRAM_PAGESIZE.
  ///
  /// On non-GBC, this is always VRAM_PAGESIZE.
  int wramPageStart;

  /// The current page of ROM, always multiples of ROM_PAGESIZE.
  int romPageStart;

  /// CPU that is using the MMU, useful to trigger changes in other parts affected by memory changes.
  CPU cpu;

  /// DMA memory controller (only available on gameboy color games).
  ///
  /// Used for direct memory copy operations.
  DMA dma;

  Memory(CPU cpu)
  {
    this.cpu = cpu;
    this.dma = null;
  }

  /// Initialize the memory, create the data array with the defined size.
  ///
  /// Reset the memory to default boot values, Also sets all bytes in the memory space to 0 value.
  ///
  /// Should be used to reset the system state after loading new data.
  void reset()
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

    for(int i = 0; i < 0x100; i++)
    {
      this.writeIO(i, 0);
    }

    this.writeIO(0x04, 0xAB);
    this.writeIO(0x10, 0x80);
    this.writeIO(0x11, 0xBF);
    this.writeIO(0x12, 0xF3);
    this.writeIO(0x14, 0xBF);
    this.writeIO(0x16, 0x3F);
    this.writeIO(0x19, 0xBF);
    this.writeIO(0x1A, 0x7F);
    this.writeIO(0x1B, 0xFF);
    this.writeIO(0x1C, 0x9F);
    this.writeIO(0x1E, 0xBF);
    this.writeIO(0x20, 0xFF);
    this.writeIO(0x23, 0xBF);
    this.writeIO(0x24, 0x77);
    this.writeIO(0x25, 0xF3);
    this.writeIO(0x26, this.cpu.cartridge.superGameboy ? 0xF0 : 0xF1);
    this.writeIO(0x40, 0x91);
    this.writeIO(0x47, 0xFC);
    this.writeIO(0x48, 0xFF);
    this.writeIO(0x49, 0xFF);
  }

  /// Write a byte into memory address.
  ///
  /// The memory is not directly accessed some addresses might be used for I/O or memory control operations.
  void writeByte(int address, int value)
  {
    value &= 0xFF;
    address &= 0xFFFF;

    // ROM
    if(address < MemoryAddresses.CARTRIDGE_ROM_END)
    {
      return;
    }
    // VRAM
    else if(address >= MemoryAddresses.VIDEO_RAM_START && address < MemoryAddresses.VIDEO_RAM_END)
    {
      this.vram[this.vramPageStart + address - MemoryAddresses.VIDEO_RAM_START] = value;
    }
    // Cartridge RAM
    else if(address >= MemoryAddresses.SWITCHABLE_RAM_START && address < MemoryAddresses.SWITCHABLE_RAM_END)
    {
      return;
    }
    // RAM A
    else if(address >= MemoryAddresses.RAM_A_START && address < MemoryAddresses.RAM_A_SWITCHABLE_START)
    {
      this.wram[address - MemoryAddresses.RAM_A_START] = value;
    }
    else if(address >= MemoryAddresses.RAM_A_SWITCHABLE_START && address < MemoryAddresses.RAM_A_END)
    {
      this.wram[address - MemoryAddresses.RAM_A_SWITCHABLE_START + this.wramPageStart] = value;
    }
    // RAM echo
    else if(address >= MemoryAddresses.RAM_A_ECHO_START && address < MemoryAddresses.RAM_A_ECHO_END)
    {
      this.writeByte(address - MemoryAddresses.RAM_A_ECHO_START, value);
    }
    // Empty
    else if(address >= MemoryAddresses.EMPTY_A_START && address < MemoryAddresses.EMPTY_A_END)
    {
      return;
    }
    // OAM
    else if(address >= MemoryAddresses.OAM_START && address < MemoryAddresses.EMPTY_A_END)
    {
      this.oam[address - MemoryAddresses.OAM_START] = value;
    }
    // IO
    else if(address >= MemoryAddresses.IO_START)
    {
      this.writeIO(address - MemoryAddresses.IO_START, value);
    }
  }

  /// Read a byte from memory address
  ///
  /// If the address falls into the cartridge addressing zone read directly from the cartridge object.
  int readByte(int address)
  {
    address &= 0xFFFF;

    // ROM
    if(address < MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START)
    {
      return this.cpu.cartridge.data[address];
    }
    if(address >= MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START && address < MemoryAddresses.CARTRIDGE_ROM_END)
    {
      return this.cpu.cartridge.data[this.romPageStart + address - MemoryAddresses.CARTRIDGE_ROM_SWITCHABLE_START];
    }
    // VRAM
    else if(address >= MemoryAddresses.VIDEO_RAM_START && address < MemoryAddresses.VIDEO_RAM_END)
    {
      return this.vram[this.vramPageStart + address - MemoryAddresses.VIDEO_RAM_START];
    }
    // Cartridge RAM
    else if(address >= MemoryAddresses.SWITCHABLE_RAM_START && address < MemoryAddresses.SWITCHABLE_RAM_END)
    {
      return 0x0;
    }
    // RAM A
    else if(address >= MemoryAddresses.RAM_A_START && address < MemoryAddresses.RAM_A_SWITCHABLE_START)
    {
      return this.wram[address - MemoryAddresses.RAM_A_START];
    }
    else if(address >= MemoryAddresses.RAM_A_SWITCHABLE_START && address < MemoryAddresses.RAM_A_END)
    {
      return this.wram[this.wramPageStart + address - MemoryAddresses.RAM_A_SWITCHABLE_START];
    }
    // RAM echo
    else if(address >= MemoryAddresses.RAM_A_ECHO_START && address < MemoryAddresses.RAM_A_ECHO_END)
    {
      return this.readByte(address - MemoryAddresses.RAM_A_ECHO_START);
    }
    // Empty A
    else if(address >= MemoryAddresses.EMPTY_A_START && address < MemoryAddresses.EMPTY_A_END)
    {
      return 0xFF;
    }
    // OAM
    else if(address >= MemoryAddresses.OAM_START && address < MemoryAddresses.EMPTY_A_END)
    {
      return this.oam[address - MemoryAddresses.OAM_START];
    }
    // IO
    else if(address >= MemoryAddresses.IO_START)
    {
      return this.readIO(address - MemoryAddresses.IO_START);
    }

    throw new Exception('Trying to access invalid address.');
  }

  /// Write data into the IO section of memory space.
  void writeIO(int address, int value)
  {
    value &= 0xFF;
    address &= 0xFFFF;

    switch (address)
    {
      case MemoryRegisters.DOUBLE_SPEED:
        this.cpu.setDoubleSpeed((value & 0x01) != 0);
        break;
      case 0x69:
        {
          if(this.cpu.cartridge.gameboyType == GameboyType.CLASSIC)
          {
            break;
          }

          int data = this.registers[0x68];
          int currentRegister = data & 0x3f;

          this.cpu.ppu.setBackgroundPalette(currentRegister, value);

          if((data & 0x80) != 0)
          {
            currentRegister++;
            currentRegister %= 0x40;
            this.registers[0x68] = (0x80 | currentRegister) & 0xFF;
          }
          break;
        }
      case 0x6B:
        {
          if(this.cpu.cartridge.gameboyType == GameboyType.CLASSIC)
          {
            break;
          }

          int ff6a = this.registers[0x6a];
          int currentRegister = ff6a & 0x3f;
          this.cpu.ppu.setSpritePalette(currentRegister, value);

          if((ff6a & 0x80) != 0)
          {
            currentRegister++;
            currentRegister %= 0x40;
            this.registers[0x6a] = (0x80 | currentRegister) & 0xFF;
          }
          break;
        }
      // Start H-DMA transfer
      case MemoryRegisters.HDMA_LENGTH:
        {
          if(this.cpu.cartridge.gameboyType == GameboyType.CLASSIC)
          {
            //print('Not possible to used H-DMA transfer on GB classic.');
            break;
          }

          // Get the configuration of the H-DMA transfer
          int length = ((value & 0x7f) + 1) * 0x10;
          int source = ((this.registers[0x51] & 0xff) << 8) | (this.registers[0x52] & 0xF0);
          int destination = ((this.registers[0x53] & 0x1f) << 8) | (this.registers[0x54] & 0xF0);

          // H-Blank DMA
          if((value & 0x80) != 0)
          {
            this.dma = new DMA(this, source, destination, length);
            this.registers[MemoryRegisters.HDMA_LENGTH] = (length ~/ 0x10 - 1) & 0xFF;
          }
          else
          {
            if(this.dma != null)
            {
              //print('Terminated DMA from ' + source.toString() + '-' + dest.toString() + ', ' + length.toString() + ' remaining.');
            }

            // General DMA
            for(int i = 0; i < length; i++)
            {
              this.vram[this.vramPageStart + destination + i] = readByte(source + i) & 0xFF;
            }
            this.registers[MemoryRegisters.HDMA_LENGTH] = 0xFF;
          }
          return;
        }
      case MemoryRegisters.VRAM_BANK:
        {
          if(this.cpu.cartridge.gameboyType == GameboyType.COLOR)
          {
            this.vramPageStart = Memory.VRAM_PAGESIZE * (value & 0x3);
          }
          break;
        }
      case MemoryRegisters.WRAM_BANK:
        {
          if(this.cpu.cartridge.gameboyType == GameboyType.COLOR)
          {
            this.wramPageStart = Memory.WRAM_PAGESIZE * max(1, value & 0x7);
          }
          break;
        }
      case MemoryRegisters.NR14:
        if((this.registers[MemoryRegisters.NR14] & 0x80) != 0)
        {
          //this.cpu.sound.channel1.restart();
          value &= 0x7f;
        }
        this.registers[address] = value & 0xFF;
        return;
      case MemoryRegisters.NR10:
      case MemoryRegisters.NR11:
      case MemoryRegisters.NR12:
      case MemoryRegisters.NR13:
        this.registers[address] = value & 0xFF;
        //this.cpu.sound.channel1.update();
        return;
      case MemoryRegisters.NR24:
        if((value & 0x80) != 0)
        {
          //this.cpu.sound.channel2.restart();
          value &= 0x7F;
        }
        this.registers[address] = value & 0xFF;
        return;
      case MemoryRegisters.NR21:
      case MemoryRegisters.NR22:
      case MemoryRegisters.NR23:
        this.registers[address] = value & 0xFF;
        //this.cpu.sound.channel2.update();
        return;
      case MemoryRegisters.NR34:
        if((value & 0x80) != 0)
        {
          //this.cpu.sound.channel3.restart();
          value &= 0x7F;
        }
        this.registers[address] = value & 0xFF;
        return;
      case MemoryRegisters.NR30:
      case MemoryRegisters.NR31:
      case MemoryRegisters.NR32:
      case MemoryRegisters.NR33:
        this.registers[address] = value & 0xFF;
        //this.cpu.sound.channel3.update();
        return;
      case MemoryRegisters.NR44:
        if((value & 0x80) != 0)
        {
          //this.cpu.sound.channel4.restart();
          value &= 0x7F;
        }
        this.registers[address] = value & 0xFF;
        return;
      case MemoryRegisters.NR41:
      case MemoryRegisters.NR42:
      case MemoryRegisters.NR43:
        this.registers[address] = value & 0xFF;
        //this.cpu.sound.channel4.update();
        return;
      case MemoryRegisters.DMA:
        {
          int addressBase = value * 0x100;

          for(int i = 0; i < 0xA0; i++)
          {
            this.writeByte(0xFE00 + i, this.readByte(addressBase + i));
          }
          break;
        }
      case MemoryRegisters.DIV:
        value = 0;
        break;
      case MemoryRegisters.TAC:
        if(((this.registers[MemoryRegisters.TAC] ^ value) & 0x03) != 0)
        {
          this.cpu.timerCycle = 0;
          this.registers[MemoryRegisters.TIMA] = this.registers[MemoryRegisters.TMA];
        }
        break;
      case MemoryRegisters.SERIAL_SC:
        // Print serial data as characters to the terminal
        if(Configuration.printSerialCharacters)
        {
          if(value & 0xFF == 0x81)
          {
            print(String.fromCharCode(this.registers[MemoryRegisters.SERIAL_SB]));
          }
        }
        break;
      case MemoryRegisters.LCD_STAT:
        break;
      default:
        if(0x30 <= address && address < 0x40)
        {
          //this.cpu.sound.channel3.updateSample(address - 0x30, (byte) value);
        }
    }

    this.registers[address] = value & 0xFF;
  }

  /// Read IO address
  int readIO(int address)
  {
    if(address == MemoryRegisters.DOUBLE_SPEED)
    {
      return this.cpu.doubleSpeed ? 0x80 : 0x0;
    }
    else if(address == MemoryRegisters.GAMEPAD)
    {
      int reg = this.registers[MemoryRegisters.GAMEPAD];
      reg |= 0x0F;

      if(reg & 0x10 == 0)
      {
        if(this.cpu.buttons[Gamepad.RIGHT]){reg &= ~0x1;}
        if(this.cpu.buttons[Gamepad.LEFT]){reg &= ~0x2;}
        if(this.cpu.buttons[Gamepad.UP]){reg &= ~0x4;}
        if(this.cpu.buttons[Gamepad.DOWN]){reg &= ~0x8;}
      }

      if(reg & 0x20 == 0)
      {
        if(this.cpu.buttons[Gamepad.A]){reg &= ~0x1;}
        if(this.cpu.buttons[Gamepad.B]){reg &= ~0x2;}
        if(this.cpu.buttons[Gamepad.SELECT]){reg &= ~0x4;}
        if(this.cpu.buttons[Gamepad.START]){reg &= ~0x8;}
      }

      return reg;
    }
    else if(address == MemoryRegisters.NR52)
    {
      int reg = this.registers[MemoryRegisters.NR52] & 0x80;
      //TODO <ADD CODE HERE>
      //if(this.cpu.sound.channel1.isPlaying) reg |= 0x01;
      //if(this.cpu.sound.channel2.isPlaying) reg |= 0x02;
      //if(this.cpu.sound.channel3.isPlaying) reg |= 0x04;
      //if(this.cpu.sound.channel4.isPlaying) reg |= 0x08;

      return reg;
    }

    return this.registers[address];
  }
}
