# WozMania: an Apple ]\[ emulator for ARM 64

![DOS and Applesoft BASIC in WozMania](/docs/applesoft.png)

## Goal

WozMania tries to be a very fast Apple ]\[ simulator, at the expense
of portability. It is written mostly in ARM 64 assembler, and
uses Linux system calls. It has been tested on Raspberry Pi.


## What is Done

WozMania 0.2, as of 2022-07-10, emulates:

* a 6502 processor, no decimal mode;
* an Apple ]\[ keyboard;
* video output in text mode, 40 and 80 columns;
* floppy disks 1 and 2, `.nib` and `.dsk` formats;
* a language card.

WozMania runs either with an ANSI terminal or with a GUI interface.


## What is Missing

See the [to do list](TODO).


## Usage

See the [documentation](/docs/wozmania.md).


## Contributing

Help wanted:

* ideas;
* a nice logo;
* test more Apple ]\[ programs;
* port to other platforms: Apple M1, Android;
* code.

Contact: eric dot1 bischoff dot2 fr snail gmail dot3 com.


## Copyright and License

WozMania is (c) 2021-2022 Eric Bischoff.

WozMania is released under GNU GENERAL PUBLIC LICENSE, Version 2.
See [LICENSE](LICENSE) file for details.
