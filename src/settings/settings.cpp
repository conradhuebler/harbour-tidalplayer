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

#include "src/settings/secrets.h"

#include "settings.h"

static const QString PWD     {QStringLiteral("stored_passwort")};
static const QString LOGIN     {QStringLiteral("stored_login")};
static const QString SAVE_LOGIN     {QStringLiteral("store_login")};
static const QString SAVE_PASSWORT     {QStringLiteral("store_passwort")};
static const QString LOGIN_GROUP     {QStringLiteral("LoginGroup")};

void Settings::CheckLogin()
{
    ReadLoginData();
    m_loginRead = true;
    emit loginReadFinished();
}

void Settings::setLoginData(const QString &login, const QString &passwort, bool save_login, int save_passwort)
{
    QSettings settings;
    settings.beginGroup(LOGIN_GROUP);

    if(save_passwort == 1 && (passwort != m_loginpasswort))
    {
        Secrets account;
        account.set(PWD, passwort.toUtf8());
        settings.setValue(PWD, QString());

    }else if(save_passwort == 2){
        settings.setValue(PWD, passwort);
    }else if(!save_passwort && settings.value(SAVE_PASSWORT, false).toBool())
    {
        Secrets account;
        account.unset(PWD);
        settings.setValue(PWD, QString());
    }

    if(save_login)
        settings.setValue(LOGIN, login);
    else
        settings.setValue(LOGIN, QString());

    m_loginname = login;
    m_loginpasswort = passwort;

    settings.setValue(SAVE_LOGIN, save_login);
    settings.setValue(SAVE_PASSWORT, save_passwort);
}


void Settings::ReadLoginData()
{
    QSettings settings;
    settings.beginGroup(LOGIN_GROUP);

    m_save_login = settings.value(SAVE_LOGIN, false).toBool();
    m_save_passwort = settings.value(SAVE_PASSWORT, 0).toInt();

    if(m_save_login)
    {
        m_loginname = settings.value(LOGIN).toString();
        qApp->setProperty("login", m_loginname);
    }
    if(m_save_passwort == 1)
    {
        Secrets account;
        m_loginpasswort = QString::fromUtf8(account.get(PWD));
        qApp->setProperty("login", m_loginname);
    }else if(m_save_passwort == 2)
    {
        m_loginpasswort = settings.value(PWD).toString();
        qApp->setProperty("pwd", m_loginpasswort);
    }
    m_autologin = m_save_login && m_save_passwort;
    qApp->setProperty("autologin", m_autologin);

    emit autoLoginSet();
}

