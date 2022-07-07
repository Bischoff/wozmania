// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// GUI main window - declarations

#ifndef EmulatorWindow_H
#define EmulatorWindow_H

#include "emulationstatus.h"

#include <QMainWindow>
#include <QtNetwork/QLocalSocket>
#include <QDataStream>

#define FN "courier new" // font name
#define FS 13            // font size
#define BL 15            // font baseline
#define X0 10            // left margin
#define Y0 28            // top margin
#define DX 10            // column spacing
#define DY 18            // line spacing

class EmulatorWindow : public QMainWindow
{
  Q_OBJECT

  private:
    EmulationStatus emulationStatus;
    QLocalSocket socket;
    QDataStream data;
    enum
    { state_begin,
      state_message,
      state_drive, state_dirty,
      state_x, state_y, state_fx, state_txt
    } state;
    char message[128], *message_p;
    short drive,
	  column, line;
    char effect[24][80],
         text[24][80];

    void parseOutput(char c);

  private slots:
    void readyRead();
    void powerOff();
    void flushDrive();
    void ctrlReset();

  public:
    EmulatorWindow();
    ~EmulatorWindow();
    virtual void paintEvent(QPaintEvent *event);
    virtual void keyPressEvent(QKeyEvent *event);
    virtual void closeEvent(QCloseEvent *event);
};

#endif
