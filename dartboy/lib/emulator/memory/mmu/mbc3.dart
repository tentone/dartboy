import 'dart:math';

import '../../cpu/cpu.dart';
import '../cartridge.dart';
import '../memory.dart';
import 'mbc.dart';

class MBC3 extends MBC
{
  /// The currently selected RAM bank.
  int ramBank;

  /// Whether the realtime clock is enabled for IO.
  bool rtcEnabled;

  /// The realtime clock registers.
  List<int> rtc = new List<int>(4);

  MBC3(CPU cpu, Cartridge cartridge) : super(cpu, cartridge)
  {
    this.cartRam = new List<int>(MBC.RAM_PAGESIZE * 4);
  }

  void writeByte(int address, int _data)
  {
    address &= 0xffff;
    int data = _data & 0xff;

    switch (address & 0xF000)
    {
      case 0x0000:
      case 0x1000:
        if(this.cpu.cartridge.ramBanks != 0)
        {
          this.ramEnabled = (data & 0x0F) == 0x0A;
        }

        this.rtcEnabled = (data & 0x0F) == 0x0A;
        break;
      case 0x2000:
      case 0x3000:
        // Same as for MBC1, except that the whole 7 bits of the RAM Bank Number are written directly to this address.
        this.romPageStart = Memory.ROM_PAGESIZE * max(data & 0x7F, 1);
        break;
      case 0x4000:
      case 0x5000:
        // As for the MBC1s RAM Banking Mode, writing a value in range for 00h-03h maps the corresponding external RAM Bank (if any) into memory at A000-BFFF.
        // When writing a value of 08h-0Ch, this will map the corresponding RTC register into memory at A000-BFFF.
        // That register could then be read/written by accessing any address in that area, typically that is done by using address A000.

        if ((data >= 0x08) && (data <= 0x0C))
        {
          // RTC
          if(this.rtcEnabled)
          {
            // TODO <RTC WRITE>
            this.ramBank = -1;
          }
        }
        else if(data <= 0x03)
        {
          this.ramBank = data;
          this.ramPageStart = this.ramBank * MBC.RAM_PAGESIZE;
        }
        break;
      case 0xA000:
      case 0xB000:
        //Depending on the current Bank Number/RTC Register selection (see above), this memory space is used to access an 8KByte external RAM Bank, or a single RTC Register.
        if(this.ramEnabled && this.ramBank >= 0)
        {
          this.cartRam[address - 0xA000 + ramPageStart] = data;
        }
        else if(this.rtcEnabled)
        {
          // TODO <RTC READ>
          //  rtc[ramBank - 0x08] = data;
          // System.err.println("Write to RTC not implemented yet");
        }
        break;
      default:
        super.writeByte(address, _data);
        break;
    }
  }
}
