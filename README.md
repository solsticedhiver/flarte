# flarte

A desktop application (*Linux* and *Windows*) to browse https://www.arte.tv website.

It merely copies the website interface, but adds the possibility to download the videos, by using *yt-dlp*.

On Windows, excepts the binary yt-dlp.exe to be in flarte directory. Downloads to `%USERPROFILE%\Downloads` directory.

On Linux, downloads to `$XDG_DOWNLOAD_DIR` if set else to `$HOME`.

Will be configurable, once settings dialog is done.

## TODO:

- settings dialog/route
- add france.tv and other network ?
