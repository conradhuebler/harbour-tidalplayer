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

#include <QQmlEngine>

#include <QtCore/QtDebug>
#include <QtCore/QObject>
#include <QtCore/QFile>
#include <QtCore/QCoreApplication>
#include <QtCore/QJsonObject>
#include <QtCore/QSettings>

#include "src/cachemanager.h"

static const QString LOGIN_GROUP     {QStringLiteral("LoginGroup")};
static const QString SESSION     {QStringLiteral("SESSION")};

// https://stackoverflow.com/questions/23068700/embedding-python3-in-qt-5 - thanks a lot :-)
#pragma push_macro("slots")
#undef slots
#include "Python.h"
#pragma pop_macro("slots")

#include "pythonapi.h"

#define debugPrint() PyErr_Print();qDebug() << "";


void PythonApi::setLogin(const QString &name, const QString &passwort)
{
    m_login = name;
    m_passwort = passwort;

    Py_Initialize();
    PyEval_InitThreads();
    PyRun_SimpleString("import sys; sys.path.append('/usr/share/harbour-tidalplayer/python/')");


    QSettings settings;
    settings.beginGroup(LOGIN_GROUP);
    QString session = settings.value(SESSION).toString();
    bool check_session = CheckSession(session);

    if(check_session)
    {
        m_session_id = session;
        setLoginState(true);
        emit loginStateChanged();
        return;
    }


    PyObject* tidalstring = PyUnicode_FromString((char*)"tidalapi");
    PyObject* tidalmodule = PyImport_Import(tidalstring);
    PyObject* TidalInterface = PyObject_CallMethod(tidalmodule, "Session", NULL);

    PyObject* loginFunction = PyObject_GetAttrString(TidalInterface,(char*)"login");
    //    PyErr_Print();
    //    qDebug() << "";

    PyObject* loginArgs = PyTuple_Pack(2,PyUnicode_FromString((m_login.toLocal8Bit())), PyUnicode_FromString((m_passwort.toLocal8Bit())));
    //    PyErr_Print();
    //    qDebug() << "";


    Py_DECREF(tidalstring);
    Py_DECREF(tidalmodule);

    PyObject* loginResult = PyObject_CallObject(loginFunction, loginArgs);
    //    PyErr_Print();
    //    qDebug() << "";

    Py_DECREF(loginFunction);
    Py_DECREF(loginArgs);

    if(loginResult == NULL)
    {
        setLoginState(false);
        emit loginStateChanged();
        qDebug() << "";

        return;
    }

    int truthy = PyObject_IsTrue(loginResult);
    if(truthy == 1)
    {
        setLoginState(true);
        m_session_id = getAttribute(TidalInterface, "session_id");
        QSettings settings;
        settings.beginGroup(LOGIN_GROUP);
        settings.setValue(SESSION, m_session_id);

    }else
    {
        setLoginState(false);
    }
    emit loginStateChanged();
    Py_DECREF(loginResult);
}

PyObject * PythonApi::Session() const
{
    PyObject* tidalstring = PyUnicode_FromString((char*)"tidalapi");
    PyObject* tidalmodule = PyImport_Import(tidalstring);
    PyObject* TidalInterface = PyObject_CallMethod(tidalmodule, "Session", NULL);
    PyObject* loginFunction = PyObject_GetAttrString(TidalInterface,(char*)"load_session");
    PyObject* loginArgs = PyTuple_Pack(1,PyUnicode_FromString((m_session_id.toLocal8Bit())));
    PyObject* loginResult = PyObject_CallObject(loginFunction, loginArgs);

    Py_DECREF(tidalstring);
    Py_DECREF(tidalmodule);
    Py_DECREF(loginFunction);
    Py_DECREF(loginArgs);
    Py_DECREF(loginResult);

   return TidalInterface;
}

bool PythonApi::CheckSession(const QString &session)
{
    if(session.isEmpty() || session.isNull())
        return false;

    PyObject* tidalstring = PyUnicode_FromString((char*)"tidalapi");

    PyObject* tidalmodule = PyImport_Import(tidalstring);

    PyObject* TidalInterface = PyObject_CallMethod(tidalmodule, "Session", NULL);

    PyObject* loginFunction = PyObject_GetAttrString(TidalInterface,(char*)"load_session");

    PyObject* loginArgs = PyTuple_Pack(1,PyUnicode_FromString((session.toLocal8Bit())));

    PyObject* loginResult = PyObject_CallObject(loginFunction, loginArgs);


    PyObject* checkFunction = PyObject_GetAttrString(TidalInterface,(char*)"check_login");
    bool result = false;
    if(checkFunction == NULL)
    {

        Py_DECREF(tidalstring);
        Py_DECREF(tidalmodule);
        Py_DECREF(loginFunction);
        Py_DECREF(loginArgs);
        Py_DECREF(loginResult);
        return false;
    }

    int truthy = PyObject_IsTrue(checkFunction);
    if(truthy == 1)
    {
        result = true;
    }

    Py_DECREF(tidalstring);
    Py_DECREF(tidalmodule);
    Py_DECREF(loginFunction);
    Py_DECREF(loginArgs);
    Py_DECREF(loginResult);
    Py_DECREF(checkFunction);

    return result;
}

QString PythonApi::PythonApi::CompileArtist(PyObject *item) {
  QString artistInfo = QString("{\"name\":\"%2\" ,"
                               "\"image\": \"%3\" ,"
                               "\"id\":%7 }")
                           .arg(getAttribute(item, "name"))
                           .arg(getAttribute(item, "image"))
                           .arg(getAttribute(item, "id"));

  int artistid = getAttribute(item, "id").toInt();
  if (!m_cached_artists.contains(artistid))
    m_cached_artists.insert(artistid, artistInfo);

  return artistInfo;
}

QString PythonApi::CompileAlbum(PyObject *item) {
  QString albumInfo = QString("{ \"artist\":\"%1\" ,"
                              "\"duration\":\"%2\" ,"
                              "\"image\": \"%3\" ,"
                              "\"name\": \"%4\" ,"
                              "\"num_tracks\":\"%5\","
                              "\"relase\":\"%6\","
                              "\"id\":%7 }")
                          .arg(getAttribute(item, "artist.name"))
                          .arg(getAttribute(item, "duration"))
                          .arg(getAttribute(item, "image"))
                          .arg(getAttribute(item, "name"))
                          .arg(getAttribute(item, "num_tracks"))
                          .arg(getAttribute(item, "release_date"))
                          .arg(getAttribute(item, "id"));

  int albumid = getAttribute(item, "id").toInt();
  if (!m_cached_albums.contains(albumid))
    m_cached_albums.insert(albumid, albumInfo);

  return albumInfo;
}

QString PythonApi::CompileTrack(PyObject *item) {
  QString trackInfo = QString("{ \"album\":\"%1\" ,"
                              "\"albumid\":%2 ,"
                              "\"artist\":\"%3\" ,"
                              "\"artistid\":%4 ,"
                              "\"disc_num\": %5 ,"
                              "\"name\":\"%6\","
                              "\"image\":\"%7\","
                              "\"track_num\":%8,"
                              "\"id\":%9 }")
                          .arg(getAttribute(item, "album.name"))
                          .arg(getAttribute(item, "album.id"))
                          .arg(getAttribute(item, "artist.name"))
                          .arg(getAttribute(item, "artist.id"))
                          .arg(getAttribute(item, "disc_num"))
                          .arg(getAttribute(item, "name"))
                          .arg(getAttribute(item, "album.image"))
                          .arg(getAttribute(item, "track_num"))
                          .arg(getAttribute(item, "id"));

  int trackid = getAttribute(item, "id").toInt();
  if (!m_cached_tracks.contains(trackid))
    m_cached_tracks.insert(trackid, trackInfo);

  return trackInfo;
}

QString PythonApi::fetchTrackInfo(int trackid)
{
  if (m_cached_tracks.contains(trackid))
    return m_cached_tracks[trackid];

  PyObject *tidalInterface = Session();
  PyObject *trackUrlFunction =
      PyObject_GetAttrString(tidalInterface, (char *)"get_track");
  PyObject *id = PyLong_FromDouble(trackid);

  PyObject *trackUrlArguments = PyTuple_Pack(1, id);

  PyObject *trackResult =
      PyObject_CallObject(trackUrlFunction, trackUrlArguments);

  QString trackInfo = CompileTrack(trackResult);
  /*QString("{ \"album\":\"%1\" ,"
                               "\"albumid\":%2 ,"
                               "\"artist\":\"%3\" ,"
                               "\"artistid\":%4 ,"
                               "\"disc_num\": %5 ,"
                               "\"name\":\"%6\","
                               "\"cover\":\"%7\","
                               "\"track_num\":%8,"
                               "\"id\":%9 }"
                               )
          .arg(getAttribute(trackResult, "album.name"))
          .arg(getAttribute(trackResult, "album.id"))
          .arg(getAttribute(trackResult, "artist.name"))
          .arg(getAttribute(trackResult, "artist.id"))
          .arg(getAttribute(trackResult, "disc_num"))
          .arg(getAttribute(trackResult, "name"))
          .arg(getAttribute(trackResult, "album.image"))
          .arg(getAttribute(trackResult, "track_num"))
          .arg(trackid);
  */

  Py_DECREF(trackUrlFunction);
  Py_DECREF(id);
  Py_DECREF(trackUrlArguments);
  Py_DECREF(trackResult);
  Py_DECREF(tidalInterface);
  // m_cached_tracks.insert(trackid, trackInfo);
  return trackInfo;
}


QString PythonApi::fetchAlbumInfo(int albumid)
{
  if (m_cached_albums.contains(albumid))
    return m_cached_albums[albumid];

  PyObject *tidalInterface = Session();
  debugPrint();

  PyObject *trackUrlFunction =
      PyObject_GetAttrString(tidalInterface, (char *)"get_album");
  debugPrint();

  PyObject *trackUrlArguments = PyTuple_Pack(1, PyLong_FromDouble(albumid));
  debugPrint();

  PyObject *albumResult =
      PyObject_CallObject(trackUrlFunction, trackUrlArguments);
  debugPrint();

  QString albumInfo = CompileAlbum(albumResult);
  /*
  QString albumInfo =  QString("{ \"artist\":\"%1\" ,"
                               "\"duration\":\"%2\" ,"
                               "\"cover\": \"%3\" ,"
                               "\"name\": \"%4\" ,"
                               "\"num_tracks\":\"%5\","
                               "\"relase\":\"%6\","
                               "\"id\":%7 }")
          .arg(getAttribute(trackResult, "artist.name"))
          .arg(getAttribute(trackResult, "duration"))
          .arg(getAttribute(trackResult, "image"))
          .arg(getAttribute(trackResult, "name"))
          .arg(getAttribute(trackResult, "num_tracks"))
          .arg(getAttribute(trackResult, "release_date"))
          .arg(albumid);

  qDebug() << albumInfo;
  */
  Py_DECREF(trackUrlFunction);
  Py_DECREF(trackUrlArguments);
  Py_DECREF(albumResult);
  Py_DECREF(tidalInterface);
  // m_cached_albums.insert(albumid, albumInfo);

  return albumInfo;
}


QString PythonApi::fetchArtistInfo(int artistid)
{
  if (m_cached_artists.contains(artistid))
    return m_cached_artists[artistid];

  PyObject *tidalInterface = Session();
  PyObject *trackUrlFunction =
      PyObject_GetAttrString(tidalInterface, (char *)"get_artist");

  PyObject *trackUrlArguments = PyTuple_Pack(1, PyLong_FromDouble(artistid));

  PyObject *result = PyObject_CallObject(trackUrlFunction, trackUrlArguments);

  QString artistInfo = CompileArtist(result);
  /*QString("{ \"artist\":\"%1\" ,"
                                "\"name\":\"%2\" ,"
                                "\"cover\": \"%3\" ,"
                                "\"disc_num\": %4 ,"
                                "\"num_tracks\":%5,"
                                "\"relase\":\"%6\","
                                "\"id\":%7 }")
          .arg(getAttribute(trackResult, "name"))
          .arg(getAttribute(trackResult, "image"))
          .arg(getAttribute(trackResult, "image"))
          .arg(getAttribute(trackResult, "disc_num"))
          .arg(getAttribute(trackResult, "num_tracks"))
          .arg(getAttribute(trackResult, "release_date"))
          .arg(artistid);
*/
  Py_DECREF(trackUrlFunction);
  Py_DECREF(trackUrlArguments);
  Py_DECREF(result);
  Py_DECREF(tidalInterface);
  // m_cached_artists.insert(artistid, artistInfo);

  return artistInfo;
}


void PythonApi::searchArtists(const QString &search, int limit)
{
    PyObject* searchResult = searchGeneric(search, QString("artist"), limit);
    PyObject* artist = PyObject_GetAttrString(searchResult,(char*)"artists");
    m_searchedArtistResults = CompileArtistResults(artist);

    emit artistSearchFinished();

    Py_DECREF(searchResult);
    Py_DECREF(artist);
}

void PythonApi::searchAlbums(const QString &search, int limit)
{
    PyObject* searchResult = searchGeneric(search, QString("album"), limit);
    PyObject* album = PyObject_GetAttrString(searchResult,(char*)"albums");
    m_searchAlbumResults = CompileAlbumResults(album);
    emit albumSearchFinished();

    Py_DECREF(searchResult);
    Py_DECREF(album);
}

void PythonApi::searchPlaylists(const QString &search, int limit)
{
    PyObject* searchResult = searchGeneric(search, QString("playlist"), limit);
    PyObject* playlist = PyObject_GetAttrString(searchResult,(char*)"playlists");
    m_searchedPlaylistResults = CompilePlaylistResults(playlist);
    emit playlistSearchFinished();

    Py_DECREF(searchResult);
    Py_DECREF(playlist);
}


void PythonApi::searchTracks(const QString &search, int limit)
{
    PyObject* searchResult = searchGeneric(search, QString("track"), limit);
    PyObject* track = PyObject_GetAttrString(searchResult,(char*)"tracks");
    m_searchedTrackResults = CompileTrackResults(track);
    emit trackSearchFinished();

    Py_DECREF(searchResult);
    Py_DECREF(track);
}

PyObject * PythonApi::searchGeneric(const QString &search, const QString &section, int limit)
{
    PyObject * tidalInterface = Session();
    PyObject* searchFunction = PyObject_GetAttrString(tidalInterface,(char*)"search");
    PyObject* searchArguments = PyTuple_Pack(3,PyUnicode_FromString(section.toLocal8Bit()), PyUnicode_FromString((search.toLocal8Bit())), PyLong_FromDouble(limit));
    PyObject* SearchResult = PyObject_CallObject(searchFunction, searchArguments);

    Py_DECREF(searchFunction);
    Py_DECREF(searchArguments);
    Py_DECREF(tidalInterface);

    return SearchResult;
}

QString PythonApi::CompileGenericResults(PyObject *SearchResult, int type)
{
    QString result = "[";
    for(Py_ssize_t i = 0; i < PyList_Size(SearchResult); ++i)
    {
        PyObject *item = PyList_GetItem(SearchResult, i);
        PyObject* idx = PyObject_GetAttrString(item,(char*)"id");
        PyObject* name = PyObject_GetAttrString(item,(char*)"name");

        int index = PyLong_AsDouble(idx);
        QString name_string = QString::fromUtf8(PyUnicode_AsUTF8(name)).replace('"','*');
        QString element = QString("{ \"name\":\"%1\", \"id\":%2, \"type\":%3}").arg(name_string).arg(index).arg(type);
        result += QString("%1,").arg(element);

        Py_DECREF(item);
        Py_DECREF(idx);
        Py_DECREF(name);
    }
    result.chop(1);
    result += "]";
    return result;
}

void PythonApi::getTrackUrl(int trackid)
{
    PyObject * tidalInterface = Session();
    PyObject* trackUrlFunction = PyObject_GetAttrString(tidalInterface,(char*)"get_track_url");
    if(trackUrlFunction == NULL)
    {
        m_last_error = QString("strange error");
    }
    PyObject* trackUrlArguments = PyTuple_Pack(1, PyLong_FromDouble(trackid));

    PyObject* urlResults = PyObject_CallObject(trackUrlFunction, trackUrlArguments);
    if(urlResults == NULL)
    {
        m_last_error = QString("Could not find track url!");
        Py_DECREF(trackUrlFunction);
        Py_DECREF(trackUrlArguments);
        emit error();
        return;
    }
    m_recent_track_url = QString::fromUtf8(PyUnicode_AsUTF8(urlResults));

    emit recentTrackUrlChanged();

    Py_DECREF(trackUrlFunction);
    Py_DECREF(trackUrlArguments);
    Py_DECREF(urlResults);
}

QString PythonApi::getAttribute(PyObject *object, const QString &attribute)
{
    if(attribute.contains("."))
    {
        QStringList split = attribute.split(".");
        PyObject* attr = PyObject_GetAttrString(object,((split[0].toLocal8Bit().data())));
        if(attr == NULL)
        {
            return QString();
        }
        QString result = getAttribute(attr, split[1]);
        Py_DECREF(attr);
        return result;
    }
    PyObject* attr = PyObject_GetAttrString(object,((attribute.toLocal8Bit().data())));
    if(attr == NULL)
    {
        return QString();
    }
    QString result = QString::fromUtf8(PyUnicode_AsUTF8(attr)).replace('"','*');
    if(result.isEmpty())
        result = QString::number(PyLong_AsLong(attr));
    Py_DECREF(attr);

    return result;
}

QString PythonApi::invokeTrackInfo(int trackid)
{
    return fetchTrackInfo(trackid);
}
/*
QString PythonApi::invokeTrackInfo(const QString &str)
{
    return fetchTrackInfo(str.toInt());
}
*/
void PythonApi::getPlayingTrackInfo(int trackid)
{
    m_PlayingTrackInfo = fetchTrackInfo(trackid);
    emit playingTrackInfoChanged();
}

void PythonApi::getTrackInfo(int trackid)
{
    QCoreApplication::processEvents();
    m_TrackInfo = fetchTrackInfo(trackid);
    emit trackInfoChanged();
}

void PythonApi::getPlayingAlbumInfo(int albumid)
{
    m_PlayingAlbumInfo = fetchAlbumInfo(albumid);
    emit playingAlbumInfoChanged();
}

void PythonApi::getAlbumInfo(int albumid)
{
    qDebug() << albumid;
    m_AlbumInfo = fetchAlbumInfo(albumid);
    emit albumInfoChanged();
}

void PythonApi::getArtistInfo(int artistid)
{
    m_ArtistInfo = fetchArtistInfo(artistid);
    emit artistInfoChanged();
}

void PythonApi::getPlayingArtistInfo(int artistid)
{
    m_PlayingArtistInfo = fetchArtistInfo(artistid);
    emit playingArtistInfoChanged();
}

QString PythonApi::fetchTracksfromAlbum(int albumId)
{
    PyObject * tidalInterface = Session();
    PyObject* trackUrlFunction = PyObject_GetAttrString(tidalInterface,(char*)"get_album_tracks");
    if(trackUrlFunction == NULL)
    {
        m_last_error = QString("strange error");
    }
    PyObject* trackUrlArguments = PyTuple_Pack(1, PyLong_FromDouble(albumId));

    PyObject* SearchResult = PyObject_CallObject(trackUrlFunction, trackUrlArguments);

    QString result = "[";
    for(Py_ssize_t i = 0; i < PyList_Size(SearchResult); ++i)
    {
        PyObject *item = PyList_GetItem(SearchResult, i);
        result += QString("%1,").arg(CompileTrack(item));

        Py_DECREF(item);
        // Py_DECREF(idx);
        // Py_DECREF(name);
    }
    result.chop(1);
    result += "]";


    Py_DECREF(tidalInterface);
    Py_DECREF(trackUrlFunction);
    Py_DECREF(trackUrlArguments);
    Py_DECREF(SearchResult);

    return result;
}
