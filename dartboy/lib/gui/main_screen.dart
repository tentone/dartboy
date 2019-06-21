import 'dart:io';

import 'package:flutter/material.dart';

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
                        new Button(color: Colors.blueAccent, onPressed: (){}, onReleased: (){}, label: "Up"),
                        new Row
                        (
                          children: <Widget>
                          [
                            new Button(color: Colors.blueAccent, onPressed: (){}, onReleased: (){}, label: "Left"),
                            new Container(width: 50, height: 50),
                            new Button(color: Colors.blueAccent, onPressed: (){}, onReleased: (){}, label: "Right")
                          ]
                        ),
                        new Button(color: Colors.blueAccent, onPressed: (){}, onReleased: (){}, label: "Down"),
                      ],
                    ),
                    // AB
                    new Column
                    (
                      children: <Widget>
                      [
                        new Button(color: Colors.red, onPressed: (){}, onReleased: (){}, label: "A"),
                        new Button(color: Colors.green, onPressed: (){}, onReleased: (){}, label: "B"),
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
                    new Button(color: Colors.orange, onPressed: (){}, onReleased: (){}, label: "Start"),
                    new Container(width: 20),
                    new Button(color: Colors.yellowAccent, onPressed: (){}, onReleased: (){}, label: "Select"),
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
                      MainScreen.emulator.loadROM(new File('./roms/cpu_instrs.gb'));
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
