import 'dart:async';
import 'dart:io';

import './cpu/cpu.dart';
import './memory/cartridge.dart';

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

  Emulator({Function onStep})
  {
    this.cpu = null;

    this.state = EmulatorState.WAITING;
    this.onStep = onStep;
  }

  /// Press a gamepad button down (update memory register).
  void buttonDown(int button)
  {
    this.cpu.buttons[button] = true;
  }

  /// Release a gamepad button (update memory register).
  void buttonUp(int button)
  {
    this.cpu.buttons[button] = false;
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
      print('Emulator not ready, cannot run.');
      return;
    }

    this.state = EmulatorState.RUNNING;

    Function loop = () async
    {
      while(true)
      {
        if(this.state != EmulatorState.RUNNING)
        {
          print('Stopped emulation.');
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
          print('Error occured, emulation stoped.');
          print(e.toString());
          print(stacktrace.toString());
          return;
        }

        await Future.delayed(const Duration(microseconds: 1));
      }
    };
    loop();
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

    this.state = EmulatorState.READY;
  }
}