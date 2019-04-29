import 'dart:io';

import 'package:wave_generator/wave_generator.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioGenerator
{
  static void test()
  {
    if(Platform.isIOS || Platform.isAndroid)
    {
      AudioPlayer audioPlayer = new AudioPlayer();
      audioPlayer.play('output.wav');
    }

    testSoundGenerator () async
    {
      WaveGenerator generator = new WaveGenerator(/* sample rate */ 44100, BitDepth.Depth8bit);

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
  }
}