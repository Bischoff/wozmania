#! /bin/bash

AS_OPTS=""
if [ "$DEBUG" != "" ]; then
  AS_OPTS="-g"
fi

as $AS_OPTS src/instructions.s -o instructions.o
as $AS_OPTS src/emulator.s -o emulator.o
as $AS_OPTS src/floppy.s -o floppy.o
as $AS_OPTS src/keyboard.s -o keyboard.o
as $AS_OPTS src/text.s -o text.o
as $AS_OPTS src/debug.s -o debug.o
ld instructions.o emulator.o floppy.o keyboard.o text.o debug.o -o wozmania
rm instructions.o emulator.o floppy.o keyboard.o text.o debug.o

if [ ! -f drive1.nib ]; then
  cp disks/blank.nib drive1.nib
fi

if [ ! -f drive2.nib ]; then
  cp disks/blank.nib drive2.nib
fi
