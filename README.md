# WozMania: an Apple ][ emulator for ARM 64

## Motivation

This is a toy project. I wanted to learn ARM 64 assembler, so I wrote this
program as an exercise. Since it is my first assembly program for this
processor, there must be parts where it is clumsy.

I tried to write code that was as fast as possible, even at the price of
compactness, therefore it uses macros instead of subroutines. Still, it is
pure emulation, there is no just-in-time code conversion.


## What is done

As of 2021-04-29:

* 6502 processor instructions: 136 out of 256;
* input: keyboard, floppy disk 1 and 2;
* output: 40 column text mode.


## How to use

1. Assemble the emulation by running the command `./assemble.sh`.
2. Download to the same directory a file that contains the
   Apple ][ ROM; it must be named `APPLE2.ROM` and contain the
   last 20480 bytes of the memory.
3. You may also download to the same directory a file that contains
   the floppy drive 1; it must be named `drive1.nib` and contain
   35 tracks of 13 sectors of 512 nibbles.
4. Similarly, a file named `drive2.nib` will have the contents
   of floppy drive 2;
5. Run the emulator with the command `./wozmania`.
6. If there is no disk to boot from, press Ctrl-C.
   This will emulate a Ctrl-Reset and bring you to BASIC.


## How to debug

To generate debugging symbols, export this variable before assembling:
```
export DEBUG=1
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

To single-step one 6502 instruction, use:
```
     (gdb) b next
     (gdb) run
     ...
     (gdb) c
```

There are four subroutines to help debugging.
They are commented out by default:
```
   emulate:
        //bl    trace
        //bl    break
        //bl    check

	//b	print_nibble
```

You may uncomment these lines according to your debugging needs.

### trace

`trace` prints the registers for each executed 6502 instruction.

### break

`break` allows to set a 6502 breakpoint. For example, from `gdb`, to specify
`$DAF2` as a break point address:
```
     (gdb) b here
     (gdb) run
     (gdb) set *(short *) &breakpoint = 0xDAF2
     (gdb) c
```
the breakpoint can then be changed at any time later.

### check

`check` verifies the value of the registers at each executed 6502 instruction.

### print_nibble

`print_nibble` displays the drive number, track number, position of disk head, and the last nibble read.


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


## Copyright and License

WozMania is (c) 2021 Eric Bischoff.

WozMania is released under GNU GENERAL PUBLIC LICENSE, Version 2.
See LICENSE file for details.
