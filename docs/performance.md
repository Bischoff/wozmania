# WozMania: an Apple ][ emulator for ARM 64


[Top](wozmania.md): Table of Contents - [Previous](debug.md): How to Debug - [Next](bibliography.md): Bibliography

<a name="performance"/>

## Performance Considerations

<a name="style"/>

### Coding Style

I tried to write code that was as fast as possible, even at the price of
compactness, therefore it uses macros instead of subroutines. The ARM
return stack is intentionally not used at all.


<a name="processor"/>

### Processor Accelerations

Access to zero page is priviledged in the emulator, with less memory mappings.

16-bit addresses are loaded in one ARM instruction (`ldrh`).
This will lead to emulation inaccuracies for the second byte:

 * addresses that span over two different memory banks will use the
   wrong bank for that byte;
 * addresses that span over I/O addresses will not trigger I/O
   for neither of both bytes;
 * indexed indirect addressing mode, like in `LDA   ($1A,X)`,
   will not cycle inside page 0 for that byte;
 * when there is a stack overflow or underflow, the pushed or pulled
   address will not cycle inside page 1 for that byte.

All those cases are very marginal and should not impact real-life scenarios.


<a name="input-output"/>

### Input-output Accelerations

The keyboard is polled for real only one time out of 256 (this value
can be changed in the configuration file). This has a huge
performance impact, as the Apple's ROM keeps polling the keyboard a lot,
even when running non-interative BASIC programs.

The floppy disks are read for real only at the startup of the emulator,
and written for real only at the end of the emulator (assuming its contents
was modified). All input-output in the meantime only happens in memory.
You can force an earlier flushing by pressing F1.
(F1 does not work yet)


<a name="not-implemented"/>

### Not Implemented Accelerations

WozMania is a pure interpreter, there is no just-in-time compilation of
6502 code.

There is no interception of calls to well-known routines. Performance is
good enough without using such tricks.

Floppy disk is marked as "dirty" as a whole when its contents are changed.
We could refine by marking tracks or sectors individually as "dirty".
Not sure it would be worth the effort though.

[Top](wozmania.md): Table of Contents - [Previous](debug.md): How to Debug - [Next](bibliography.md): Bibliography
