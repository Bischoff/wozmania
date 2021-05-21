# WozMania: an Apple ][ emulator for ARM 64


[Top](wozmania.md): Table of Contents - [Next](debug.md): How to Debug

<a name="use"/>

## How to Use


<a name="run"/>

### Running WozMania

1. Assemble WozMania by running the command `./assemble.sh`.
2. Download to the same directory a file that contains the
   ROM of the Apple ]\[ and that must be named `APPLE2.ROM`.
3. Run the emulator with the command `./wozmania`.
4. To exit the emulator, press F4.

![DOS and Applesoft BASIC in WozMania](/docs/applesoft.png)

The ROM file must contain the last part of the memory. For example,
Apple ]\[+ ROM files covering memory from `$B000` to `$FFFF` are
20,480 bytes long (5 x 4,096). That's larger than the ROM space
(`$D000` to `$FFFF`, 3 x 4,096 bytes), but that's not a problem.

A configuration file named `wozmania.conf`, also situated in the same
directory as the emulator, allows to fine-tune the emulated hardware
at run time.

WozMania essentially tries to emulate an Apple ][+. While other
models, like the Apple //e, are out of focus, it is likely they
will at least partially work.


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

In the same directory as the emulator, there are two files, `drive1.nib`
and `drive2.nib`. They represent the contents of the two floppy drives
and contain 232,960 nibbles each (35 tracks of 13 sectors of 512 nibbles).
Two nibbles are needed to represent one useful byte, therefore that's
only a capacity of 35 track of 13 sectors of 256 bytes.

You can also use files in `.dsk` format, `drive1.dsk` and `drive2.dsk`
They contain 143,360 bytes each (35 tracks of 16 sectors of 256 bytes).
WozMania first tries to load `drive1.nib`, and if it is absent,
it takes `drive1.dsk`, and the same goes for the second drive.

If you have no file at all for the first drive, the emulator still starts,
but the DOS hangs trying to read the floppy. In such a case, press Ctrl-C,
this will emulate a Ctrl-Reset and bring you to BASIC.

#### Saving Data

The files shipped with WozMania are initially blank. If you saved new data
on them but want to revert them to blank, replace them with the file
`disks/blank.nib`. You can also replace them with any other disk file,
for example with the DOS master disk.

![The master disk files in WozMania](floppy.png)

To prevent accidental writing on a disk, use a command like:
```
$ chmod -w drive1.nib
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
can also take advantage of the Videoterm card.

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
