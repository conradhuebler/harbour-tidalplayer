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

#include <QtCore/QVector>
#include <QtCore/QtDebug>
#include <QtCore/QObject>
#include <QtCore/QFile>
#include <QtCore/QCoreApplication>
#include <QtCore/QJsonObject>

#include "playlistmanager.h"


void PlaylistManager::addTrackId(int trackId)
{
    m_current_track_ids << trackId;
    updatePlaylist();
}

void PlaylistManager::insertTrackId(int trackId)
{
    int index = m_current_track_ids.indexOf(m_current_track_id);
    m_current_track_ids.insert(index + 1, trackId);
    updatePlaylist();
}

void PlaylistManager::play()
{
    if(m_current_track_id < m_current_track_ids.size())
    {
        m_trackID = m_current_track_ids[m_current_track_id];
        emit currenTrackIDChanged();
    }else
        emit playlistFinished();
}

void PlaylistManager::playTrackId(int trackId)
{
    int index = m_current_track_ids.indexOf(m_current_track_id);
    m_current_track_ids.insert(index + 1, trackId);
    nextTrack();
    updatePlaylist();
}

void PlaylistManager::playTrack(int trackIndexFromPlaylist)
{
    m_current_track_id = trackIndexFromPlaylist - 1;
    nextTrack();
}

void PlaylistManager::nextTrack()
{
    qDebug() << m_current_track_id<<m_current_track_ids.size() <<m_current_track_id<<m_current_track_ids;
    if(m_current_track_id < m_current_track_ids.size())
    {
        m_trackID = m_current_track_ids[m_current_track_id];
        emit currenTrackIDChanged();
    }else
        emit playlistFinished();
    m_current_track_id++;
}

void PlaylistManager::prevTrack()
{
    m_current_track_id--;
    if(m_current_track_id > 0)
    {
        m_trackID = m_current_track_ids[m_current_track_id];
        emit currenTrackIDChanged();
    }else
        emit playlistFinished();
}

void PlaylistManager::updatePlaylist()
{
    m_track_ids.clear();
    m_track_ids = "[";
    for(auto i : m_current_track_ids)
        m_track_ids += QString("{\"id\":%1},").arg(i);
    m_track_ids.chop(1);
    m_track_ids += "]";
}
