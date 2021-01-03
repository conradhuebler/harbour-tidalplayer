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

// https://stackoverflow.com/questions/23068700/embedding-python3-in-qt-5 - thanks a lot :-)
#pragma push_macro("slots")
#undef slots
#include "Python.h"
#pragma pop_macro("slots")

#include "pythonapi.h"

void PythonApi::setLogin(const QString &name, const QString &passwort)
{
    m_login = name;
    m_passwort = passwort;

    Py_Initialize();

    PyRun_SimpleString("import sys; sys.path.append('/usr/share/harbour-tidalplayer/python/')");

    PyObject* tidalstring = PyUnicode_FromString((char*)"tidalapi");
    PyObject* tidalmodule = PyImport_Import(tidalstring);
    m_TidalInterface = PyObject_CallMethod(tidalmodule, "Session", NULL);

    PyObject* loginFunction = PyObject_GetAttrString(m_TidalInterface,(char*)"login");
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
    }else
    {
        setLoginState(false);
    }
    emit loginStateChanged();
    Py_DECREF(loginResult);
}

void PythonApi::searchArtists(const QString &search, int limit)
{
    PyObject* searchResult = searchGeneric(search, QString("artist"), limit);
    PyObject* artist = PyObject_GetAttrString(searchResult,(char*)"artists");
    m_searchedArtistResults = (CompileArtistResults(artist));
    emit searchFinished();

    Py_DECREF(searchResult);
    Py_DECREF(artist);
}

void PythonApi::searchAlbums(const QString &search, int limit)
{
    PyObject* searchResult = searchGeneric(search, QString("album"), limit);
    PyObject* album = PyObject_GetAttrString(searchResult,(char*)"albums");
    m_searchAlbumResults = (CompileAlbumResults(album));
    emit searchFinished();

    Py_DECREF(searchResult);
    Py_DECREF(album);
}

void PythonApi::searchPlaylists(const QString &search, int limit)
{
    PyObject* searchResult = searchGeneric(search, QString("playlist"), limit);
    PyObject* playlist = PyObject_GetAttrString(searchResult,(char*)"playlists");
    m_searchedPlaylistResults = (CompilePlaylistResults(playlist));
    emit searchFinished();

    Py_DECREF(searchResult);
    Py_DECREF(playlist);
}


void PythonApi::searchTracks(const QString &search, int limit)
{
    PyObject* searchResult = searchGeneric(search, QString("track"), limit);
    PyObject* track = PyObject_GetAttrString(searchResult,(char*)"tracks");
    m_searchedTrackResults = (CompileTrackResults(track));
    emit searchFinished();

    Py_DECREF(searchResult);
    Py_DECREF(track);
}

/*
    qDebug() << search << limit;
    if(!m_loginState)
        qDebug() << "no login at all?";


    PyObject* myFunction = PyObject_GetAttrString(m_TidalInterface,(char*)"search");

    PyErr_Print();
    qDebug() << "";

    PyObject* args = PyTuple_Pack(3,PyUnicode_FromString(QString("artist").toLocal8Bit()), PyUnicode_FromString((search.toLocal8Bit())), PyLong_FromDouble(limit));
    PyErr_Print();
    qDebug() << "";

    PyObject* SearchResult = PyObject_CallObject(myFunction, args);
    PyErr_Print();
    qDebug() << "";

    PyObject* artist = PyObject_GetAttrString(SearchResult,(char*)"artists");
    PyErr_Print();
    qDebug() << "";

    qDebug() << PyList_Size(artist);
    for(Py_ssize_t i = 0; i < PyList_Size(artist); ++i)
    {
       PyObject *item = PyList_GetItem(artist, i);
       PyObject* idx = PyObject_GetAttrString(item,(char*)"id");
       PyErr_Print();

       PyObject* name = PyObject_GetAttrString(item,(char*)"name");
       PyErr_Print();

       int index = PyLong_AsDouble(idx);
       PyObject* str = PyUnicode_AsEncodedString(name, "utf-8", "~E~");
       QString name_string = QString::fromUtf8(PyUnicode_AsUTF8(name));
       qDebug() << name_string << index;
       Py_DECREF(item);
       Py_DECREF(idx);
       Py_DECREF(name);
       Py_DECREF(str);
    }
    */


PyObject *  PythonApi::searchGeneric(const QString &search, const QString &section, int limit)
{
    PyObject* searchFunction = PyObject_GetAttrString(m_TidalInterface,(char*)"search");
    PyObject* searchArguments = PyTuple_Pack(3,PyUnicode_FromString(section.toLocal8Bit()), PyUnicode_FromString((search.toLocal8Bit())), PyLong_FromDouble(limit));
    PyObject* SearchResult = PyObject_CallObject(searchFunction, searchArguments);

    /*
    PyObject* artist = PyObject_GetAttrString(SearchResult,(char*)"artists");
    PyObject* albums = PyObject_GetAttrString(SearchResult,(char*)"albums");
    PyObject* playlist = PyObject_GetAttrString(SearchResult,(char*)"playlists");
    PyObject* tracks = PyObject_GetAttrString(SearchResult,(char*)"tracks");
    */


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
        /*
       QJsonObject element;
       element["id"] = index;
       element["name"] = name_string;
       element["type"] = type;
       */
        //result[QString::number(i)] = element;
        // qDebug() << index << name_string << type;
        Py_DECREF(item);
        Py_DECREF(idx);
        Py_DECREF(name);
    }
    result.chop(1);
    result += "]";
    // qDebug() << result;
    return result;
}

void PythonApi::getTrackUrl(int trackid)
{
    PyObject* trackUrlFunction = PyObject_GetAttrString(m_TidalInterface,(char*)"get_track_url");
    PyObject* trackUrlArguments = PyTuple_Pack(1, PyLong_FromDouble(trackid));
    PyObject* urlResults = PyObject_CallObject(trackUrlFunction, trackUrlArguments);
    m_recent_track_url = QString::fromUtf8(PyUnicode_AsUTF8(urlResults));
    // qDebug() << m_recent_track_url;
    emit recentTrackUrlChanged();

    Py_DECREF(trackUrlFunction);
    Py_DECREF(trackUrlArguments);
    Py_DECREF(urlResults);
}
