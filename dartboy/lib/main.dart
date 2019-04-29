import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'gui/main_screen.dart';

void main()
{
  runApp(MyApp());
}

class MyApp extends StatelessWidget
{
  void overrideTargetPlatformForDesktop() {
    TargetPlatform targetPlatform;

    if(Platform.isMacOS)
    {
      targetPlatform = TargetPlatform.iOS;
    }
    else if (Platform.isLinux || Platform.isWindows)
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

    return new MaterialApp
    (
      title: 'DartBoy',
      theme: new ThemeData
      (
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'GBC'),
    );
  }
}
