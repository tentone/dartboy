import 'dart:io';

import 'package:flutter/material.dart';

import '../emulator/emulator.dart';
import 'lcd_painter.dart';

class MainScreen extends StatefulWidget
{
  MainScreen({Key key, this.title}) : super(key: key);

  final String title;

  /// Emulator instance
  Emulator emulator = new Emulator();

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
            new Expanded(child: new CustomPaint
            (
              painter: new LCDPainter(),
            )),
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
                        new FlatButton(onPressed: null, child: new Text("Up")),
                        new Row
                        (
                          children: <Widget>
                          [
                            new FlatButton(onPressed: null, child: new Text("Left")),
                            new FlatButton(onPressed: null, child: new Text("Right"))
                          ]
                        ),
                        new FlatButton(onPressed: null, child: new Text("Down"))
                      ],
                    ),
                    // AB
                    new Column
                    (
                      children: <Widget>
                      [
                        new FlatButton(onPressed: null, child: new Text("A")),
                        new FlatButton(onPressed: null, child: new Text("B"))
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
                    new FlatButton(onPressed: null, child: new Text("Start")),
                    new FlatButton(onPressed: null, child: new Text("Select"))
                  ],
                ),
                // Button (Start + Pause + Load)
                new Expanded(child: new Row
                (
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>
                  [
                    new FlatButton(onPressed: ()
                    {
                      this.widget.emulator.run();
                    }, child: new Text("Run")),
                    new FlatButton(onPressed: ()
                    {
                      this.widget.emulator.pause();
                    }, child: new Text("Pause")),
                    new FlatButton(onPressed: ()
                    {
                      this.widget.emulator.reset();
                    }, child: new Text("Reset")),
                    new FlatButton(onPressed: ()
                    {
                      this.widget.emulator.loadROM(new File('./roms/cpu_instrs.gb'));
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
