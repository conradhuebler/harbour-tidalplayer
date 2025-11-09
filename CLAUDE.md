# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a native Tidal Music Player for Sailfish OS, built with QML/Qt and Python. The app uses PyOtherSide to bridge QML UI with Python backend that interfaces with the Tidal API.

## Build and Development Commands

### Building
```bash
# Build the project using qmake
qmake
make

# Build RPM package (Sailfish OS)
rpmbuild --define "_topdir $(pwd)/rpm" -ba rpm/harbour-tidalplayer.spec
```

### Prerequisites
- Sailfish OS SDK
- Python 3.x with required dependencies
- PyOtherSide QML plugin
- Git submodules must be initialized: `git submodule update --init --recursive`

### Dependencies Installation
The project requires specific Python packages available through OpenRepos:
- Python3-requests  
- Python3-future
- Python3-dateutil
- MPRIS Qt5 QML plugin

## Development Guidelines

### Code Organization
- Each `qml/` subdirectory may contain component-specific documentation
- Variable sections updated regularly with short-term information
- Preserved sections contain permanent knowledge and patterns
- Instructions blocks contain operator-defined future tasks and visions

### QML/JavaScript Implementation Standards
- Mark new QML components as "// Claude Generated" for traceability
- Document new functions briefly with JSDoc-style comments
- Document existing undocumented functions if appearing regularly
- Remove TODO comments if done and approved
- **Debug Logging Standards**:
  - Use 4-tier debug system: 0=None, 1=Normal, 2=Informative, 3=Verbose/Spawn
  - Enable debug level via user settings (settings.debugLevel)
  - Always use conditional guards around console.log() calls
  - Pattern: `if (settings.debugLevel >= 1) console.log("Component: message")`
  - Avoid debug overhead in production builds (level 0)
- Use proper QML/JavaScript error handling patterns
- Maintain backward compatibility with older Sailfish OS versions
- **Always check and consider instructions blocks** before implementing
- Replace deprecated QML properties/methods when encountered
- Follow QML coding conventions and property binding patterns

## Architecture

### Core Components

**Python Backend (`qml/tidal.py`)**
- Main Tidal API client class
- Handles authentication (OAuth), search, playback URL generation
- Communicates with QML via PyOtherSide signals
- Location: `qml/tidal.py`

**QML Bridge (`qml/components/TidalApi.qml`)**  
- PyOtherSide interface between QML and Python
- Signal handlers for Python→QML communication
- Exposes Python functions to QML UI
- Location: `qml/components/TidalApi.qml`

**Media Controller (`qml/components/MediaController.qml`)**
- QtMultimedia MediaPlayer wrapper
- MPRIS integration for system media controls
- Handles playback state and auto-advance logic
- Location: `qml/components/MediaController.qml`

**Playlist Management (`qml/components/PlaylistManager.qml`)**
- Track queue management
- Current/next/previous track logic
- Integration with PlaylistStorage for persistence
- Location: `qml/components/PlaylistManager.qml`

### Key Architecture Patterns

1. **Signal-Based Communication**: Python backend sends signals via PyOtherSide, QML components handle them and emit Qt signals
2. **Caching System**: Track/album/artist metadata cached in TidalCache component
3. **OAuth Authentication**: Full OAuth flow with token refresh handling
4. **Modular QML Components**: Separate components for different responsibilities (auth, media, playlists, etc.)

### External Dependencies
- `external/python-tidal/`: Custom Tidal API client (patched version)
- `external/dateutil/`: Python dateutil library
- `external/isodate/`: ISO date parsing
- `external/mpegdash/`: MPEG-DASH support
- `external/pyaes/`: A pure-Python implementation of the AES block cipher algorithm
- `external/python-future/`: is the missing compatibility layer between Python 2 and Python 3. 
- `external/ratelimit/`: API rate limiting
- `external/six/`: Six is a Python 2 and 3 compatibility library

## Important Files

- `harbour-tidalplayer.pro`: Qt project file with build configuration
- `qml/harbour-tidalplayer.qml`: Main application window and global state
- `qml/tidal.py`: Core Python API client
- `rpm/harbour-tidalplayer.spec`: RPM packaging specification

## Development Notes

- The app uses a patched version of tidalapi v0.7.1 due to compatibility issues
- OAuth tokens are stored using Nemo.Configuration
- MPRIS integration provides system-wide media controls
- The build process copies Python dependencies to the output directory
- Testing requires physical Sailfish OS device or emulator with proper dependencies

## Performance Status

### 🚀 Completed Optimizations ✅
- **Async-First API Pattern** - Request queuing with deduplication (30-50% UI improvement)
- **Database Query Batching** - 50-item batch operations (25% query improvement)  
- **Incremental Cache Cleanup** - Non-blocking cleanup (eliminated UI freezes)
- **Track Play Deduplication** - WORKAROUND for duplicate playTrackId() calls

### 🎯 Priority Optimizations TODO
1. **Batch Signal Emissions** - Replace individual pyotherside.send() calls
2. **Virtual Scrolling** - Add cacheBuffer/reuseItems to major ListViews
3. **LRU Cache** - Implement size limits to prevent memory leaks
4. **Lazy Page Loading** - Async Loaders for FirstPage carousel

---

## 🎨 Completed Features ✅

### Homescreen Personalization System
- **HomescreenManager.qml** - 8 configurable sections with priority loading
- **ConfigurableSection.qml** - Reusable components with expand/collapse
- **SectionCache.qml** - LRU caching with LocalStorage persistence
- **PersonalConfigurable.qml** - New configurable personal page
- **HomescreenSettings.qml** - Configuration UI in Settings

### Advanced Play System  
- **AdvancedPlayManager.qml** - Replace/Append/PlayNow/Queue actions
- **Context Menus** - Right-click actions for all content types
- **Single-Click Navigation** - Opens detail pages instead of playing

### Sleep Timer System
- **SleepTimerDialog.qml** - TimePicker integration with presets
- **Multiple Actions** - Pause/Stop/Fade/Close app options
- **Live Feedback** - Cover and MiniPlayer countdown display

### Media System Enhancement
- **MediaHandler.qml** - Amber.Mpris integration  
- **Reduced Permissions** - Only Internet + Audio required
- **MPRIS Integration** - System media controls

---

## 🎵 Dual Audio Player Buffer System - EXPERIMENTAL

### Instructions Block - Future Implementation
**Vision**: Implement seamless track transitions with background pre-loading to eliminate loading gaps between tracks.

### Architecture Plan

#### Core Concept
```qml
// MediaHandler.qml enhancement
Audio { id: audioPlayer1 }  // Currently playing
Audio { id: audioPlayer2 }  // Pre-loading next track
```

#### Implementation Strategy
1. **Optional Feature** - Controlled by settings toggle
2. **Smart Pre-loading** - Only when current track is >30% complete
3. **Crossfade Logic** - Smooth transitions between players
4. **Fallback Support** - Graceful degradation if pre-loading fails

#### Technical Details
```qml
// Dual player state management
property bool player1Active: true
property bool preloadingEnabled: settings.enableTrackPreloading || false
property string nextTrackUrl: ""

function preloadNextTrack() {
    if (!preloadingEnabled) return
    
    var nextTrackId = playlistManager.getNextTrackId()
    if (nextTrackId && audioPlayer.position > audioPlayer.duration * 0.3) {
        tidalApi.getTrackUrl(nextTrackId) // Background request
    }
}
```

#### Benefits
- **Seamless Transitions** - Zero-gap track changes
- **Better UX** - Instant playback of next track
- **Smart Resource Use** - Only pre-load when beneficial

#### Challenges
- **Memory Usage** - Two audio streams simultaneously  
- **Network Bandwidth** - Additional background requests
- **Token Expiry** - Tidal URLs may expire before use
- **State Complexity** - Managing dual player states

#### Settings Integration
```qml
// Settings.qml addition
Switch {
    text: qsTr("Enable Track Pre-loading")
    description: qsTr("Load next track in background for seamless playback")
    checked: settings.enableTrackPreloading
    onClicked: settings.enableTrackPreloading = checked
}
```

### Implementation Files
- `qml/components/MediaHandler.qml` - Dual Audio player logic
- `qml/components/TidalApi.qml` - Background URL fetching  
- `qml/pages/Settings.qml` - User toggle for feature
- `qml/components/PlaylistManager.qml` - Next track prediction

**Status**: 📋 PLANNED - Ready for optional implementation
