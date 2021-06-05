# WozMania: an Apple ][ emulator for ARM 64


[Top](wozmania.md): Table of Contents - [Next](debug.md): How to Debug

<a name="use"/>

## How to Use


<a name="run"/>

### Running WozMania

1. Assemble and install WozMania by running the commands `make`
   and `sudo make install`.
2. Download to the directory `/var/lib/wozmania/roms` a file
   named `APPLE2.ROM` that contains the ROM of the Apple ]\[.
3. Run the emulator with the command `wozmania`.
4. To exit the emulator, press F4.

![DOS and Applesoft BASIC in WozMania](/docs/applesoft.png)

#### The ROM file

The ROM file must contain the last part of the memory. For example,
Apple ]\[+ ROM files covering memory from `$B000` to `$FFFF` are
20,480 bytes long (5 x 4,096). That's larger than the ROM space
(`$D000` to `$FFFF`, 3 x 4,096 bytes), but that's not a problem.

A configuration file named `/etc/wozmania.conf` allows to fine-tune
the emulated hardware at run time, as well as the paths to various
files. For example, tu use a different ROM file, declare:
```
rom /path/to/some/other/rom/file
```

WozMania essentially tries to emulate an Apple ]\[+. While other models,
like the Apple //e, are out of focus, it is likely they will at least
partially work if you use the ROM corresponding to those models.


<a name="keyboard"/>

### Using the Keyboard

The following keys are defined:

| Linux  | Apple ]\[  |
| ------ | ---------- |
| Ctrl-C | Ctrl-Reset |
| F3     | Ctrl-C     |
| F4     | Power off  |


<a name="floppy"/>

### Using the Floppy Disks

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

Writing on `.dsk` files is not supported yet.

#### Enabling or Disabling the Controller

To activate the floppy disk controller's ROM at `$C600`, specify in
the configuration file:
```
floppy enable
```

If the ROM file already contains ROM code for the floppy disk controller,
it will ignored, and the firmware will be provided by WozMania.

You may completly disable the floppy disk controller by specifying:
```
floppy disable
```

If the ROM file already contains ROM code for the floppy disk controller,
it will be overwritten with a jump to the monitor.


<a name="language"/>

### Using the Language Card

Apple's language card offers additional 16 KiB of RAM and 2 KiB of ROM.
It is designed to host a language other than Applesoft BASIC,
like Integer BASIC or Pascal.

If you boot on the DOS system master disk, it loads the Integer BASIC
into the language card. You can then switch to this BASIC with the
command `INT`, and back to AppleSoft BASIC with the command `FP`.

![Integer BASIC in WozMania](integer.png)

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


<a name="v80"/>

### Using the 80 Column Card

WozMania emulates a Videoterm 80 column card from
[Videx](https://videx.com/contact-us/about-videx/).

You can switch to 80 column mode from the BASIC by typing `PR#3`.
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


[Top](wozmania.md): Table of Contents - [Next](debug.md): How to Debug
