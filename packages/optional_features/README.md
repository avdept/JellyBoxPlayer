# optional_features

The parts of JellyBox that are not open: per-manufacturer UPnP renderer
behaviour, the genre-mix playlist policy, cross-device continuity
(the Jellybox Cloud account, session sync and handoff), and the external music
catalogue used for similar artists, discographies and song previews.

**This is the open stub.** It carries the API the app compiles against, with
inert implementations — no quirk rules, no generator, continuity reporting
`available == false` and `catalogSources()` returning nothing. A build made
from this repository alone is a complete music player; it just has no renderer
workarounds, no generated mixes, no Jellybox Cloud row in settings and no
discovery sections on artist pages.

The working implementation is a private package swapped in through
`pubspec_overrides.yaml`:

```yaml
dependency_overrides:
  optional_features:
    git:
      url: git@github.com:avdept/optional_features.git
      ref: main
```

Each feature keeps its own entrypoint, so imports say what they are:

```dart
import 'package:optional_features/upnp_quirks.dart';
import 'package:optional_features/genre_playlists.dart';
import 'package:optional_features/jellybox_cloud.dart';
import 'package:optional_features/catalog.dart';
```

The app hands each feature what it needs through a port it implements —
`GenrePlaylistSource<S>` and `CloudHost<S>` — so none of this code knows what a
Jellyfin item id means.
