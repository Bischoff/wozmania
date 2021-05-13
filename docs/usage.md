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
 * [Technical Details](#details)
 * [Bibliography](#biblio)


<a name="use"/>

## How to Use


<a name="run"/>

### Running WozMania

1. Assemble WozMania by running the command `./assemble.sh`.
2. Download to the same directory a file that contains the
   ROM of the Apple ][ and that must be named `APPLE2.ROM`.
3. Run the emulator with the command `./wozmania`.
4. To exit the emulator, press F4.

The ROM file must contain the last part of the memory.
For example, Apple ][+ ROMs covering memory from
`$B000` to `$FFFF` are 20,480 bytes long (5 x 4096).


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

In the same directory as the emulator, there are two files, `drive1.nib`
and `drive2.nib`. They represent the contents of the two floppy drives
and contain 232,960 bytes each (35 tracks of 13 sectors of 512 nibbles).

If you remove these files, the emulator still starts, but the DOS hangs
trying to read them. In such a case, press Ctrl-C, this will emulate
a Ctrl-Reset and bring you to BASIC.

These files are initially blank. If you saved new data on them but want
to revert them to blank, replace them with the file `disks/blank.nib`.
You can also replace them with any other `.nib` file, for example with
the DOS master disk.

To prevent accidental writing on a disk, use a command like:
```
$ chmod -w drive1.nib
```
This is equivalent to closing the write protection punch with black
tape on an original floppy disk.

Some ROM files do not contain the controller's ROM at `$C600`.
To enable it, uncomment this line:
```
	//bl	enable_drives
```

You may completly disable the floppy disk controller by uncommenting
this line:
```
	//bl	disable_drives
```


<a name="language"/>

## Using the Language Card

Apple's language card offers additional 16 KiB of RAM and 2 KiB of ROM.
It is designed to host a language other than Applesoft BASIC,
like Integer BASIC or Pascal.

If you boot on the DOS system master disk, it loads the Integer BASIC
into the language card. You can then switch to this BASIC with the
command `INT`, and back to AppleSoft BASIC with the command `FP`.

You may completly disable the language card by uncommenting this line:
```
	//bl	disable_langcard
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

* trace
* break
* check
* f_read
* f_write

By default, they are not assembled. To assemble them, use
environment variables, e.g:
```
$ TRACE=y ./assemble.sh
```

The environment variables that can be defined are
`TRACE`, `BREAK`, `CHECK`, `F_READ`, and `F_WRITE`.

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

#### check

`check` verifies the value of the registers at each executed 6502 instruction.

#### f_read and f_write

`f_read` displays the drive number, track number, position of disk head,
and the last nibble read from the floppy disk.

`f_write` does the same for the last nibble written.


<a name="details"/>

## Technical Details

I tried to write code that was as fast as possible, even at the price of compactness,
therefore it uses macros instead of subroutines. The stack is intentionally not used
at all.

The nature of an emulator makes it difficult to use the pre-increment and
post-increment functionalities of the ARM 64 (there are almost no loops, for instance).
This is why you will see very little use of those functionalities.

The performance is quite disappointing. For example, the Rugg-Feldman benchmark 1
executes in 1'44s on my Raspberry Pi 400, against 1.3s on a real Apple ][,
i.e. 80 times slower. I don't know if the other emulators do better.


<a name="biblio"/>

## Bibliography

NMOS 6502 opcodes,
John Pickens et. al.,
http://6502.org/tutorials/6502opcodes.html

The 6502 overflow flag explained mathematically,
Ken Shirriff,
http://www.righto.com/2012/12/the-6502-overflow-flag-explained.html

Apple II ROM disassembly,
James P. Davis,
https://6502disassembly.com/a2-rom/APPLE2.ROM.html

Beneath Apple DOS,
Don Worth and Peter Lechner,
Quality Software, 4th edition, May 1982

Apple Language Card,
Apple Computer Inc.
