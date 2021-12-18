import 'package:flutter/material.dart';

import 'gui/main_screen.dart';

void main()
{
  runApp(DartBoy());
}

class DartBoy extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return new MaterialApp
    (
      title: 'GBC',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new MainScreen(title: 'GBC'),
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      debugShowMaterialGrid: false
    );
  }
}
