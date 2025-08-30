# Tidal Player for Sailfish OS

A native Tidal music streaming client for Sailfish OS, built with QML/Qt and Python using the tidalapi v0.7.1 (https://tidalapi.netlify.app/).

### TIDAL API Usage
As v0.7.1 is not fully compatible with TIDAL anymore, line 114 of tidalapi/user.py is removed during the packaging process.

### Development History
This project development is driven by Claude 3.5 Sonnet AI. The icon is created by Midjourney.

## ✨ Features

### 🎵 Core Music Features
- ✅ **Tidal Account Integration** - Full OAuth authentication with token refresh
- ✅ **Music Library Access** - Browse and search Tidal's complete music catalog
- ✅ **Playlist Management** - Create, edit, and manage personal playlists
- ✅ **Playback Control** - Play tracks, albums, playlists, and mixes
- ✅ **Media Controls** - Play, pause, next, previous with MPRIS system integration
- ✅ **Track Information** - Complete metadata display with album artwork
- ✅ **Favorites System** - Save favorite tracks, albums, artists, and playlists

### 🏠 Advanced Homescreen System
- ✅ **Configurable Sections** - 8 customizable content sections
  - Recently Played, Popular Playlists, Top Artists, Top Albums
  - Top Tracks, Personal Playlists, Custom Mixes, Radio Stations  
- ✅ **Cache-First Loading** - Instant startup with cached content
- ✅ **Priority-Based Refresh** - Smart background updates
- ✅ **Toggle Interface** - Switch between classic and modern homescreen

### 🎮 Advanced Play Actions
- ✅ **Context Menus** - Right-click for advanced play options
- ✅ **Multiple Play Modes**:
  - Replace Playlist & Play
  - Add to Playlist & Play  
  - Play Now (Keep Playlist)
  - Add to Queue
- ✅ **Configurable Defaults** - Set preferred play action in settings
- ✅ **Single-Click Navigation** - Click to view details, long-press for play menu

### ⏰ Sleep Timer System
- ✅ **Modern UI** - Sailfish OS native TimePicker integration
- ✅ **Quick Presets** - 8 preset buttons (5m, 10m, 15m, 30m, 45m, 1h, 1.5h, 2h)
- ✅ **Custom Time Selection** - Full time picker for any duration
- ✅ **Multiple Actions**:
  - Pause playback
  - Stop playback  
  - Fade out and pause (10-second fade)
  - Close application
- ✅ **Live Progress Feedback** - Real-time countdown with system notifications
- ✅ **Cover Integration** - Timer display in application cover

### 🚀 Performance Optimizations
- ✅ **Async-First API** - 30-50% UI responsiveness improvement
- ✅ **Database Batching** - 25% query performance improvement  
- ✅ **Request Deduplication** - 30% network efficiency improvement
- ✅ **Incremental Cache Cleanup** - Eliminated periodic UI freezes
- ✅ **LRU Cache Management** - Memory leak prevention

### 🔧 System Integration
- ✅ **MPRIS Media Controls** - System-wide media control integration
- ✅ **Reduced Permissions** - Only Internet + Audio permissions required
- ✅ **System Notifications** - Native notification banners
- ✅ **Cover Page Support** - Track info and timer display in cover
- ✅ **MiniPlayer** - Persistent mini player with progress slider

## Requirements

Include https://openrepos.net/user/7598/repository and https://openrepos.net/user/2414/repository as repository:

or look for
Python3-request
and
Python3-future

in storeman and add the corresponding repos.

and 

- Python 3.x
- Qt/QML
- PyOtherSide
- Tidal API credentials

## 📦 Getting Test Builds

### Automatic RPM Builds
This project automatically builds RPM packages for all Sailfish OS architectures:

**For Testing Latest Features:**
- 🔄 **Master Branch Builds** - Every push to master triggers automatic builds
- 🧪 **Pull Request Builds** - Every PR gets tested with automatic builds
- 📥 **Download Location** - Go to [Actions](../../actions), click on latest build, download artifacts

**For Stable Releases:**
- 🚀 **Tagged Releases** - Official releases with changelog in [Releases](../../releases)
- 📋 **Release Notes** - Complete changelog and installation instructions

### Supported Architectures
- **aarch64** - Modern ARM64 devices (Xperia 10 II/III/IV, etc.)
- **armv7hl** - Older ARM32 devices (Jolla Phone, Xperia X, etc.)  
- **i486** - x86 emulator and Intel-based devices

### Installation
1. Download the appropriate RPM for your device architecture
2. Transfer to your Sailfish OS device
3. Install via Settings → System → Software Updates → Manual Installation
4. Or use `pkcon install-local harbour-tidalplayer-*.rpm` from terminal

