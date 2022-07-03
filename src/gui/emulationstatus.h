// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// GUI status bar - declarations

#ifndef EmulationStatus_H
#define EmulationStatus_H

class EmulatorWindow;
class QLabel;

class EmulationStatus
{
  private:
    QLabel *led1, *led2;

  public:
    EmulationStatus(EmulatorWindow *emulatorWindow);
    void leds(short drive, short dirty) const;
};

#endif
