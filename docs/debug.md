# WozMania: an Apple ][ emulator for ARM 64


[Top](wozmania.md): Table of Contents - [Previous](subsystems.md): The Subsystems - [Next](performance.md): Performance Considerations


## How to Debug


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
(gdb) i r w17              program counter
          w18              stack pointer
          w19              A
          w20              X
          w21              Y
          w22              program status
```

To inspect contents of the Apple's memory, for example at emulated
address `$0300`, use:
```
(gdb) x /32xb $x23 + 0x0300
```

To single-step one 6502 instruction, use:
```
(gdb) b next
(gdb) run
      ...
(gdb) c
```


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
$ TRACE=1 make
```

You can redirect the output of these routines like this:
```
$ wozmania 2> debug.txt
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


[Top](wozmania.md): Table of Contents - [Previous](subsystems.md): The Subsystems - [Next](performance.md): Performance Considerations
