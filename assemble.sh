#! /bin/bash

set -e

echo "Assembling WozMania..."

AS_OPTS=""
if [ "$DEBUG" != "" ]; then
  AS_OPTS="$AS_OPTS -g"
  echo "  enabling debug symbols"
fi
if [ "$TRACE" != "" ]; then
  AS_OPTS="$AS_OPTS --defsym TRACE=1"
  echo "  enabling trace output"
fi
if [ "$BREAK" != "" ]; then
  AS_OPTS="$AS_OPTS --defsym BREAK=1"
  echo "  enabling 6502 breakpoints"
fi
if [ "$CHECK" != "" ]; then
  AS_OPTS="$AS_OPTS --defsym CHECK=1"
  echo "  enabling register checks"
fi
if [ "$F_READ" != "" ]; then
  AS_OPTS="$AS_OPTS --defsym F_READ=1"
  echo "  enabling floppy read printout"
fi
if [ "$F_WRITE" != "" ]; then
  AS_OPTS="$AS_OPTS --defsym F_WRITE=1"
  echo "  enabling floppy write printout"
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
