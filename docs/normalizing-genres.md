# Normalizing your music genres

JellyBox builds genre mixes from what you actually listen to: it reads the genres on your
played tracks, ranks them by play count, and turns the top few into shuffled 20-song mixes.
That only works as well as the genres in your library.

If your files carry `Alt Metal` on one album and `Alt. Metal` on another, Jellyfin treats
those as two unrelated genres. Your listening gets split across both, and neither may rank
high enough to become a mix.

**You may not need to do anything.** JellyBox already folds spelling variants together -
`Alt Metal`, `Alt. Metal`, `alt-metal` and `Alt.Metal` are all counted as one genre, and a
mix built from that genre pulls songs from every spelling. The mix is labelled with whichever
spelling you've played most.

What JellyBox cannot fix for you:

- **Synonyms.** `Alt Metal` and `Alternative Metal` are different words, not different
  spellings. Same for `R&B` and `RnB`, or `Hip Hop` and `Rap`.
- **Junk tags.** `seen live`, `favourites`, `00s`, `albums I own` - these come from
  scrobbler-style tags and compete with real genres for a slot.
- **Missing genres.** A track with no genre tag can never appear in a mix.
- **Accents.** `Métal` and `Metal` stay separate.

Fixing the tags themselves solves all four, and it improves every client you use, not just
this one.

## Why Jellyfin won't do it for you

Worth knowing before you go looking for a setting or a plugin - there isn't one.

- **Genres come from your file tags, and nothing else.** Jellyfin reads the `GENRE` tag
  during a library scan. It never writes tags back to your files.
- **Its only normalization is case and accents.** Internally Jellyfin lowercases genre
  names and strips diacritics. It does *not* strip punctuation, so `Alt Metal` and
  `Alt. Metal` remain distinct genres on the server. There is no merge or rename UI.
- **No plugin fills the gap.** Of the music plugins in the official catalog, Discogs,
  AudioDb and MusicBrainz write genres onto *albums*. Jellyfin does not pass album genres
  down to tracks, so they never reach the data mixes are built from. (MusicBrainz album
  genres also only landed in the 12.0 release candidates - on 10.11 that provider writes no
  genres at all.)

So this is a tagging job, done with a tagging tool, before Jellyfin ever sees the files.

## Step 1 — find your duplicates

Before changing anything, see what you're dealing with. This lists every group of genre
names in your library that differ only by punctuation, spacing or case.

Get an API key from **Dashboard → API Keys**, then:

```bash
export JELLYFIN_URL="http://your-server:8096"
export JELLYFIN_TOKEN="your-api-key"
```

```python
import json, os, re, urllib.request

server = os.environ["JELLYFIN_URL"].rstrip("/")
request = urllib.request.Request(
    f"{server}/MusicGenres?limit=2000",
    headers={"X-Emby-Token": os.environ["JELLYFIN_TOKEN"]},
)
genres = json.load(urllib.request.urlopen(request))["Items"]

def key(name):
    return re.sub(r"[\W_]+", "", name.lower().replace("&", "and"))

buckets = {}
for genre in genres:
    buckets.setdefault(key(genre["Name"]), []).append(genre["Name"])

print(f"{len(genres)} genres, {len(buckets)} after normalizing\n")
for names in buckets.values():
    if len(names) > 1:
        print(" | ".join(sorted(names)))
```

The count on the first line is the useful number. If 340 genres collapse to 190, most of
your genre list is noise. Keep the output — you'll re-run this at the end to check your work.

## Step 2 — fix the tags

Pick whichever tool matches your library size and how much control you want.

### beets — best for bulk cleanup

The [`lastgenre`](https://beets.readthedocs.io/en/stable/plugins/lastgenre.html) plugin
exists for exactly this problem. It has a whitelist of real genre names, so junk tags get
dropped, and a canonicalization tree that rolls obscure genres up to their parent - `viking
metal` becomes `black metal`, or `heavy metal` if that's as specific as your whitelist goes.

```yaml
plugins: lastgenre

lastgenre:
    canonical: yes      # roll obscure genres up to a parent
    whitelist: yes      # drop anything that isn't a real genre
    count: 2            # at most two genres per track
    force: yes          # overwrite the genres already in your files
    source: album       # one genre set per album, not per track
```

Then apply it to your existing library:

```bash
beet lastgenre
```

`force: yes` is the important one - without it, beets leaves existing genre tags alone, which
means it won't fix the mess you already have. Run it on a subset first (`beet lastgenre
artist:Tool`) and check the result before committing to the whole library.

### MusicBrainz Picard — best with a GUI

Under **Options → Metadata → Genres**:

| Setting | Set it to | Why |
| --- | --- | --- |
| Use genres from MusicBrainz | on | Community-voted genres rather than whatever was in the file |
| Use folksonomy tags as genre | **off** | This is where `seen live` and `00s` come from |
| Maximum number of genres | 1–2 | The default of 5 buries the genre that actually describes the album |
| Minimal genre usage | 90% | The default. Lower it only if too many albums come back with no genre |
| Genres or folksonomy tags to include or exclude | see below | Your own vocabulary control |

That last field takes filter rules: `-` excludes, `+` includes, `*` is a wildcard, and
`/…/` is a regular expression. So `-*metal*` drops every metal sub-genre, and `+rock`
keeps `rock` regardless of its vote share.

### Just normalize what's there

If your genres are basically right and only the spelling is inconsistent, you don't need to
re-fetch anything. [`kid3-cli`](https://kid3.kde.org/) or a short
[mutagen](https://mutagen.readthedocs.io/) script can rewrite the `GENRE` tag in place.
Use your Step 1 output as the list of what to merge, and pick one spelling per group.

## Step 3 - make Jellyfin notice

**A normal library scan will not pick up your new genres.** This is the step people miss.

Jellyfin only overwrites a track's genres when the field was empty to begin with, or when
you explicitly ask it to replace everything. So:

1. Go to **Dashboard → Libraries**, find your music library.
2. Choose **Refresh metadata**, and select **Replace all metadata** — not "Scan for new
   and updated files".

Two things that will silently block this:

- **Locked fields.** If genres were ever locked on an item (an item's edit screen has a
  lock per field), Jellyfin skips genres entirely for that item, replace-all or not.
- **Multi-genre tags.** If your files pack several genres into one tag like
  `Rock; Alt Metal`, Jellyfin needs to know how to split it. Enable custom tag delimiters
  in the library's settings and list your separator, otherwise the whole string becomes a
  single genre named `Rock; Alt Metal`.

Genres with no tracks left pointing at them disappear on their own after the refresh.

## Step 4 - verify

Re-run the Step 1 script. The two counts should be much closer together, and the duplicate
groups should be mostly gone.

In JellyBox, the "Made for you" shelf is built **once per day per library** and then stored, so
retagging does not change it straight away - you'll keep seeing the mixes built from your old
tags until the date rolls over. Release builds have no rebuild button; debug builds show one
next to the shelf title.

## What to aim for

A small, deliberate vocabulary beats an exhaustive one.

- **1–2 genres per track.** More than that and every album belongs to everything.
- **20–40 genres total** for a typical library. Coarse names like `Alt Metal` group far
  better than a dozen micro-genres with three albums each.
- **Enough songs per genre to matter.** JellyBox only builds a mix from a genre with at
  least 20 songs in your library, takes at most 3 mixes, and allows at most 2 songs from
  the same album in a mix - so a genre needs roughly 10 distinct albums to fill a full
  20-song mix. Hyper-specific genres never clear that bar.

If you tag for the mixes you want to listen to rather than for taxonomic accuracy, you'll
get better shelves.
