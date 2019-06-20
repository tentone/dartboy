import 'dart:io';

import 'package:flutter/material.dart';

import '../emulator/emulator.dart';
import 'package:dartboy/gui/lcd_widget.dart';

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
    RoundedRectangleBorder shape = new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0));

    CircleBorder circleShape = new CircleBorder();

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
                        new RaisedButton(color: Colors.blueAccent, shape: shape, onPressed: (){print("UP");}, child: new Text("Up")),
                        new Row
                        (
                          children: <Widget>
                          [
                            new RaisedButton(color: Colors.blueAccent, shape: shape, onPressed: (){}, child: new Text("Left")),
                            new RaisedButton(color: Colors.blueAccent, shape: shape, onPressed: (){}, child: new Text("Right"))
                          ]
                        ),
                        new RaisedButton(color: Colors.blueAccent, shape: shape, onPressed: (){}, child: new Text("Down"))
                      ],
                    ),
                    // AB
                    new Column
                    (
                      children: <Widget>
                      [
                        new RaisedButton(color: Colors.red, shape: circleShape, onPressed: (){}, child: new Text("A")),
                        new RaisedButton(color: Colors.green, shape: circleShape, onPressed: (){}, child: new Text("B"))
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
                    new RaisedButton(color: Colors.orange, shape: shape, onPressed: (){}, child: new Text("Start")),
                    new RaisedButton(color: Colors.yellowAccent, shape: shape, onPressed: (){}, child: new Text("Select"))
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
