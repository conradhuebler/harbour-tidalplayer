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
COPIES += six

typing.files = external/typing_extensions/src/typing_extensions.py
typing.path = $$OUT_PWD/python

six.path = $$OUT_PWD/python
six.files = external/six/six.py

isodate.files = external/isodate/src/isodate/*
isodate.path  = /usr/share/$${TARGET}/python/isodate

tidalpython.files = $$files(external/tidalapi/*.py)
tidalpython.path  = $$OUT_PWD/python/tidalapi

mpegdash.files = $$files(external/mpegdash/mpegdash/*.py)
mpegdash.path  = $$OUT_PWD/python/mpegdash

ratelimit.files = $$files(external/ratelimit/ratelimit/*.py)
ratelimit.path  = $$OUT_PWD/python/ratelimit

dateutil.path = /usr/share/$${TARGET}/python/dateutil
dateutil.files = external/dateutil/dateutil/*

future.path =/usr/share/$${TARGET}/python/python-future
future.files = external/python-future/*

aes.path = /usr/share/$${TARGET}/python/pyaes
aes.files = $$files(external/pyaes/pyaes/*.py)

INSTALLS += isodate
INSTALLS += future
INSTALLS += aes
INSTALLS += dateutil
