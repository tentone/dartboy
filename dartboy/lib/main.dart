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
    Registers registers = MainScreen.emulator.cpu.registers;
    registers.reset();
    registers.a = 2;
    print(registers.a);

    registers.af = 3;
    print(registers.af);

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
