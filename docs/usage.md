# WozMania: an Apple ][ emulator for ARM 64


[Top](wozmania.md): Table of Contents - [Previous](build.md): How to Build - [Next](debug.md): How to Debug


## How to Use


### Running WozMania

To run WozMania, you need:

- a Linux system
- a 64 bits ARM processor
- at least 1 MB RAM
- at least 2 MB disk space
- an ANSI terminal with at least 26 rows and 80 columns
- if you want to use the GUI, a X-Window display.

To run the emulator in a terminal:

1. Run the emulator with the command `wozmania`.
2. To exit the emulator, press F4.

![DOS and Applesoft BASIC in WozMania](/docs/applesoft.png)

To run WozMania in a Graphical User Interface:

1. Start the emulator as a background task by typing `wozmania &`
2. Start the GUI by typing `wozmania-gui`
3. To exit the emulator, select `Power` => `off` in the menus.


### Using the Keyboard

In text mode, the following keys are defined:

| Linux keys | Apple ]\[         |
| ---------- | ----------------- |
| Ctrl-C     | Ctrl-Reset        |
| F1         | Flush floppy disk |
| F3         | Ctrl-C            |
| F4         | Power off         |

You can set the ratio at which the keyboard is polled for real.
For example, if you set in `/etc/wozmania.conf`:
```
keyboard_poll_ratio 7
```
it means that keyboard is polled for real only one time
out of 128 (2^7 = 128). The idea is to accelerate the emulator
by not spending more time in system calls than necessary.
The default value is 8, meaning the keyboard is polled only
one time out of 256.


### Using the screen

WozMania emulates a display in text mode or in low-resolution graphics
mode.

In text mode, there are 40 columns on 24 lines. You reach this mode
from BASIC by using the command `TEXT`. Characters can be displayed
in normal mode (command `NORMAL`), inverted (command `INVERSE`), or
flashing (command `FLASH`).

In low-resolution graphics mode, there are by default 40x40 pixels
in 16 colors and 4 lines of text. You reach this mode by using the
command `GR`. You can obtain a full graphic screen of 40x48 pixels
in 16 colors with the BASIC command `POKE -16302,0`. You can return
to the mixed graphic and text display with `POKE -16301,0`.
 
![Low-resolution mode](/docs/lores.png)

Text mode is available in both an ANSI terminal and in the GUI interface.
Low-resolution mode is available in an ANSI terminal.
Other combinations are under development.

Note: there is also a 80-column text mode explained in the section about
the 80 columns card below.


### Using the Floppy Disks

WozMania emulates a floppy disk controller in slot 6.

#### Supported formats

The file `/var/lib/wozmania/disks/blank.nib` represents the low level
contents of a blank disk inserted in a floppy drive. It contains
232,960 nibbles (35 tracks of 13 sectors of 512 nibbles).
Two nibbles are needed to represent one useful byte, therefore that's
only a capacity of 35 track of 13 sectors of 256 bytes.

You can also use files in `.dsk` format.
`/var/lib/wozmania/disks/blank.dsk` also represents the contents
of a blank disk. It contains 143,360 bytes
(35 tracks of 16 sectors of 256 bytes) in a slightly higher level
representation.

#### Using other disks

![The master disk files in WozMania](floppy.png)

WozMania emulate two floppy drives. You can use other disks than
the two blank disks shipped with WozMania, for example you can use
the DOS master disk. To do that, download a file representing a
floppy disk somewhere and specify the path to this file in
`/etc/wozmania.conf`:
```
drive1 /path/to/some/other/disk
drive2 /path/to/yet/another/disk
```

The disk's format is recognized from the file name ending,
either '.nib' or '.dsk'.

If `drive1` or `drive2` is not specified in the configuration file,
the corresponding drive is considered as empty (no disk).
If the first drive is empty, the emulator still starts,
but the DOS hangs trying to read the floppy. In such a case, press Ctrl-C,
this will emulate a Ctrl-Reset and bring you to BASIC.

#### Saving Data

The blank disks shipped with WozMania are write-protected.
To write-protect any other disk in order to prevent accidental writing
to it, use a command like:
```
$ chmod -w mydisk.nib
```
This is equivalent to closing the write protection punch with black
tape on an original floppy disk.

All changes to the disk are written to a cache in memory. This cache
is flushed to disk when you exit the emulator.

You can force flushing the current disk at any time:
* by pressing F1 when running in a terminal
* by selecting `Floppy` => `Flush` menu in the GUI.

An unsaved cache is shown below the emulated screen:
* as `D1` or `D2` when running in a terminal
* as a red light next to `D1` or `D2` in the GUI.

#### Enabling or Disabling the Controller

To activate the floppy disk controller's ROM at `$C600`, specify in
the configuration file:
```
floppy enable
```

If the ROM file already contains ROM code for the floppy disk controller,
it will be ignored, and the firmware will be provided by WozMania.

You may completly disable the floppy disk controller by specifying:
```
floppy disable
```

If the ROM file already contains ROM code for the floppy disk controller,
it will be overwritten with a jump to the monitor.


### Using the Language Card

Apple's language card offers additional 16 KiB of RAM and 2 KiB of ROM,
and is inserted in slot 0. It is designed to host a language other than
Applesoft BASIC, like Integer BASIC or Pascal.

If you boot on the DOS system master disk, it loads the Integer BASIC
into the language card. You can then switch to this BASIC with the
command `INT`, and back to Applesoft BASIC with the command `FP`.

![Integer BASIC in WozMania](integer.png)

The Integer BASIC code also contains the mini-assembler. To
access the mini-assembler from the Integer BASIC, use the command
`CALL -2458`.

WozMania makes the following approximations:

* the emulator considers the ROM of the card as identical to
  the normal ROM of the Apple ]\[;
* when the language card is write-protected, it is enough to read
  only one time the relevant address to unlock the card.

Those simplifications should have no effect in real-life scenarios.

To activate the language card, specify in the configuration file:
```
langcard enable
```

You may completly disable the language card by specifying:
```
langcard disable
```


### Using the 80 Column Card

WozMania emulates a Videoterm 80 column card in slot 3 from
[Videx](https://videx.com/contact-us/about-videx/).

You can switch to 80 column mode from the BASIC by typing `PR#3`.
You can then return to 40 column mode by typing `PR#6`.
Some applications like [Visicalc](http://www.bricklin.com/history/saiidea.htm)
also take advantage of the Videoterm card.

![Visicalc in WozMania](visicalc.png)

WozMania makes the following approximation:

* the shared memory area (`$C800` to `$CFFF`) is always assigned to
  the 80 column card, no matter which card has been accessed last.

That simplification should have no effect in real-life scenarios.

To activate the 80 column card, specify in the configuration file:
```
80col enable
```

You may completly disable the 80 column card by specifying:
```
80col disable
```


### The Graphical User Interface

The WozMania GUI and the emulator are two separate programs.

The emulator communicates with the GUI via the Unix domain socket
`/tmp/wozmania.sock`.

![The Graphical User Interface](gui.png)

In the GUI, the following menus are defined:

| Linux menus                | Apple ]\[         |
| -------------------------- | ----------------- |
| `Power` => `Off`           | Power off         |
| `Floppy` => `Flush`        | Flush floppy disk |
| `Keyboard` => `Ctrl-Reset` | Ctrl-Reset        |

To run WozMania with the GUI, specify in the configuration file:
```
gui enable
```

You may return to a display in the terminal by specifying:
```
gui disable
```


[Top](wozmania.md): Table of Contents - [Previous](build.md): How to Build - [Next](debug.md): How to Debug
