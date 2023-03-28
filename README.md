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
- linux_x64.tar.gz: this is built on an *Ubuntu 22.04* and expects *libmpv.so.1* to be present. Otherwise, you will have to compile it yourself with the *flutter* SDK.

## Known issues

Embedded player is sub-optimal (based on mpv/libmpv):
- no sound on some videos (ffmpeg bug)
- no subtitles
- seeking (forward/backward) does not always work
- bug: download is aborted if dialog is closed

Using an external [c]vlc instance will be an option, once settings will be done. This will fix only the first issue, though :-(

## TODO

- settings dialog/route
- better control for player (fullscreen, sound)
- make it usable on android tablet/phone?
- add france.tv and other network?
