// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// GUI main window - declarations

#ifndef EmulatorWindow_H
#define EmulatorWindow_H

#include <QWidget>
#include <QtNetwork/QLocalSocket>

class EmulatorWindow : public QWidget
{
  Q_OBJECT

  private:
    QLocalSocket socket;
    QDataStream data;
    char effect[24][80],
         text[24][80];

  public slots:
    void readyRead();

  public:
    EmulatorWindow();
    ~EmulatorWindow();
    virtual void paintEvent(QPaintEvent *event);
    virtual void keyPressEvent(QKeyEvent *event);
};

#endif
