TEMPLATE = app
TARGET = wozmania-gui
target.path = /usr/bin

QT = core gui widgets network

HEADERS += emulatorwindow.h
SOURCES += main.cpp emulatorwindow.cpp
INSTALLS += target
