// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// GUI main window

#include "emulatorwindow.h"

#include <QMenuBar>
#include <QMenu>
#include <QAction>
#include <QPainter>
#include <QPaintEvent>

// Parse output from emulator
void EmulatorWindow::parseOutput(char out)
{
  switch (state)
  {
    case state_begin:
      if (out == 'T') state = state_x;
      else if (out == 'S') state = state_drive;
      break;
    case state_x:
      column = out % 80;
      state = state_y;
      break;
    case state_y:
      line = out % 24;
      state = state_fx;
      break;
    case state_fx:
      effect[line][column] = out;
      state = state_txt;
      break;
    case state_txt:
      text[line][column] = out;
      update(X0 + column * DX, Y0 + line * DY, DX, DY);
      state = state_begin;
      break;
    case state_drive:
      drive = out;
      state = state_dirty;
      break;
    case state_dirty:
      emulationStatus.leds(drive, out);
      state = state_begin;
      break;
  }
}

// Constructor
EmulatorWindow::EmulatorWindow() :
  QMainWindow(),
  emulationStatus(this),
  socket(this),
  data(&socket),
  state(state_begin)
{
  QAction *action;
  QMenu *menu;

  setGeometry(100, 100,
              X0 + DX * 80 + 8, Y0 + DY * 24 + 24);
  setWindowTitle("WozMania 0.2");

  menu = menuBar()->addMenu("&Power");
  action = new QAction("&Off", this);
  action->setStatusTip("Turn computer off");
  connect(action, &QAction::triggered, this, &EmulatorWindow::powerOff);
  menu->addAction(action);

  menu = menuBar()->addMenu("&Floppy");
  action = new QAction("F&lush", this);
  action->setStatusTip("Flush current disk");
  connect(action, &QAction::triggered, this, &EmulatorWindow::flushDrive);
  menu->addAction(action);

  menu = menuBar()->addMenu("&Keyboard");
  action = new QAction("&Ctrl-Reset", this);
  action->setStatusTip("Press Ctrl-Reset");
  connect(action, &QAction::triggered, this, &EmulatorWindow::ctrlReset);
  menu->addAction(action);

  connect(&socket, SIGNAL(readyRead()), this, SLOT(readyRead()));
  printf("Connecting to emulator...\n");
  socket.connectToServer("/tmp/wozmania.sock");
  if (!socket.waitForConnected(-1))
  {
    fprintf(stderr, "Error: %s\n", (const char *) socket.errorString().toLatin1());
    exit(1);
  }

  for (short line = 0; line < 24; line++)
  {
    for (short column = 0; column < 80; column++)
    {
      effect[line][column] = '0';
      text[line][column] = ' ';
    }
  }
}

// Destructor
EmulatorWindow::~EmulatorWindow()
{
  socket.disconnectFromServer();
}

// Store bytes received from emulator
void EmulatorWindow::readyRead()
{
  char *output;
  int n;
  const char *p;

  n = socket.bytesAvailable();
  if (n == 0) return;

  output = new char[n];
  data.readRawData(output, n);

  for (p = output; p < output + n; p++)
    parseOutput(*p);

  delete output;
}

// Power off
void EmulatorWindow::powerOff()
{
  close();
}

// Flush current disk
void EmulatorWindow::flushDrive()
{
  data.writeRawData("\eF", 2);
}

// Press Ctrl-Reset
void EmulatorWindow::ctrlReset()
{
  data.writeRawData("\eR", 2);
}

// Refresh window contents
void EmulatorWindow::paintEvent(QPaintEvent *event)
{
  QPainter painter(this);
  QFont fixed(FN, FS);
  QRect refreshed(event->rect());
  short cmin = (refreshed.left() - X0) / DX,
	cmax = (refreshed.right() - X0 + DX - 1) / DX,
	lmin = (refreshed.top() - Y0) / DY,
	lmax = (refreshed.bottom() - Y0 + DY - 1) / DY;

  if (cmin < 0) cmin = 0;
  if (cmax > 80) cmax = 80;
  if (lmin < 0) lmin = 0;
  if (lmax > 24) lmax = 24;

  painter.setFont(fixed);
  painter.setBackgroundMode(Qt::OpaqueMode);
  for (short line = lmin; line < lmax; line++)
  {
    for (short column = cmin; column < cmax; column++)
    {
      if (effect[line][column] == '0')
      {
        painter.setBackground(Qt::black);
	painter.setPen(Qt::white);
      }
      else
      {
	painter.setBackground(Qt::white);
	painter.setPen(Qt::black);
      }
      painter.drawText
        (X0 + column * DX, Y0 + BL + line * DY,
         QString(text[line][column])
        );
    }
  }
}

// Send pressed key to emulator
void EmulatorWindow::keyPressEvent(QKeyEvent *event)
{

  if (event->key() == Qt::Key_Escape)
  {
    data.writeRawData("\e\e", 2);
  }
  else
  {
    QByteArray input(event->text().toLatin1());

    data.writeRawData(input.constData(), input.length());
  }
}

// Application quits
void EmulatorWindow::closeEvent(QCloseEvent *event)
{
Q_UNUSED(event);
  data.writeRawData("\eO", 2);
}
