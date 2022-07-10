#! /bin/bash
#
# Start WozMania either in text or graphic mode

grep -E "^gui[ \t]+disable" /etc/wozmania.conf
if [ $? -eq 0 ]; then
  wozmania
else
  wozmania &
  wozmania-gui
fi
