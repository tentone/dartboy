import 'dart:async';
import 'dart:io';

import './cpu/cpu.dart';
import './memory/cartridge.dart';
import './memory/memory_registers.dart';

enum EmulatorState
{
  WAITING,
  READY,
  RUNNING
}

/// Main emulator object used to directly interact with the system.
///
/// GUI communicates with this object, it is responsible for providing image, handling key input and user interaction.
class Emulator
{
  /// State of the emulator, indicates if there is data loaded, and the emulation state.
  EmulatorState state;

  /// CPU object
  CPU cpu;

  /// Callback function called on the end of each emulator step.
  Function onStep;

  /// Timer used to step the CPU.
  Timer timer;

  Emulator({Function onStep})
  {
    this.cpu = null;

    this.state = EmulatorState.WAITING;
    this.onStep = onStep;
  }

  /// Press a gamepad button down (update memory register).
  void buttonDown(int button)
  {
    this.cpu.mmu.registers[MemoryRegisters.R_JOYPAD] |= (button & 0xFF);
  }

  /// Release a gamepad button (update memory register).
  void buttonUp(int button)
  {
    this.cpu.mmu.registers[MemoryRegisters.R_JOYPAD] &= (~button & 0xFF);
  }

  /// Load a ROM from a file and create the HW components for the emulator.
  void loadROM(File file)
  {
    if(this.state != EmulatorState.WAITING)
    {
      //TODO <DEBUG PRINT>
      print('Emulator should be reset to load ROM.');
      return;
    }

    List<int> data = file.readAsBytesSync();

    Cartridge cartridge = new Cartridge();
    cartridge.load(data);

    this.cpu = new CPU(cartridge);

    this.state = EmulatorState.READY;

    this.printCartridgeInfo();
  }

  /// Print some information about the ROM file loaded into the emulator.
  void printCartridgeInfo()
  {
    print('Catridge info');
    print('Type: ' + this.cpu.cartridge.type.toString());
    print('Name: ' + this.cpu.cartridge.name);
    print('GB: ' + this.cpu.cartridge.gameboyType.toString());
    print('SGB: ' + this.cpu.cartridge.superGameboy.toString());
  }

  /// Reset the emulator, stop running the code and unload the cartridge
  void reset()
  {
    this.cpu = null;
    this.state = EmulatorState.WAITING;
  }

  /// Run the emulation
  void run()
  {
    if(this.state != EmulatorState.READY)
    {
      //TODO <DEBUG PRINT>
      print('Emulator not ready, cannot run.');
      return;
    }

    this.state = EmulatorState.RUNNING;

    int step = 0;
    this.timer = new Timer.periodic(const Duration(microseconds: 1), (Timer t)
    {
      step++;

      if(this.state != EmulatorState.RUNNING)
      {
        //TODO <DEBUG PRINT>
        print('Stopped emulation (Step: ' + step.toString() + ')');
        this.timer.cancel();
        return;
      }

      //Step CPU
      try
      {
        this.cpu.step();

        if(this.onStep != null)
        {
          this.onStep();
        }
      }
      catch(e, stacktrace)
      {
        //TODO <DEBUG PRINT>
        print('Error occured, emulation stoped. (Step: ' + step.toString() + ')');
        print(e.toString());
        print(stacktrace.toString());
        this.timer.cancel();
      }
    });
  }

  /// Pause the emulation
  void pause()
  {
    if(this.state != EmulatorState.RUNNING)
    {
      //TODO <DEBUG PRINT>
      print('Emulator not running cannot be paused');
      return;
    }

    this.timer.cancel();
    this.state = EmulatorState.READY;
  }
}