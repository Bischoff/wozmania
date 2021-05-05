# WozMania: an Apple ][ emulator for ARM 64

##### Table of Contents  

 * [How to use](#use)  
    * [Using the keyboard](#keyboard)
    * [Using the floppy disks](#floppy)
 * [How to debug](#debug)  
    * [Debugging with gdb](#gdb)
    * [Helper routines](#helpers)
 * [Bibliography](#biblio)  


<a name="use"/>

## How to use

1. Assemble WozMania by running the command `./assemble.sh`.
2. Download to the same directory a file that contains the
   ROM of the Apple ][ and that must be named `APPLE2.ROM`.
3. Run the emulator with the command `./wozmania`.
4. To exit the emulator, press F4.

WozMania emulates only the hardware of an Apple ][+. It is therefore
recommended to use the ROM of that model (20,480 bytes long).

<a name="keyboard"/>

### Using the keyboard

The following keys are defined:

| Linux  | Apple ][   |
| ------ | ---------- |
| Ctrl-C | Ctrl-Reset |
| F3     | Ctrl-C     |
| F4     | Power off  |


<a name="floppy"/>

### Using the floppy disks

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

You may completly disable the floppy disk controller by uncommenting
this line:
```
	//bl	disable_drives
```


<a name="debug"/>

## How to debug


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

### Helper routines

There are five subroutines to help debugging.
They are commented out by default:
```
emulate:
        //bl    trace
        //bl    break
        //bl    check

	//b	nibble_read

	//b	nibble_written
```
You may uncomment these lines according to your debugging needs.

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

#### nibble_*

`nibble_read` displays the drive number, track number, position of disk head, and the last nibble read.

`nibble_written` does the same for the last nibble written.


<a name="biblio"/>

## Bibliography

NMOS 6502 opcodes,
John Pickens et. al.,
http://6502.org/tutorials/6502opcodes.html

Apple II ROM disassembly,
James P. Davis,
https://6502disassembly.com/a2-rom/APPLE2.ROM.html

The 6502 overflow flag explained mathematically,
Ken Shirriff,
http://www.righto.com/2012/12/the-6502-overflow-flag-explained.html

Beneath Apple DOS,
Don Worth and Peter Lechner,
Quality Software, 4th edition, May 1982
