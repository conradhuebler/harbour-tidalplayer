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

class Settings: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString loginname MEMBER m_loginname READ LoginName WRITE setLoginName NOTIFY loginNameChanged)
    Q_PROPERTY(QString loginpasswort MEMBER m_loginpasswort READ LoginPasswort WRITE setLoginPasswort NOTIFY loginPasswortChanged)
    Q_PROPERTY(bool saveLogin MEMBER m_save_login READ SaveLogin NOTIFY saveLoginChanged)
    Q_PROPERTY(int savePasswort MEMBER m_save_passwort READ SavePasswort NOTIFY savePasswortChanged)

    Q_PROPERTY(bool loginRead MEMBER m_loginRead READ LoginRead NOTIFY loginReadFinished)
    Q_PROPERTY(bool canAutoLogin MEMBER m_autologin READ AutoLogin NOTIFY autoLoginSet)
    Q_DISABLE_COPY(Settings)
    Settings() { }

public:
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine)
    {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine);
        Settings *settings = new Settings;
        settings->ReadLoginData();
        return settings;
    }

    QString LoginPasswort() const { return m_loginpasswort; }
    QString LoginName() const { return m_loginname; }

    inline bool AutoLogin() const { return m_autologin; }

    inline bool SaveLogin() const { return m_save_login; }
    inline int SavePasswort() const { return m_save_passwort; }
    inline bool LoginRead() const { return m_loginRead; }

public slots:
    void setLoginData(const QString &login, const QString &passwort, bool save_login, int save_passwort);
    void setLoginName(const QString &login) { m_loginname = login; }
    void setLoginPasswort(const QString &passwort) {  m_loginpasswort = passwort; }

    void ReadLoginData();
    void CheckLogin();

signals:
    void loginNameChanged();
    void loginPasswortChanged();
    void loginDataRead();
    void saveLoginChanged();
    void savePasswortChanged();
    void loginReadFinished();
    void autoLoginSet();

private:
    QString m_loginpasswort, m_loginname;
    bool m_autologin = false, m_save_login = false, m_loginRead = false;
    int m_save_passwort = 0;
};
