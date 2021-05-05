# WozMania: an Apple ][ emulator for ARM 64

![DOS and Basic in wozmania](/docs/wozmania-basic.png)

## Motivation

This is a toy project. I wanted to learn ARM 64 assembler, so I wrote this
program as an exercise. Since it is my first assembly program for this
processor, there must be parts where it is clumsy.

I tried to write code that was as fast as possible, even at the price of
compactness, therefore it uses macros instead of subroutines. Still, it is
pure emulation, there is no just-in-time code conversion.


## What is done

As of 2021-05-04:

* 6502 processor instructions: 142 out of 256;
* input: keyboard;
* output: 40 column text mode;
* input-output: floppy disks 1 and 2.


## Usage

See the [documentation](/docs/usage.md).


## Copyright and License

WozMania is (c) 2021 Eric Bischoff.

WozMania is released under GNU GENERAL PUBLIC LICENSE, Version 2.
See LICENSE file for details.
