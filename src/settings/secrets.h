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

#include <QByteArray>
#include <QtCore/QPair>

#include <memory>

#include <Sailfish/Secrets/request.h>
#include <Sailfish/Secrets/secretmanager.h>
#include <Sailfish/Secrets/secret.h>


class Secrets
{
public:
    Secrets();

    bool set(const QString &key, const QByteArray &data);
    bool unset(const QString &key);
    QByteArray get(const QString &key);

private:

    std::unique_ptr<Sailfish::Secrets::SecretManager> m_manager{new Sailfish::Secrets::SecretManager()};
    static const QString m_collectionName;

    void ensureCollection();
    bool setupCollection();
    bool checkResult(const Sailfish::Secrets::Request &req);
    Sailfish::Secrets::Secret::Identifier createIdentifier(const QString &key);
};
