import 'dart:io';

import 'package:flutter/material.dart';

import '../emulator/memory/gamepad.dart';
import '../emulator/emulator.dart';
import './lcd.dart';
import './button.dart';

class MainScreen extends StatefulWidget
{
  MainScreen({Key key, this.title}) : super(key: key);

  final String title;

  /// Emulator instance
  static Emulator emulator = new Emulator();

  @override
  MainScreenState createState()
  {
    return new MainScreenState();
  }
}

class MainScreenState extends State<MainScreen>
{
  @override
  Widget build(BuildContext context)
  {
    return new Scaffold
    (
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
                    new Button(color: Colors.orange, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.START);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.START);}, label: "Start"),
                    new Container(width: 20),
                    new Button(color: Colors.yellowAccent, onPressed: (){MainScreen.emulator.buttonDown(Gamepad.SELECT);}, onReleased: (){MainScreen.emulator.buttonUp(Gamepad.SELECT);}, label: "Select"),
                  ],
                ),
                // Button (Start + Pause + Load)
                new Expanded(child: new Row
                (
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>
                  [
                    new RaisedButton(onPressed: ()
                    {
                      MainScreen.emulator.run();
                    }, child: new Text("Run")),
                    new RaisedButton(onPressed: ()
                    {
                      MainScreen.emulator.pause();
                    }, child: new Text("Pause")),
                    new RaisedButton(onPressed: ()
                    {
                      MainScreen.emulator.reset();
                    }, child: new Text("Reset")),
                    new RaisedButton(onPressed: ()
                    {
                      MainScreen.emulator.loadROM(new File('./roms/pokemon.gb'));
                    }, child: new Text("Load"))
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
