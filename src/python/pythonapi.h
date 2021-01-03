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


#pragma once

#include <QQmlEngine>

#include <QtCore/QtDebug>
#include <QtCore/QObject>
#include <QtCore/QFile>
#include <QtCore/QCoreApplication>
#include <QtCore/QJsonObject>

// https://stackoverflow.com/questions/23068700/embedding-python3-in-qt-5 - thanks a lot :-)
#pragma push_macro("slots")
#undef slots
#include "Python.h"
#pragma pop_macro("slots")

class PythonApi : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(PythonApi)
    PythonApi() { }

    Q_PROPERTY(bool loginState MEMBER m_loginState NOTIFY loginStateChanged)
    Q_PROPERTY(QString trackResults MEMBER m_searchedTrackResults NOTIFY searchFinished)
    Q_PROPERTY(QString albumsResults MEMBER m_searchAlbumResults NOTIFY searchFinished)
    Q_PROPERTY(QString trackUrl MEMBER m_recent_track_url NOTIFY recentTrackUrlChanged)

public:
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine)
    {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine);

        bool autologin = qApp->property("autologin").toBool();
        QString login = qApp->property("login").toString();
        QString pwd = qApp->property("pwd").toString();
        PythonApi *api = new PythonApi;

        if(autologin)
            api->setLogin(login,pwd);

        qApp->setProperty("pwd", QString());

        return api;
    }

    enum JsonElements {
        Track = 1,
        Album = 2,
        Artist = 3,
        Playlist = 4
    };


    QString SearchedTracksResults() const { return m_searchedTrackResults; }
    QString SearchedAlbumsResults() const { return m_searchAlbumResults; }
    QString SearchedArtistsResults() const { return m_searchedArtistResults; }
    QString SearchedPlaylistsResults() const { return m_searchedPlaylistResults; }

    QString RecentTrackUrl() const { return m_recent_track_url;}
    QString RecentVideoUrl() const { return m_recent_video_url;}

private:
    bool m_loginState = false;
    PyObject *m_TidalInterface;
    QString m_login, m_passwort;
    QString m_recent_track_url, m_recent_video_url;
    QString m_searchedTrackResults, m_searchAlbumResults, m_searchedArtistResults, m_searchedPlaylistResults;

    PyObject * searchGeneric(const QString &search, const QString &section, int limit);

    QString CompileGenericResults(PyObject *searchResults, int type);

    inline QString CompileArtistResults(PyObject *searchResult) { return CompileGenericResults(searchResult, JsonElements::Artist); }
    inline QString CompileAlbumResults(PyObject *searchResult) { return CompileGenericResults(searchResult, JsonElements::Album); }
    inline QString CompilePlaylistResults(PyObject *searchResult) { return CompileGenericResults(searchResult, JsonElements::Playlist); }
    inline QString CompileTrackResults(PyObject *searchResult) { return CompileGenericResults(searchResult, JsonElements::Track); }

public slots:
    void setLogin(const QString &name, const QString &passwort);
    inline void setLoginState(bool login){ m_loginState = login; }

    void searchArtists(const QString &string, int limit = 50);
    void searchAlbums(const QString &string, int limit = 50);
    void searchPlaylists(const QString &search, int limit = 50);
    void searchTracks(const QString &search, int limit = 50);

    void getTrackUrl(int trackid);

signals:
    void loginStateChanged();
    void searchFinished();
    void recentTrackUrlChanged();
    void recentVideoUrlChanged();
};
