#! /bin/bash
#
# Start WozMania either in a terminal or in a graphical user interface

grep -E "^gui[ \t]+disable" /etc/wozmania.conf
if [ $? -eq 0 ]; then
  wozmania
else
  wozmania &
  wozmania-gui
fi
