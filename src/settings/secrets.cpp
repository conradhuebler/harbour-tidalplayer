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

#include <QtCore/QDebug>

#include <QException>

#include <Sailfish/Secrets/collectionnamesrequest.h>
#include <Sailfish/Secrets/createcollectionrequest.h>
#include <Sailfish/Secrets/deletesecretrequest.h>
#include <Sailfish/Secrets/storesecretrequest.h>
#include <Sailfish/Secrets/storedsecretrequest.h>
#include <Sailfish/Secrets/deletecollectionrequest.h>

#include "secrets.h"

using namespace Sailfish::Secrets;

const QString Secrets::m_collectionName(QStringLiteral("tidalPlayer"));

Secrets::Secrets()
{

}

QByteArray Secrets::get(const QString &key) {
    ensureCollection();

    StoredSecretRequest ssr;
    ssr.setManager(m_manager.get());
    ssr.setUserInteractionMode(Sailfish::Secrets::SecretManager::SystemInteraction);
    ssr.setIdentifier(createIdentifier(key));;
    ssr.startRequest();
    ssr.waitForFinished();

    auto success = checkResult(ssr);
    if (success)
    {
        return ssr.secret().data();
    }

    return QByteArray();
}

bool Secrets::set(const QString &key, const QByteArray &data) {
    ensureCollection();

    Secret secret(createIdentifier(key));
    secret.setData(data);

    StoreSecretRequest ssr;
    ssr.setManager(m_manager.get());
    ssr.setSecretStorageType(StoreSecretRequest::CollectionSecret);
    ssr.setUserInteractionMode(SecretManager::SystemInteraction);
    ssr.setSecret(secret);
    ssr.startRequest();
    ssr.waitForFinished();

    return checkResult(ssr);
}

bool Secrets::unset(const QString &key) {
    ensureCollection();

    DeleteSecretRequest dsr;
    dsr.setManager(m_manager.get());
    dsr.setUserInteractionMode(SecretManager::SystemInteraction);
    dsr.setIdentifier(createIdentifier(key));
    dsr.startRequest();
    dsr.waitForFinished();

    return checkResult(dsr);
}

void Secrets::ensureCollection() {
    CollectionNamesRequest cnr;
    cnr.setManager(m_manager.get());
    cnr.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
    cnr.startRequest();
    cnr.waitForFinished();
    if(checkResult(cnr) && cnr.collectionNames().contains(m_collectionName)) {
        return;
    }

    bool initialized = setupCollection();
    if(!initialized) {
        QException e;
        throw e;
    }
}

bool Secrets::setupCollection()
{
    CreateCollectionRequest ccr;
    ccr.setManager(m_manager.get());
    ccr.setCollectionName(m_collectionName);
    ccr.setAccessControlMode(SecretManager::OwnerOnlyMode);
    ccr.setCollectionLockType(CreateCollectionRequest::DeviceLock);
    ccr.setDeviceLockUnlockSemantic(SecretManager::DeviceLockVerifyLock);
    ccr.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
    ccr.setEncryptionPluginName(SecretManager::DefaultEncryptedStoragePluginName);
    ccr.startRequest();
    ccr.waitForFinished();
    return checkResult(ccr);
}

bool Secrets::checkResult(const Request &req)
{
    Result result = req.result();
    bool success = result.errorCode() == Result::NoError;
    if (!success) {
        qDebug() << result.errorMessage();
    }
    return success;
}

Secret::Identifier Secrets::createIdentifier(const QString &key)
{
    return Secret::Identifier(key, Secrets::m_collectionName, SecretManager::DefaultEncryptedStoragePluginName);
}
