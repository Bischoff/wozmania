// WozMania Apple ][ emulator for ARM processor
// (c) Eric Bischoff 2021-2022
// Released under GPLv2 license
//
// GUI main window

#include "emulatorwindow.h"

#include <QTimerEvent>
#include <QLabel>
#include <QPainter>
#include <QPaintEvent>

#define FN "courier new" // font name
#define FS 13            // font size
#define BL 15            // font baseline
#define X0 10            // left margin
#define Y0 16            // top margin
#define DX 10            // column spacing
#define DY 18            // line spacing

// Constructor
EmulatorWindow::EmulatorWindow() :
  socket(this),
  data(&socket)
{
  setGeometry(100, 100,
              X0 + DX * 80 + 8, Y0 + DY * 24 + 8);
  setWindowTitle("WozMania 0.2");

  connect(&socket, SIGNAL(bytesWritten(qint64)), this, SLOT(bytesWritten(qint64)));
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
  n = n - (n % 4);
  if (n == 0) return;

  output = new char[n];
  data.readRawData(output, n);

  for (p = output;
       p + 4 <= output + n;
       p += 4)
  {
    short column = p[0] % 80, line = p[1] % 24;
    char fx = p[2], txt = p[3];

    effect[line][column] = fx;
    text[line][column] = txt;

    update(X0 + column * DX, Y0 + line * DY, DX, DY);
  }

  delete output;
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
  QByteArray input(event->text().toLatin1());

  data.writeRawData(input.constData(), input.length());
}
