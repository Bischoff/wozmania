# WozMania: an Apple ][ emulator for ARM 64


[Top](wozmania.md): Table of Contents - [Previous](debug.md): How to Debug - [Next](bibliography.md): Bibliography


## Performance Considerations


### Coding Style

I tried to write code that was as fast as possible, even at the price of
compactness, therefore it uses macros instead of subroutines. The ARM
return stack is intentionally almost not used at all.



### Processor Accelerations

Access to zero page is priviledged in the emulator, with less memory mappings.

16-bit addresses are loaded in one ARM instruction (`ldrh`).
This will lead to emulation inaccuracies for the second byte:

 * addresses that span over two different memory banks will use the
   wrong bank for that byte;
 * addresses that span over I/O addresses will not trigger I/O
   for neither of both bytes;
 * indexed indirect addressing mode, like in `LDA   ($1A,X)`,
   will not cycle inside page 0;
 * when there is a stack overflow or underflow, the pushed or pulled
   address will not cycle inside page 1.

All those cases are very marginal and should not impact real-life scenarios.



### Input-output Accelerations

The keyboard is polled for real only one time out of 256 (this value
can be changed in the configuration file). This has a huge
performance impact, as the Apple's ROM keeps polling the keyboard a lot,
even when running non-interactive BASIC programs.

The floppy disks are read for real only at the startup of the emulator,
and written for real only at the end of the emulator (assuming their contents
were modified). All input-output in the meantime only happens in memory.
You can force an earlier flushing by pressing F1 (when running in a terminal),
or by choosing `Floppy` => `Flush` (when using the GUI).

When using the Graphical User Interface, the emulator sends data to the
screen via a Unix domain socket. When the output buffer is full, the emulator
waits for 2.1 milliseconds and retries. This value has been determined
experimentally as an optimum. There does not seem to be an easy way to
increase the size of the output buffer of the socket.


### Not Implemented Accelerations

WozMania is a pure interpreter, there is no just-in-time compilation of
6502 code.

There is no interception of calls to well-known routines. Performance is
good enough without using such tricks.

Floppy disk is marked as "dirty" as a whole when its contents are changed.
We could refine by marking tracks or sectors individually as "dirty".
I am not sure it would be worth the effort though.

[Top](wozmania.md): Table of Contents - [Previous](debug.md): How to Debug - [Next](bibliography.md): Bibliography
