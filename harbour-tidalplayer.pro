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
        qml/pages/dialogs/Account.qml \
        qml/pages/dialogs/OAuth.qml \
        rpm/harbour-tidalplayer.changes.in\
        rpm/harbour-tidalplayer.changes.run.in\
        rpm/harbour-tidalplayer.spec\
        rpm/harbour-tidalplayer.yaml

COPIES += tidalpython
COPIES += mpegdash
COPIES += ratelimit
COPIES += typing
COPIES += dateutil
COPIES += dateutilparser
COPIES += isodatelocal
COPIES += futurelocal
COPIES += pastlocal
COPIES += sixlocal

tidalpython.files = $$files(external/tidalapi/*.py)
tidalpython.path  = $$OUT_PWD/python/tidalapi

mpegdash.files = $$files(external/mpegdash/mpegdash/*.py)
mpegdash.path  = $$OUT_PWD/python/mpegdash

ratelimit.files = $$files(external/ratelimit/ratelimit/*.py)
ratelimit.path  = $$OUT_PWD/python/ratelimit

typing.files = $$files(external/typing_extensions-4.12.2/src/*.py)
typing.path  = $$OUT_PWD/python/typing_extensions

dateutil.files = $$files(external/dateutil-2.8.2/dateutil/*.py)
dateutil.path  = $$OUT_PWD/python/dateutil

dateutilparser.files = $$files(external/dateutil-2.8.2/dateutil/parser/*.py)
dateutilparser.path  = $$OUT_PWD/python/dateutil/parser

# Local build copies (COPIES)
isodatelocal.files = $$files(external/isodate-0.6.1/src/isodate/*.py)
isodatelocal.path  = $$OUT_PWD/python/isodate

futurelocal.files = $$files(external/python-future-1.0.0/src/future/*.py)
futurelocal.path = $$OUT_PWD/python/future

pastlocal.files = $$files(external/python-future-1.0.0/src/past/*.py)
pastlocal.path = $$OUT_PWD/python/past

sixlocal.files = external/six-1.12.0/six.py
sixlocal.path = $$OUT_PWD/python/

# Installation targets (INSTALLS)
isodate.files = external/isodate-0.6.1/*
isodate.path  = /usr/share/$${TARGET}/python/isodate

future.path =/usr/share/$${TARGET}/python/python-future
future.files = external/python-future-1.0.0/*

six.path =/usr/share/$${TARGET}/python/six
six.files = external/six-1.12.0/*

libs.path = /usr/share/$${TARGET}
libs.files = external

INSTALLS += six
INSTALLS += isodate
INSTALLS += libs  
INSTALLS += future
