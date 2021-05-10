#! /bin/bash

set -e

AS_OPTS=""
if [ "$DEBUG" != "" ]; then
  AS_OPTS="-g"
  echo "Assembling in DEBUG mode"
fi

for file in instructions emulator memory floppy keyboard text debug; do
  as $AS_OPTS src/$file.s -o $file.o
done

ld instructions.o emulator.o memory.o floppy.o keyboard.o text.o debug.o -o wozmania

for file in instructions emulator memory floppy keyboard text debug; do
  rm $file.o
done

if [ ! -f drive1.nib ]; then
  cp disks/blank.nib drive1.nib
  echo "Creating blank disk drive1.nib"
fi

if [ ! -f drive2.nib ]; then
  cp disks/blank.nib drive2.nib
  echo "Creating blank disk drive2.nib"
fi

echo "Assembly complete"
