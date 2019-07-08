# DartBoy

- Dart based GameBoy (and GameBoy Color) emulator that runs on desktop, mobile and web using the Flutter framework (tested on Windows and Android).
- Project was developed using Flutter 1.5.5 and Dart 2.3.0.
- Supports MBC1, MBC2, MBC3, MBC5 and basic cartridges, has basic support for GameBoy Color games. Does not support Super GameBoy specific features.
- Full support for the Sharp LR35902 CPU instruction set.


### Screenshots




### Setup Flutter Desktop

- In Windows install visual studio with C++ support and make sure that the command `msbuild` works properly and that `vcvars64.bat` is in the path. (If visual studio is installed but `msbuild` is not found, add it to your path).
- Flutter desktop support is still experimental and not enabled by default, its only available on the master channel.

```
flutter channel master
flutter precache --windows
flutter upgrade
```

- Set the `ENABLE_FLUTTER_DESKTOP` environment variable true, to enable desktop support.

```
set ENABLE_FLUTTER_DESKTOP=true
flutter devices
```



### Resources

- [GameBoy CPU Manual](http://marc.rawer.de/Gameboy/Docs/GBCPUman.pdf)
- [Everything You Always Wanted To Know About GAMEBOY](http://bgb.bircd.org/pandocs.htm)
- [GameBoy CPU (LR35902)](http://www.pastraiser.com/cpu/gameboy/gameboy_opcodes.html)
- [Flutter desktop quick start guide](https://github.com/google/flutter-desktop-embedding/blob/master/Quick-Start.md)
- [Flutter desktop embedding example](https://github.com/google/flutter-desktop-embedding)
- [Flutter desktop plugins (file chooser)](https://github.com/google/flutter-desktop-embedding/tree/master/plugins)
- [Game boy test roms](https://github.com/retrio/gb-test-roms)
- [The Ultimate Game Boy Talk (33c3)](https://www.youtube.com/watch?v=HyzD8pNlpwI)

