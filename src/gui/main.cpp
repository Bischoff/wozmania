// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// GUI interface main program

#include "emulatorwindow.h"

#include <QApplication>

int main(int argc, char **argv)
{
  QApplication app(argc, argv);

  EmulatorWindow window;
  window.show();

  return app.exec();
}
