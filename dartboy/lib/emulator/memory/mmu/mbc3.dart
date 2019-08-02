import 'dart:math';
import 'dart:typed_data';

import '../../cpu/cpu.dart';
import '../memory.dart';
import '../memory_addresses.dart';
import 'mbc.dart';
import 'mbc1.dart';

class MBC3 extends MBC
{
  /// The currently selected RAM bank.
  int ramBank;

  /// Whether the real time clock is enabled for IO.
  bool rtcEnabled;

  /// The real time clock registers.
  Uint8List rtc;

  MBC3(CPU cpu) : super(cpu);

  @override
  void reset()
  {
    super.reset();

    this.rtcEnabled = false;
    this.ramBank = 0;

    this.rtc = new Uint8List(4);
    this.rtc.fillRange(0, this.rtc.length, 0);

    this.cartRam = new Uint8List(MBC.RAM_PAGESIZE * 4);
    this.cartRam.fillRange(0, this.cartRam.length, 0);
  }

  @override
  void writeByte(int address, int value)
  {
    address &= 0xFFFF;

    if(address >= MBC1.RAM_DISABLE_START && address < MBC1.RAM_DISABLE_END)
    {
      if(this.cpu.cartridge.ramBanks > 0)
      {
        this.ramEnabled = (value & 0x0F) == 0x0A;
      }

      this.rtcEnabled = (value & 0x0F) == 0x0A;
    }
    // Same as for MBC1, except that the whole 7 bits of the RAM Bank Number are written directly to this address.
    else if(address >= MBC1.ROM_BANK_SELECT_START && address < MBC1.ROM_BANK_SELECT_END)
    {
      this.romPageStart = Memory.ROM_PAGESIZE * max(value & 0x7F, 1);
    }
    // As for the MBC1s RAM Banking Mode, writing a value in range for 00h-03h maps the corresponding external RAM Bank (if any) into memory at A000-BFFF.
    // When writing a value of 08h-0Ch, this will map the corresponding RTC register into memory at A000-BFFF.
    // That register could then be read/written by accessing any address in that area, typically that is done by using address A000.
    else if(address >= 0x4000 && address < 0x6000)
    {
      // TODO <RTC WRITE>
      if(value >= 0x08 && value <= 0x0C)
      {
        if(this.rtcEnabled)
        {
          this.ramBank = -1;
        }
      }
      else if(value <= 0x03)
      {
        this.ramBank = value;
        this.ramPageStart = this.ramBank * MBC.RAM_PAGESIZE;
      }
    }
    //Depending on the current Bank Number/RTC Register selection this memory space is used to access an 8KByte external RAM Bank, or a single RTC Register.
    else if(address >= MemoryAddresses.SWITCHABLE_RAM_START && address < MemoryAddresses.SWITCHABLE_RAM_END)
    {
      if(this.ramEnabled && this.ramBank >= 0)
      {
        this.cartRam[address - MemoryAddresses.SWITCHABLE_RAM_START + this.ramPageStart] = value;
      }
      else if(this.rtcEnabled)
      {
        // TODO <ADD CODE HERE TO WRITE RTC>
        //this.rtc[this.ramBank - 0x08] = value;
      }
    }
    else
    {
      super.writeByte(address, value);
    }
  }
}
