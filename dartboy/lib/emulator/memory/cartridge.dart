import 'dart:math';

import '../cpu/cpu.dart';
import './mmu/mmu.dart';
import './mmu/mbc1.dart';
import './mmu/mbc2.dart';
import './mmu/mbc3.dart';
import './mmu/mbc5.dart';

/// Stores the cartridge information and data.
///
/// Also manages the cartridge type and is responsible for the memory bank switching.
class Cartridge
{
  /// Data stored in the cartridge (directly loaded from a ROM file).
  List<int> data;

  /// Size of the memory in bytes
  int size;

  /// Cartridge name read from the
  String name;

  /// Cartridge type, there are 16 different types.
  ///
  /// Read from memory address 0x147 (Check page 11 of the GB CPU manual for details)
  int type;

  /// In cartridge ROM configuration. Read from the address 0x148.
  ///
  /// (Check page 12 of the GB CPU manual for details)
  int romType;

  /// Indicates how many rom banks there are available.
  ///
  /// Each ROM bank has 32KB in size
  int romBanks;

  /// In cartridge RAM configuration. Read from the address 0x149.
  ///
  /// (Check page 12 of the GB CPU manual for details)
  int ramType;

  /// Indicates how many RAM banks are available in the cartridge.
  ///
  /// Each bank has 8KBytes in size.
  int ramBanks;

  /// Cartridge checksum, used to check if the data of the game is good, and also used to select the better color palette in classic gb games.
  int checksum;

  /// In CGB cartridges the upper bit is used to enable CGB functions. This is required, otherwise the CGB switches itself into Non-CGB-Mode.
  ///
  /// There are two different CGB modes 80h Game supports CGB functions, but works on old gameboys also, C0h Game works on CGB only.
  GameboyType gameboyType;

  /// SGB mode indicates if the game has super gameboy features
  bool superGameboy;

  Cartridge();

  /// Load cartridge byte data
  void load(List<int> data)
  {
    this.size = data.length;
    this.data = data;

    this.type = this.readByte(0x147);
    this.name = String.fromCharCodes(this.readBytes(0x134, 0x142));
    this.romType = this.readByte(0x148);
    this.ramType = this.readByte(0x149);
    this.gameboyType = this.readByte(0x143) != 0 ? GameboyType.COLOR : GameboyType.CLASSIC;
    this.superGameboy = this.readByte(0x146) == 0x3;

    // Calculate the special value used by the CGB boot ROM to colorize some monochrome games.
    int chk = 0;
    for(int i = 0; i < 16; i++)
    {
      chk += this.data[0x134 + i];
    }
    this.checksum = chk & 0xFF;

    this.setBankSizeRAM();
    this.setBankSizeROM();
  }

  /// Create a the memory controller of the cartridge.
  MMU createController(CPU cpu)
  {
    if(this.type == CartridgeType.ROM)
    {
      print('Created basic MMU unit.');
      return new MMU(cpu, this);
    }
    else if(this.type == CartridgeType.MBC1 || this.type == CartridgeType.MBC1_RAM || this.type == CartridgeType.MBC1_RAM_BATT)
    {
      print('Created MBC1 unit.');
      return new MBC1(cpu, this);
    }
    else if(this.type == CartridgeType.MBC2 || this.type == CartridgeType.MBC2_BATT)
    {
      print('Created MBC2 unit.');
      return new MBC2(cpu, this);
    }
    else if(this.type == CartridgeType.MBC3 || this.type == CartridgeType.MBC3_RAM || this.type == CartridgeType.MBC3_RAM_BATT || this.type == CartridgeType.MBC3_TIMER_BATT || this.type == CartridgeType.MBC3_TIMER_RAM_BATT)
    {
      print('Created MBC3 unit.');
      return new MBC3(cpu, this);
    }
    else if(this.type == CartridgeType.MBC5 || this.type == CartridgeType.MBC5_RAM || this.type == CartridgeType.MBC5_RAM_BATT || this.type == CartridgeType.MBC5_RUMBLE || this.type == CartridgeType.MBC5_RUMBLE_SRAM || this.type == CartridgeType.MBC5_RUMBLE_SRAM_BATT)
    {
      print('Created MBC5 unit.');
      return new MBC5(cpu, this);
    }

    return null;
  }

  /// Checks if the cartridge has battery.
  bool hasBattery()
  {
    return this.type == CartridgeType.ROM_RAM_BATT || this.type == CartridgeType.ROM_MMM01_SRAM_BATT || this.type == CartridgeType.MBC1_RAM_BATT || this.type == CartridgeType.MBC3_TIMER_BATT || this.type == CartridgeType.MBC3_TIMER_RAM_BATT || this.type == CartridgeType.MBC3_RAM_BATT || this.type == CartridgeType.MBC5_RAM_BATT || this.type == CartridgeType.MBC5_RUMBLE_SRAM_BATT;
  }

  /// Set how many ROM banks exist based on the ROM type.
  void setBankSizeROM()
  {
    if (this.romType == 52)
    {
      this.romBanks = 72;
    }
    else if (this.romType == 53)
    {
      this.romBanks = 80;
    }
    else if (this.romType == 54)
    {
      this.romBanks = 96;
    }
    else
    {
      this.romBanks = (pow(2, this.romType + 1)).toInt();
    }
  }

  /// Set how many RAM banks exist in the cartridge based on the RAM type.
  void setBankSizeRAM()
  {
    if(this.ramType == 0)
    {
      this.ramBanks = 0;
    }
    else if(this.ramType == 1)
    {
      this.ramBanks = 1;
    }
    else if(this.ramType == 2)
    {
      this.ramBanks = 1;
    }
    else if(this.ramType == 3)
    {
      this.ramBanks = 4;
    }
    else if(this.ramType == 4)
    {
      this.ramBanks = 16;
    }
  }

  /// Read a range of bytes from the cartridge.
  List<int> readBytes(int initialAddress, int finalAddress)
  {
    return this.data.sublist(initialAddress, finalAddress);
  }

  /// Read a single byte from cartridge
  int readByte(int address)
  {
    return this.data[address] & 0xFF;
  }
}

/// Enum to indicate the gameboy type present in the cartridge.
enum GameboyType
{
  CLASSIC, COLOR
}

/// List of all cartridge types available in the game boy.
///
/// Cartridges have different memory configurations.
class CartridgeType
{
  static const int ROM = 0x00;
  static const int ROM_RAM = 0x08;
  static const int ROM_RAM_BATT = 0x09;
  static const int ROM_MMM01 = 0x0B;
  static const int ROM_MMM01_SRAM = 0x0C;
  static const int ROM_MMM01_SRAM_BATT = 0x0D;

  static const int MBC1 = 0x01;
  static const int MBC1_RAM = 0x02;
  static const int MBC1_RAM_BATT = 0x03;

  static const int MBC2 = 0x05;
  static const int MBC2_BATT = 0x06;

  static const int MBC3_TIMER_BATT = 0x0F;
  static const int MBC3_TIMER_RAM_BATT = 0x10;
  static const int MBC3 = 0x11;
  static const int MBC3_RAM = 0x12;
  static const int MBC3_RAM_BATT = 0x13;

  static const int MBC5 = 0x19;
  static const int MBC5_RAM = 0x1A;
  static const int MBC5_RAM_BATT = 0x1B;
  static const int MBC5_RUMBLE = 0x1C;
  static const int MBC5_RUMBLE_SRAM = 0x1D;
  static const int MBC5_RUMBLE_SRAM_BATT = 0x1E;

  static const int POCKETCAM = 0x1F;
  static const int BANDAI_TAMA5 = 0xFD;
  static const int HUDSON_HUC3 = 0xFE;
  static const int HUDSON_HUC1 = 0xFF;
}