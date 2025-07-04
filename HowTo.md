# Preconditions
just to be able to build and run the solution, it should suffice to have sailfishos sdk and python-tidal installed
to be able to run tests you will also need python and all the other stuff
after cloning the repo don't forget to:
git submodule update --init --recursive
to download the dependencies. in my case i had errors in two packages. deletion of empty folders and retry fixed it.

rest of this files seems currently pretty outdated and i will clean it up later.

## On linux

## On Windows
install sailfishos sdk
### when using latest tidalapi, currently not!, skip
install wsl
install ubuntu or any other linux distro into wsl
install python and pip (3. in ubuntu wsl)
install tidalapi: $ pip install tidalapi
during installation do remember the installation folder
copy *.py files from tidalapi installation folder (see above) into external/python-tidal/tidalapi
### using patched tidalapi from phone
start windows terminal
install tidal-player on phone
if installation fails e.g. due to:, nothing provides .. python3-dateutil
connect phone with computer
scp /usr/share/harbour-tidalplayer/python/tidalapi/request.py defaultuser@192.168.2.14:C:\Users\<your-user>\Downloads


ssh -p 2223 -i 'C:\SailfishOS\vmshare\ssh\private_keys\sdk - Copy' root@localhost


clone harbour-tidalplayer repo
copy *.py files from ..\Downloads to .external\python-tidal\tidalapi

open and build project
it sshould work now
deploy should work


# On Emulator
you need to ssh from terminal into emulator // check my note in forum.
## in Emulator
install mpris:
pkcon install mpris-qt5-qml-plugin
add lpr repo to install python dependencies:
sudo zypper ar https://sailfish.openrepos.net/lpr/personal-main.repo
mittels search oder zypper packages den key von neuer repo akzeptieren:
sudo zypper search python3
then install dateutils
pkcon install python3-python-date..
futures for i486 are not provided by lpr
download future src from https://files.pythonhosted.org/packages/a7/b2/4140c69c6a66432916b26158687e821ba631a4c9273c474343badf84d3ba/future-1.0.0.tar.gz
https://dl.fedoraproject.org/pub/epel/9/Everything/aarch64/Packages/p/python3-future-0.18.3-3.el9.noarch.rpm
on second terminal: copy them to ~
scp -P 2223 -i 'C:\SailfishOS\vmshare\ssh\private_keys\sdk - Copy' C:\Users\<user>\Downloads\future-1.0.0.tar.gz defaultuser@localhost:
in emulator, unzip, and install them
gunzip -c future-1.0.0.tar.gz | tar xf -
cd future-1.0.0/
python3 setup.py install
devel-su easy_install future

 ssh -p 2223 -i 'C:\SailfishOS\vmshare\ssh\private_keys\sdk - Copy' root@localhost

https://docs.sailfishos.org/Tools/Sailfish_SDK/FAQ/#how-do-i-install-packages-to-emulator


errors on emulator after installing future
pkcon install sailfish-browser to fix below errors


QML AnimatedLoader: (file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:5:1: module "Sailfish.WebEngine" is not installed
    import Sailfish.WebEngine 1.0
    ^, file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:6:1: module "Sailfish.WebView.Popups" is not installed
    import Sailfish.WebView.Popups 1.0
    ^, file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:4:1: module "Sailfish.WebView" is not installed
    import Sailfish.WebView 1.0
    ^, file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:5:1: module "Sailfish.WebEngine" is not installed
    import Sailfish.WebEngine 1.0
    ^, file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:6:1: module "Sailfish.WebView.Popups" is not installed
    import Sailfish.WebView.Popups 1.0
    ^, file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:4:1: module "Sailfish.WebView" is not installed
    import Sailfish.WebView 1.0
    ^, file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:5:1: module "Sailfish.WebEngine" is not installed
    import Sailfish.WebEngine 1.0
    ^, file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:6:1: module "Sailfish.WebView.Popups" is not installed
    import Sailfish.WebView.Popups 1.0
    ^, file:///tmp/qml-live-overlay--harbour-tidalplayer-harbour-tidalplayerEbpUR5/qml/dialogs/OAuth.qml:4:1: module "Sailfish.WebView" is not installed
    import Sailfish.WebView 1.0    ^)

# GIT upstream / branching etc

https://devopscube.com/set-git-upstream-respository-branch/

git checkout -b favorites
git push -u origin favorites

git branch -vv

# future features

album.share_url <- share album >
album.similar <->
album.type -> (single/ep/lp)

artist.get_other()  <-gets other albums of artist>

general
some exception handling
   catch the important exceptions and visualize them to use, maybe re-login button
quick goto-current playlist from player ?

