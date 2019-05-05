import 'dart:io';

import 'cpu/cpu.dart';
import 'cartridge.dart';

/// Main emulator object used to directly interact with the system.
///
/// GUI communicates with this object, it is responsible for providing image, handling key input and user interaction.
class Emulator
{
  CPU cpu;
  Cartridge cartridge;

  /// Load a ROM from a file and create the HW components for the emulator.
  void loadROM(String fname)
  {
    File rom = new File(fname);
    List<int> data = rom.readAsBytesSync();

    this.cartridge = new Cartridge();
    this.cartridge.load(data);

    this.cpu = new CPU(this.cartridge);

    printCartridgeInfo();
  }

  void printCartridgeInfo()
  {
    print('Catridge info');
    print('Type: ' + this.cpu.memory.cartridge.type.toString());
    print('Name: ' + this.cpu.memory.cartridge.name);
    print('GB: ' + this.cpu.memory.cartridge.gameboyType.toString());
    print('SGB: ' + this.cpu.memory.cartridge.superGameboy.toString());
  }

  void start()
  {
    if(this.cpu != null)
    {
      //TODO <ADD CODE HERE>
    }
  }

  void step()
  {
    //TODO <ADD CODE HERE>
  }
}