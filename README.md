# flarte

A *flutter* desktop application (*Linux* and *Windows*) to browse https://www.arte.tv website.

<img src="./screenshots/20230324-flarte-640x.png" />

It merely copies the website interface, but adds the possibility to download the videos, by using *ffmpeg*.
**It should be obvious that all the videos are copyrighted by arte.tv, and not free to share as is.**

On *Windows*, excepts the binary *ffmpeg.exe* to be in flarte directory. Downloads to `%USERPROFILE%\Downloads` directory.

On *Linux*, downloads to `$XDG_DOWNLOAD_DIR` if set else to `$HOME`.

Will be configurable, once settings dialog is done.

## Release archives

There are currently 2 archives with precompiled binaries:

- windows_x64.zip:  needs *ffmpeg.exe* (preferably in same directory as *flarte.exe*) to be able to download videos.
- linux_x64.tar.gz: this is built on an *Ubuntu 22.04* VM and expects *libmpv.so.1* to be present. If you have a more *recent mpv version* (with libmpv.so.2), you will have to build *flarte* with `flutter build`

## Building and running

To build and run yourself the app, once the flutter SDK is installed, you simply run `flutter run` in the directory of the source code.

## TODO

- better control for player (fullscreen, sound)
- text only mode
- cast to chromecast on android
- add france.tv and other network?
