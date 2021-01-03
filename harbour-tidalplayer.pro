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

CONFIG += sailfishapp file_copies

LIBS += -L /usr/local/lib/python3.8 -lpython3.8
INCLUDEPATH += /usr/include/python3.8
DEPENDPATH += /usr/include/python3.8

QT += multimedia

PKGCONFIG += sailfishsecrets


SOURCES +=  src/harbour-tidalplayer.cpp \
            src/python/pythonapi.cpp \
            src/settings/secrets.cpp \
            src/settings/settings.cpp

 HEADERS += src/settings/secrets.h \
            src/python/pythonapi.h \
            src/settings/settings.h

DISTFILES +=  harbour-tidalplayer.desktop \
    qml/harbour-tidalplayer.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FirstPage.qml\
    qml/pages/SecondPage.qml\
    qml/pages/Settings.qml\
    rpm/harbour-tidalplayer.changes.in\
    rpm/harbour-tidalplayer.changes.run.in\
    rpm/harbour-tidalplayer.spec\
    rpm/harbour-tidalplayer.yaml

COPIES += tidalpython
tidalpython.files = $$files(external/python-tidal/tidalapi/*.py)
tidalpython.path = $$OUT_PWD/python/tidalapi


SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n
# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-tidalplayer-de.ts

