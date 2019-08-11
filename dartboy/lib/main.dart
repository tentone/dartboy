import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'emulator/cpu/registers.dart';
import 'gui/main_screen.dart';

void main()
{
  runApp(DartBoy());
}

class DartBoy extends StatelessWidget
{
  /// Override the target platform is running on desktop.
  void overrideTargetPlatformForDesktop()
  {
    TargetPlatform targetPlatform;

    if(Platform.isMacOS)
    {
      targetPlatform = TargetPlatform.iOS;
    }
    else if(Platform.isLinux || Platform.isWindows)
    {
      targetPlatform = TargetPlatform.android;
    }

    if(targetPlatform != null)
    {
      debugDefaultTargetPlatformOverride = targetPlatform;
    }
  }

  @override
  Widget build(BuildContext context)
  {
    // TODO <Test Code>
    Registers registers = new Registers(null);

    List<int> list = [ -120, 127, 300, -300];
    for(int i = 0; i < list.length; i++)
    {
      registers.a = list[i];
      print(registers.a);

      registers.f = list[i];
      print(registers.f);

      registers.af = list[i];
      print(registers.af);

      registers.hl = list[i];
      print(registers.hl);
    }

    overrideTargetPlatformForDesktop();

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
