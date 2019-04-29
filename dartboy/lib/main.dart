import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wave_generator/wave_generator.dart';

import 'package:audioplayers/audioplayers.dart';

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

    if(Platform.isIOS || Platform.isAndroid)
    {
      AudioPlayer audioPlayer = new AudioPlayer();
      audioPlayer.play('output.wav');
    }

    testSoundGenerator () async {

      WaveGenerator generator = new WaveGenerator(
        /* sample rate */ 44100,
          BitDepth.Depth8bit);

      Note note = new Note(
      /* frequency */ 220,
      /* msDuration */ 3000,
      /* waveform */ Waveform.Sine,
      /* volume */ 0.5);

      File file = new File('output.wav');

      List<int> bytes = List<int>();
      await for (int byte in generator.generate(note))
      {
        bytes.add(byte);
      }

      file.writeAsBytes(bytes, mode: FileMode.append);
    }

    testSoundGenerator();

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
