# WozMania: an Apple ][ emulator for ARM 64


[Top](wozmania.md): Table of Contents - [Previous](build.md): How to Build - [Next](subsystems.md): The Subsystems


## How to Run


### System Requirements

To run WozMania, you need:

- a Linux system
- a 64 bits ARM processor
- at least 1 MB RAM
- at least 2 MB disk space
- an ANSI terminal with at least 26 rows and 80 columns
  and support for Unicode characters
- if you want to use the GUI, a X-Window display.


### Running in a Terminal

To run the emulator in an ANSI terminal like the Linux console,
xterm, konsole or gnome-terminal:

1. Make sure the configuration file `/etc/wozmania.conf` contains:
```
gui disable
```
2. Run the emulator with the command `wozmania`.
3. To exit the emulator, press F4.

![DOS and Applesoft BASIC in WozMania](/docs/applesoft.png)

### Running in the Graphical User Interface

The WozMania GUI and the emulator are two separate programs.
To run WozMania in a Graphical User Interface:

1. Make sure the configuration file `/etc/wozmania.conf` contains:
```
gui enable
```
2. Start the emulator as a background task by typing `wozmania &`
3. Start the GUI by typing `wozmania-gui`
4. To exit the emulator, select `Power` => `off` in the menus.

![The Graphical User Interface](gui.png)

In the GUI, the following menus are defined:

| Linux menus                | Apple ]\[         |
| -------------------------- | ----------------- |
| `Power` => `Off`           | Power off         |
| `Floppy` => `Flush`        | Flush floppy disk |
| `Keyboard` => `Ctrl-Reset` | Ctrl-Reset        |


[Top](wozmania.md): Table of Contents - [Previous](build.md): How to Build - [Next](subsystems.md): The Subsystems
