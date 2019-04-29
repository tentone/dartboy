import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'gui/main_screen.dart';

void main()
{
  runApp(DartBoyApp());
}

class DartBoyApp extends StatelessWidget
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
    overrideTargetPlatformForDesktop();

    File rom = new File('./roms/cpu_instrs.gb');
    List<int> data = rom.readAsBytesSync();
    print(data.length);

    return new MaterialApp
    (
      title: 'DartBoy',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new MainScreen(title: 'GBC'),
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      debugShowMaterialGrid: false
    );
  }
}
