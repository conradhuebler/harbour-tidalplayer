/*
 * Copyright (C) 2020 Conrad Hübler <Conrad.Huebler@gmx.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */


#include <QtCore/QScopedPointer>
#include <QtCore/QDebug>

#include <QQmlEngine>
#include <QtQuick>

#include "settings/settings.h"

#include "python/pythonapi.h"

#include "playlistmanager.h"

#include <sailfishapp.h>

int main(int argc, char *argv[])
{
  // Some more speed & memory improvements
  setenv("QT_NO_FAST_MOVE", "0", 0);
  setenv("QT_NO_FT_CACHE", "0", 0);
  setenv("QT_NO_FAST_SCROLL", "0", 0);
  setenv("QT_NO_ANTIALIASING", "1", 1);
  setenv("QT_NO_FREE", "0", 0);
  setenv("QT_PREDICT_FUTURE", "1", 1);
  setenv("QT_NO_BUG", "1", 1);
  setenv("QT_NO_QT", "1", 1);
  // Taken from sailfish-browser
  setenv("USE_ASYNC", "1", 1);
  QQuickWindow::setDefaultAlphaBuffer(true);

  QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

  QScopedPointer<QQuickView> v(SailfishApp::createView());

  qmlRegisterSingletonType<Settings>("harbour.tidalplayer", 1, 0, "Settings",
                                     &Settings::qmlInstance);
  qmlRegisterSingletonType<PythonApi>("harbour.tidalplayer", 1, 0, "PythonApi",
                                      &PythonApi::qmlInstance);
  qmlRegisterSingletonType<PythonApi>("harbour.tidalplayer", 1, 0,
                                      "PlaylistManager",
                                      &PlaylistManager::qmlInstance);

  v->setSource(SailfishApp::pathTo("qml/harbour-tidalplayer.qml"));
  v->show();
  return app->exec();
}
