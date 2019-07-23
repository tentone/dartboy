import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../emulator/memory/gamepad.dart';
import '../emulator/emulator.dart';
import './lcd.dart';
import './button.dart';
import './Modal.dart';

class MainScreen extends StatefulWidget
{
  MainScreen({Key key, this.title}) : super(key: key);

  final String title;

  /// Emulator instance
  static Emulator emulator = new Emulator();

  static LCDState lcdState = new LCDState();

  static bool keyboardHandlerCreated = false;
  @override
  MainScreenState createState()
  {
    return new MainScreenState();
  }
}

class MainScreenState extends State<MainScreen>
{
  static const int KEY_I = 73;
  static const int KEY_O = 79;
  static const int KEY_P = 80;

  static Map<int, int> keyMapping =
  {
    // Left arrow
    263: Gamepad.LEFT,
    // Right arrow
    262: Gamepad.RIGHT,
    // Up arrow
    265 : Gamepad.UP,
    // Down arrow
    264: Gamepad.DOWN,
    // Z
    90: Gamepad.A,
    // X
    88: Gamepad.B,
    // Enter
    257: Gamepad.START,
    // C
    67: Gamepad.SELECT
  };

  @override
  Widget build(BuildContext context)
  {
    if(!MainScreen.keyboardHandlerCreated)
    {
      MainScreen.keyboardHandlerCreated = true;

      RawKeyboard.instance.addListener((RawKeyEvent key)
      {
        // Get the keyCode from the object string description (keyCode does not seem to be exposed other way)
        String keyPress = key.data.toString();

        String value = keyPress.substring(keyPress.indexOf('keyCode: ') + 9, keyPress.indexOf(', scanCode:'));
        if(value.length == 0)
        {
          return;
        }

        int keyCode = int.parse(value);

        // Debug functions
        if(key is RawKeyDownEvent)
        {
          if(keyCode == KEY_I)
          {
            print('Toogle background layer.');
            MainScreen.emulator.cpu.ppu.debugBackgroundEnabled = !MainScreen.emulator.cpu.ppu.debugBackgroundEnabled;
          }
          else if(keyCode == KEY_O)
          {
            print('Toogle sprite layer.');
            MainScreen.emulator.cpu.ppu.debugSpritesEnabled = !MainScreen.emulator.cpu.ppu.debugSpritesEnabled;
          }
        }

        if(!keyMapping.containsKey(keyCode))
        {
          return;
        }

        if(key is RawKeyUpEvent)
        {
          MainScreen.emulator.buttonUp(keyMapping[keyCode]);
        }
        else if(key is RawKeyDownEvent)
        {
          MainScreen.emulator.buttonDown(keyMapping[keyCode]);
        }
      });
    }


    return new Scaffold
    (
      backgroundColor: Colors.black,
      body: new Container
      (
        child: new Column
        (
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>
          [
            // LCD
            new Expanded(child: new LCDWidget()),
            new Expanded(child: new Column
            (
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>
              [
                // Buttons (DPAD + AB)
                new Row
                (
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>
                  [
                    // DPAD
                    new Column
                    (
                      children: <Widget>
                      [
                        new Button(color: Colors.blueAccent, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.UP);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.UP);}, label: "Up"),
                        new Row
                        (
                          children: <Widget>
                          [
                            new Button(color: Colors.blueAccent, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.LEFT);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.LEFT);}, label: "Left"),
                            new Container(width: 50, height: 50),
                            new Button(color: Colors.blueAccent, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.RIGHT);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.RIGHT);}, label: "Right")
                          ]
                        ),
                        new Button(color: Colors.blueAccent, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.DOWN);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.DOWN);}, label: "Down"),
                      ],
                    ),
                    // AB
                    new Column
                    (
                      children: <Widget>
                      [
                        new Button(color: Colors.red, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.A);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.A);}, label: "A"),
                        new Button(color: Colors.green, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.B);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.B);}, label: "B"),
                      ],
                    ),
                  ],
                ),
                // Button (SELECT + START)
                new Row
                (
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>
                  [
                    new Button(color: Colors.orange, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.START);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.START);}, labelColor: Colors.black, label: "Start"),
                    new Container(width: 20),
                    new Button(color: Colors.yellowAccent, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.SELECT);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.SELECT);}, labelColor: Colors.black, label: "Select"),
                  ],
                ),
                // Button (Start + Pause + Load)
                new Expanded(child: new ListView
                (
                  padding: const EdgeInsets.only(left:10.0, right: 10.0),
                  scrollDirection: Axis.horizontal,
                  children: <Widget>
                  [
                    new RaisedButton(onPressed: ()
                    {
                      if(MainScreen.emulator.state != EmulatorState.READY)
                      {
                        Modal.alert(context, 'Error', 'Not ready to run. Load ROM first.');
                        return;
                      }
                      MainScreen.emulator.run();
                    }, color: Colors.black, child: new Text("Run", style: const TextStyle(color: Colors.white))),
                    new RaisedButton(onPressed: ()
                    {
                      if(MainScreen.emulator.state != EmulatorState.RUNNING)
                      {
                        Modal.alert(context, 'Error', 'Not running cant be paused.');
                        return;
                      }

                      MainScreen.emulator.pause();
                    }, color: Colors.black, child: new Text("Pause", style: const TextStyle(color: Colors.white))),
                    new RaisedButton(onPressed: ()
                    {
                      MainScreen.emulator.reset();
                    }, color: Colors.black, child: new Text("Reset", style: const TextStyle(color: Colors.white))),
                    (!Platform.isAndroid && !Platform.isIOS) ? new RaisedButton(onPressed: ()
                    {
                      MainScreen.emulator.debugStep();
                    }, color: Colors.black, child: new Text('Step', style: const TextStyle(color: Colors.white))) : new Container(width: 0.0),
                    (!Platform.isAndroid && !Platform.isIOS) ? new RaisedButton(onPressed: ()
                    {
                      for(int i = 0; i < 100; i++)
                      {
                        MainScreen.emulator.debugStep();
                      }
                    }, color: Colors.black, child: new Text('Step 100x', style: const TextStyle(color: Colors.white))) : new Container(width: 0.0),
                    new RaisedButton(onPressed: ()
                    {
                      if(MainScreen.emulator.state != EmulatorState.WAITING)
                      {
                        Modal.alert(context, 'Error', 'There is a ROM already loaded. Reset before loading new ROM.');
                        return;
                      }

                      if(Platform.isAndroid || Platform.isIOS)
                      {
                        FilePicker.getFile(fileExtension: 'gb').then((File file)
                        {
                          MainScreen.emulator.loadROM(file);
                        });
                      }
                      else
                      {
                        MainScreen.emulator.loadROM(new File('./roms/tetris.gb'));
                      }

                      if(MainScreen.emulator.state == EmulatorState.READY)
                      {
                        Modal.alert(context, 'Success', 'ROM loaded, ready to play.');
                      }

                    }, color: Colors.black, child: new Text("Load", style: const TextStyle(color: Colors.white))),
                  ],
                ))
              ]
            )
          )
          ]
        )
      )
    );
  }
}
