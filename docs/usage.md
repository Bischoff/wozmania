# WozMania: an Apple ][ emulator for ARM 64

##### Table of Contents

 * [How to Use](#use)
    * [Running WozMania](#run)
    * [Using the Keyboard](#keyboard)
    * [Using the Floppy Disks](#floppy)
    * [Using the Language Card](#language)
 * [How to Debug](#debug)
    * [Debugging with gdb](#gdb)
    * [Helper Routines](#helpers)
 * [Performance Considerations](#performance)
    * [Coding Style](#style)
    * [Implemented Accelerations](#implemented)
    * [Not Implemented Accelerations](#not-implemented)
 * [Bibliography](#biblio)


<a name="use"/>

## How to Use


<a name="run"/>

### Running WozMania

1. Assemble WozMania by running the command `./assemble.sh`.
2. Download to the same directory a file that contains the
   ROM of the Apple ]\[ and that must be named `APPLE2.ROM`.
3. Run the emulator with the command `./wozmania`.
4. To exit the emulator, press F4.

The ROM file must contain the last part of the memory. For example,
Apple ]\[+ ROM files covering memory from `$B000` to `$FFFF` are
20,480 bytes long (5 x 4,096). That's larger than the ROM space
(`$D000` to `$FFFF`, 3 * 4,096 bytes), but that's not a problem.

A configuration file named `wozmania.conf`, also situated in the same
directory as the emulator, allows to fine-tune the emulated hardware
at run time.


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
Two nibbles are needed to represent one useful byte, therefore that
is only a capacity of 35 track of 13 sectors of 256 bytes.

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

To prevent accidental writing on a disk, use a command like:
```
$ chmod -w drive1.nib
```
This is equivalent to closing the write protection punch with black
tape on an original floppy disk.

Writing on `.dsk` files is not supported yet.

#### Enabling or Disabling the Controller

Some ROM files do not contain the floppy disk controller's ROM at `$C600`.
To install this ROM, specify in the configuration file:
```
floppy install
```

You may completly disable the floppy disk controller by specifying:
```
floppy disable
```

Last option does not install the ROM code, but leaves the controller
enabled:
```
floppy enable
```


<a name="language"/>

### Using the Language Card

Apple's language card offers additional 16 KiB of RAM and 2 KiB of ROM.
It is designed to host a language other than Applesoft BASIC,
like Integer BASIC or Pascal.

If you boot on the DOS system master disk, it loads the Integer BASIC
into the language card. You can then switch to this BASIC with the
command `INT`, and back to AppleSoft BASIC with the command `FP`.

WozMania makes the following approximations:

* the emulator considers the ROM of the card as identical to
  the normal ROM of the Apple ]\[;
* when the language card is write-protected, it is enough to read
  only one time the relevant address to unlock the card.

Those simplifications should have no effect in real-life scenarios.

You may completly disable the language card by specifying in the
configuration file:
```
langcard disable
```

The other option leaves the language card enabled:
```
langcard enable
```


<a name="debug"/>

## How to Debug


<a name="gdb"/>

### Debugging with gdb

To generate debugging symbols, export this variable before assembling:
```
$ export DEBUG=1
```
assemble, and start the emulator with `gdb`:
```
$ gdb wozmania
```

From `gdb`, you may inspect the 6502 registers like this:
```
(gdb) i r w19              program counter
          w20              stack pointer
          w21              A
          w22              X
          w23              Y
          w24              program status
```

To inspect contents of the Apple's memory, for example at emulated
address `$0300`, use:
```
(gdb) x /32xb $x25 + 0x0300
```

To single-step one 6502 instruction, use:
```
(gdb) b next
(gdb) run
      ...
(gdb) c
```


<a name="helpers"/>

### Helper Routines

There are five routines to help debugging:

* `trace`
* `break`
* `check`
* `f_read`
* `f_write`

By default, they are not assembled. To assemble them, use
environment variables, e.g.:
```
$ TRACE=1 ./assemble.sh
```

You can redirect the output of these routines like this:
```
$ ./wozmania 2> debug.txt
```
and then follow the debugging in another terminal:
```
$ tail -f debug.txt
```

#### trace

`trace` prints the registers for each executed 6502 instruction.

To activate this routine, assemble with `TRACE=1`.

#### break

`break` allows to set a 6502 breakpoint. For example, from `gdb`, to specify
`$DAF2` as a break point address:
```
(gdb) b here
(gdb) run
(gdb) set *(short *) &breakpoint = 0xDAF2
(gdb) c
```
the breakpoint can then be changed at any time later.

To activate this routine, assemble with `BREAK=1`.

#### check

`check` verifies the value of the registers at each executed 6502 instruction.

To activate this routine, assemble with `CHECK=1`.

#### f_read and f_write

`f_read` displays the drive number, track number, position of disk head,
and the last nibble read from the floppy disk.

To activate this routine, assemble with `F_READ=1`.

`f_write` does the same for the last nibble written.

To activate this routine, assemble with `F_WRITE=1`.


<a name="performance"/>

## Performance Considerations

<a name="style"/>

### Coding Style

I tried to write code that was as fast as possible, even at the price of
compactness, therefore it uses macros instead of subroutines. The ARM
return stack is intentionally not used at all.


<a name="implemented"/>

### Implemented Accelerations

Access to zero page is priviledged in the emulator, with less memory mappings.

Keyboard is polled for real only one time out of 256. This has a huge
performance impact, as the Apple's ROM keeps polling the keyboard a lot,
even when running non-interative BASIC programs.

16-bit addresses are loaded in one ARM instruction (`ldrh`).
This will lead to emulation inaccuracies for the second byte:

 * addresses that span over two different memory banks will use the
   wrong bank for that byte;
 * addresses that span over I/O addresses will not trigger I/O
   for that byte;
 * indexed indirect addressing mode, like in `LDA   ($1A,X)`,
   will not cycle inside page 0 for that byte;
 * when there is a stack overflow or underflow, the pushed or pulled
   address will not cycle inside page 1 for that byte.

All those cases are very marginal and should not impact real-life scenarios.


<a name="not-implemented"/>

### Not Implemented Accelerations

WozMania is a pure interpreter, there is no just-in-time compilation of
6502 code.

There is no interception of calls to well-known routines. Performance is
good enough without using such tricks.


<a name="biblio"/>

## Bibliography

NMOS 6502 opcodes,
John Pickens et. al.,
http://6502.org/tutorials/6502opcodes.html

The 6502 overflow flag explained mathematically,
Ken Shirriff,
http://www.righto.com/2012/12/the-6502-overflow-flag-explained.html

CPU unofficial opcodes,
Damian Yerrick et. al.,
https://wiki.nesdev.com/w/index.php/CPU_unofficial_opcodes

Apple II ROM disassembly,
James P. Davis,
https://6502disassembly.com/a2-rom/APPLE2.ROM.html

Beneath Apple DOS,
Don Worth and Peter Lechner,
Quality Software, 4th edition, May 1982

Apple Language Card,
Apple Computer Inc.
