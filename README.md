# Compote: an Apple ][ emulator for ARM 64

## Motivation

This is a toy project. I wanted to learn ARM 64 assembler, so I wrote this
program as an exercise. Since it is my first assembly program for this
processor, there must be parts where it is clumsy.

I tried to write code that was as fast as possible, even at the price of
compactness, therefore it uses macros instead of subroutines. Still, it is
pure emulation, there is no just-in-time code conversion.


## What is done

As of 2021-04-18:

* 6502 processor instructions: 103 out of 256;
* input: keyboard, keyboard strobe;
* output: text buffer.

That is sufficient to run Applesoft BASIC and the ROM monitor.


## How to use

1. Assemble the emulation by running the command `./assemble.sh`.
2. Download to the same directory a file that contains the
   Apple ][ ROM; it must be named `APPLE2.ROM` and contain the
   last 20480 bytes of the memory.
3. Run the emulator with the command `./compote`.


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

There are three subroutines to help debugging. They are commented out
by default:
```
   emulate:
        //bl    trace
        //bl    break
        //bl    check
```

You may uncomment these lines according to your debugging needs.

`trace` prints the registers for each executed 6502 instruction.

`break` allows to set a 6502 breakpoint. For example, from `gdb`, to specify
`$DAF2` as a break point address:
```
     (gdb) b here
     (gdb) run
     (gdb) set *(short *) &breakpoint = 0xDAF2
     (gdb) c
```
the breakpoint can then be changed at any time later.

`check` verifies the value of the registers at each executed 6502 instruction.

There is another line that is interesting to uncomment:
```
        //.align        16
memory:
```

It aligns the 6502 memory to a 64k boundary. The address in ARM register `w25`
can then be combined with a 6502 address with a simple OR to provide the real
address of that memory.


## Copyright and License

Compote is (c) 2021 Eric Bischoff.

Compote is released under GNU GENERAL PUBLIC LICENSE, Version 2.
See LICENSE file for details.
