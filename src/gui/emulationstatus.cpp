// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// GUI status bar

#include "emulationstatus.h"
#include "emulatorwindow.h"

#include <QStatusBar>
#include <QLabel>

// Constructor
EmulationStatus::EmulationStatus(EmulatorWindow *emulatorWindow)
{
  QStatusBar *statusBar = emulatorWindow->statusBar();
  QPixmap pix(6, 6);
  QLabel *name1, *name2;

  pix.fill(Qt::green);

  name1 = new QLabel("D1");
  statusBar->addPermanentWidget(name1);

  led1 = new QLabel;
  led1->setPixmap(pix);
  statusBar->addPermanentWidget(led1);

  name2 = new QLabel("D2");
  statusBar->addPermanentWidget(name2);

  led2 = new QLabel;
  led2->setPixmap(pix);
  statusBar->addPermanentWidget(led2);
}

// Change color of leds
void EmulationStatus::leds(char drive, char dirty) const
{
  QPixmap pix(6, 6);

  pix.fill(dirty == '1'? Qt::red: Qt::green);

  (drive == '1'? led1: led2)->setPixmap(pix);
}
