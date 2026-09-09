# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Project Overview

Native Tidal Music Player for Sailfish OS. QML/Qt UI, Python backend via PyOtherSide.

## Very General Instructions for AI Coding

- Avoid flattery, compliments, or positive language. Be clear and concise. Do not use agreeable language to deceive.
- Default to short responses; only expand when the operator asks for detail.
- Do comprehensive verification before claiming completion.
- Show proof of completion, do not just assert it.
- Prioritize thoroughness over speed.
- If the operator corrects you, adapt for the rest of the task.
- No completion claim until zero remaining instances can be demonstrated.
- **Never commit until the operator has explicitly confirmed.** Stage changes, summarize the diff, wait.
- Do not use `git add -A` / `git add .`; name files explicitly.
- Keep commit messages short and concise — a single subject line; add a body only when context is genuinely useful.

## Build

```bash
qmake && make
rpmbuild --define "_topdir $(pwd)/rpm" -ba rpm/harbour-tidalplayer.spec
```

Submodules: `git submodule update --init --recursive` (only `mpegdash`, `ratelimit`, `pyaes` are submodules; other `external/*` packages are committed directly). Runtime dependencies are declared in `rpm/harbour-tidalplayer.yaml` and mirrored in the `.spec`.

## Architecture

- `qml/tidal.py` — Python backend, Tidal API client (uses `external/tidalapi`)
- `qml/components/TidalApi.qml` — PyOtherSide bridge, signal handlers
- `qml/components/MediaHandler.qml` + `DualAudioManager.qml` — playback, MPRIS, optional crossfade/preload
- `qml/components/PlaylistManager.qml` + `PlaylistStorage.qml` — queue and persistence
- `qml/components/TidalCache.qml` — track/album/artist metadata cache (LocalStorage)
- `qml/pages/Personal.qml` — home page shell; central LocalStorage cache, exposes `cacheItem` / `loadSectionItems`
- `qml/pages/sections/` — one Column component per homescreen section; order driven by `homescreenSectionOrder` setting
- `qml/pages/HomescreenLayout.qml` — drag-to-reorder layout config (uses `Opal.DragDrop`, same pattern as `TrackList.qml`)
- `qml/pages/widgets/CoverArt.qml` — artwork tile: rounded corners, hairline edge,
  optional drop shadow (`elevation`) and mirrored reflection (`reflection`)
- `qml/pages/widgets/BlurBackdrop.qml` — the artwork blurred and dimmed behind headers
  and the player bar (`FastBlur` on a 128px decode)
- `qml/pages/widgets/DetailHeader.qml` — hero header (blurred backdrop + cover on its
  reflection); `TrackList.qml` shows it instead of the `PageHeader` when `headerImage` is set
- `qml/pages/widgets/CoverFlow.qml` — `PathView` cover flow; used full-screen by
  `qml/pages/QueueCoverFlowPage.qml` (play queue) and inline by `HomeSection.qml`
- Appearance settings: `artworkEffects`, `blurBackdrops`, `homeCoverFlow`
  (Settings → Appearance; keys `/artworkEffects`, `/blurBackdrops`, `/homeCoverFlow`)
- `qml/harbour-tidalplayer.qml` — application window, global state, Nemo.Notifications, settings glue

Communication: Python emits PyOtherSide signals → QML handlers re-emit Qt signals.

## QML Conventions

- Mark new components `// Claude Generated`.
- Gate every `console.log` behind a debug-level check:
  `if (settings.debugLevel >= 1) console.log("Component: …")`
  Levels 0 / 1 / 2 / 3 = None / Normal / Informative / Verbose.
- Sailfish 4.6 ships Qt 5.6 — do not use `Qt.callLater`, `Qt.labs.settings`, or `String.prototype.contains`. Use `Timer`, `QtQuick.LocalStorage`, and `indexOf` / `includes` instead.
- Effects come from `QtGraphicalEffects 1.0` (Qt 5.6), not `QtQuick.Effects`. An item
  handed to an effect as `source`/`maskSource` needs `layer.enabled: true`, and it
  contributes its pixels but never its own `transform` — put the transform on a wrapper.
- `Matrix4x4` (the perspective term in the cover flow) needs at least `import QtQuick 2.3`;
  the plain `import QtQuick 2.0` used elsewhere in this repo does not expose it.
- Do not give a component a `default property alias`: the file's own children land in
  the alias target as well.
- Maintain backward compatibility with older Sailfish releases where reasonable.
- Replace deprecated QML properties/methods when encountered.

## Important Files

- `harbour-tidalplayer.pro` — qmake build config, `INSTALLS` rules for vendored Python packages
- `rpm/harbour-tidalplayer.{spec,yaml}` — package metadata; keep `Requires` in sync between both
- `qml/harbour-tidalplayer.qml` — main window and global state
- `qml/tidal.py` — Python API client
