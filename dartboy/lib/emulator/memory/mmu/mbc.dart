import 'dart:io';

import '../../cpu/cpu.dart';
import '../cartridge.dart';
import 'mmu.dart';

/// Abstract implementation of features shared by all Memory Banking Chips.
class MBC extends MMU
{
  /// The size of a page of cart RAM, 8k in size.
  static const int RAM_PAGESIZE = 0x2000;

  /// The current offset (page) into cart ram.
  int ramPageStart;

  /// Whether or not accessing RAM is currently enabled.
  bool ramEnabled;

  /// Raw cart ram.
  List<int> cartRam;

  MBC(CPU cpu, Cartridge cartridge) : super(cpu, cartridge);

  /// Load the state of the internal RAM of the cartridge from file.
  void load(File file)
  {
    if(!this.cpu.cartridge.hasBattery())
    {
      throw new Exception('Cartridge has no battery.');
    }

    int length = this.cartRam.length;

    this.cartRam = file.readAsBytesSync();

    if(length != this.cartRam.length)
    {
      throw new Exception('Loaded invalid cartridge RAM file.');
    }
  }

  /// Save the state of the internal RAM of the cartridge to file.
  void save(File file)
  {
    if(!this.cpu.cartridge.hasBattery())
    {
      throw new Exception('Cartridge has no battery.');
    }
    
    file.writeAsBytes(this.cartRam, flush: true, mode: FileMode.write);
  }

  @override
  int readByte(int address)
  {
    address &= 0xffff;

    switch (address & 0xF000)
    {
      case 0xA000:
      case 0xB000:
        if(this.ramEnabled)
        {
          return this.cartRam[address - 0xA000 + this.ramPageStart];
        }
        // Return an invalid value
        else
        {
          return 0xFF;
        }
        break;
    }

    return super.readByte(address);
  }
}