# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-tidalplayer

CONFIG += sailfishapp_qml  file_copies

SOURCES +=

OTHER_FILES += harbour-tidalplayer.desktop \
        qml/harbour-tidalplayer.qml \
        qml/cover/CoverPage.qml \
        qml/pages/FirstPage.qml\
        qml/pages/SecondPage.qml\
        qml/pages/Personal.qml\
        qml/pages/Settings.qml\
        qml/tidal.py \
        qml/playlistmanager.py \
        qml/pages/dialogs/Account.qml \
        qml/pages/dialogs/OAuth.qml \
        rpm/harbour-tidalplayer.changes.in\
        rpm/harbour-tidalplayer.changes.run.in\
        rpm/harbour-tidalplayer.spec\
        rpm/harbour-tidalplayer.yaml

COPIES += tidalpython
COPIES += mpegdash
COPIES += isodate
COPIES += ratelimit
COPIES += typing
COPIES += dateutil

tidalpython.files = $$files(external/tidalapi/*.py)
tidalpython.path  = $$OUT_PWD/python/tidalapi

mpegdash.files = $$files(external/mpegdash/mpegdash/*.py)
mpegdash.path  = $$OUT_PWD/python/mpegdash

isodate.files = $$files(external/isodate/src/isodate/*.py)
isodate.path  = $$OUT_PWD/python/isodate

ratelimit.files = $$files(external/ratelimit/ratelimit/*.py)
ratelimit.path  = $$OUT_PWD/python/ratelimit

typing.files = $$files(external/typing_extensions-4.13.2/src/*.py)
typing.path  = $$OUT_PWD/python/typing_extensions

# actually should do this since it's recursive and saves doing the copy file in spec
libs.path =/usr/share/$${TARGET}/python/dateutil
libs.files = external/dateutil-2.8.2/dateutil/*

INSTALLS += libs
