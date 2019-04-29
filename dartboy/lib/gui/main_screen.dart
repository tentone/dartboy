import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget
{
  MainScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  MainScreenState createState()
  {
    return new MainScreenState();
  }
}

class MainScreenState extends State<MainScreen>
{
  int counter = 0;

  void incrementCounter()
  {
    this.counter++;
    setState((){});
  }

  @override
  Widget build(BuildContext context)
  {
    return new Scaffold
    (
      appBar: new AppBar
      (
        title: new Text('Game Boy Emulator'),
      ),
      body: new Center
      (
        child: new Column
        (
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>
          [
            new Text(counter.toString()),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ),
    );
  }
}
