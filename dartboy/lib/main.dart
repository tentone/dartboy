import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    overrideTargetPlatformForDesktop();

    Function printVariants = (int a)
    {
      print(a);
      print(a.toSigned(8));
      print(a.toUnsigned(8));
    };


    Uint8List a = new Uint8List(1);
    a[0] = 255;
    print(a);
    print(a[0].toSigned(8));
    a[0] += 2;
    print(a);

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
