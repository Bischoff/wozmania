#! /bin/bash

AS_OPTS=""
if [ "$DEBUG" != "" ]; then
  AS_OPTS="-g"
fi

as $AS_OPTS instructions.s -o instructions.o
as $AS_OPTS emulator.s -o emulator.o
ld instructions.o emulator.o -o emulator
rm instructions.o emulator.o
