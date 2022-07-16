# WozMania: an Apple ][ emulator for ARM 64


[Top](wozmania.md): Table of Contents - [Next](run.md): How to Run


## How to Build


### Assembling the Emulator

To assemble and install WozMania:

1. go to `src/emulator` subdirectory
2. run `make`
3. run `sudo make install`.
4. Download to the directory `/var/lib/wozmania/roms` a file
   named `APPLE2.ROM` that contains the ROM of the Apple ]\[.


### Compiling the Graphical User Interface:

To compile and install the Graphical User Interface:

1. install the Qt5 development libraries
2. go to `src/gui` subdirectory
3. run `qmake wozmania-gui.pro`
4. run `make`
5. run `sudo make install`


### The ROM File

The ROM file must contain the last part of the memory. For example,
Apple ]\[+ ROM files covering memory from `$B000` to `$FFFF` are
20,480 bytes long (5 x 4,096). That's larger than the ROM space
(`$D000` to `$FFFF`, 3 x 4,096 bytes), but that's not a problem.

A configuration file named `/etc/wozmania.conf` allows to fine-tune
the emulated hardware at run time, as well as the paths to various
files. For example, to use a different ROM file, declare:
```
rom /path/to/some/other/rom/file
```

WozMania essentially tries to emulate an Apple ]\[+. While other models,
like the Apple //e, are out of focus, it is likely they will at least
partially work if you use the ROM corresponding to those models.


[Top](wozmania.md): Table of Contents - [Next](run.md): How to Run
