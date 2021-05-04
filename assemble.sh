#! /bin/bash

AS_OPTS=""
if [ "$DEBUG" != "" ]; then
  AS_OPTS="-g"
fi

as $AS_OPTS instructions.s -o instructions.o
as $AS_OPTS emulator.s -o emulator.o
as $AS_OPTS floppy.s -o floppy.o
as $AS_OPTS keyboard.s -o keyboard.o
as $AS_OPTS text.s -o text.o
as $AS_OPTS debug.s -o debug.o
ld instructions.o emulator.o floppy.o keyboard.o text.o debug.o -o wozmania
rm instructions.o emulator.o floppy.o keyboard.o text.o debug.o
