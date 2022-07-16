The emulator communicates with the GUI via the non-blocking
Unix domain socket `/tmp/wozmania.sock`.

This document explains the protocol used.

# Emulator => GUI

 * 'N' `x` `y` `c`

   prints character `c` at position `(x,y)` in normal text

 * 'I' `x` `y` `c`

   prints character `c` at position `(x,y)` in inverted text

 * 'F' `x` `y` `c`

   prints character `c` at position `(x,y)` in flashing text
   (not implemented yet)

 * 'G' `x` `y` `pair`

   prints a pair of low-resolution pixels at position `(x,y)`,
   the color of top pixel is coded in the 4 high-order bits,
   and the color of bottom pixel is coded in the 4 low-order
   bits of `pair`

 * 'A' `message`

   prints null-terminated `message` in an alert box

 * 'S' `drive` `dirty`

   changes the status bar to reflect state of floppy `drive`
   as `dirty` (red) or not (green)


# GUI => emulator

 * normal keys

   all characters, excepted 'Esc' key

 * 'Esc' 'F'

   "flush disk" command

 * 'Esc' 'R'

   "ctrl-Reset" command

 * 'Esc' 'Esc'

   'Esc' key itself
