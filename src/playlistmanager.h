/*
 * Copyright (C) 2021 Conrad Hübler <Conrad.Huebler@gmx.net>
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

class PlaylistManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int trackID MEMBER m_trackID)
    Q_PROPERTY(int videoID MEMBER m_videoID)
    Q_PROPERTY(QString trackNames MEMBER m_track_names)
    Q_PROPERTY(QString trackIds MEMBER m_track_ids)

    Q_PROPERTY(bool keepTrack MEMBER m_keep_current_track)
    Q_PROPERTY(int currentTrackIndex MEMBER m_current_track_index)
    Q_DISABLE_COPY(PlaylistManager)
    PlaylistManager() { }

public:
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine)
    {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine);
        PlaylistManager *playlist = new PlaylistManager;
        return playlist;
    }

    Q_INVOKABLE bool canNext() const {
      return m_current_track_index < m_current_track_ids.size() - 1;
    }

    Q_INVOKABLE bool canPrev() const { return m_current_track_index > 0; }

  public slots:
    /* add track to the end of the playlist */
    void addTrackId(int trackId);

    /* add track to be the next in the playlist */
    void insertTrackId(int trackId);

    /* stop current track and play this one */
    void playTrackId(int trackId);
    void playTrack(int trackIndexFromPlaylist);


    /* play next track from playlist */
    Q_INVOKABLE void nextTrack();

    /* play previouse track from playlist */
    Q_INVOKABLE void prevTrack();


    Q_INVOKABLE void play();

    Q_INVOKABLE void clear();

  signals:
    void currenTrackIDChanged();
    void currentTrackInfoChanged();
    void currentVideoIDChanged();
    void playlistChanged();
    void playlistFinished();

    void currentTrackChanged();
private:
    void updatePlaylist();

    QString  m_track_ids = QString(), m_track_names = QString();
    QVector<int> m_current_track_ids;
    int m_current_track_index = 0, m_trackID = 0, m_videoID = 0;
    bool m_keep_current_track = false;
};

