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

tidalpython.files = $$files(external/python-tidal/tidalapi/*.py)
tidalpython.path  = $$OUT_PWD/python/tidalapi

python.files = external/*
DISTFILES += external/mpgegdash/mpegdash/*
DISTFILES += external/isodate/src/isodate/*
DISTFILES += external/ratelimit/ratelimit/*
DISTFILES += external/typing_extensions/src/*

python.path = "/usr/share/harbour-tidalplayer/python"
INSTALLS += python

#libs.path = /usr/share/$${TARGET}
#libs.files = external
#INSTALLS += libs
