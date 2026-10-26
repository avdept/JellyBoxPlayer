// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(count) =>
      "${Intl.plural(count, one: '${count} album', other: '${count} albums')}";

  static String m1(name) => "${name} API";

  static String m2(version) => "App version: ${version}";

  static String m3(name) => "Based on ${name}";

  static String m4(deviceName) =>
      "Unable to cast to ${deviceName} — switched back to this device.";

  static String m5(deviceName) =>
      "${deviceName} is now playing something else — switched back to this device.";

  static String m6(name) => "Connected as ${name}";

  static String m7(status) => "Connection: ${status}";

  static String m8(name) => "Could not open ${name}";

  static String m9(name) => "Could not queue ${name}";

  static String m10(name) => "Could not start an instant mix for \"${name}\"";

  static String m11(name) => "Could not start a mix for \"${name}\"";

  static String m12(name) => "Could not start playing \"${name}\"";

  static String m13(count) => "Current online devices: ${count}";

  static String m14(name) => "Delete downloaded \"${name}\"?";

  static String m15(name) => "Delete \"${name}\"?";

  static String m16(number) => "Disc ${number}";

  static String m17(count, size) =>
      "Its ${Intl.plural(count, one: '${count} downloaded song', other: '${count} downloaded songs')} (${size}) will be deleted from this device.";

  static String m18(error) => "Error: ${error}";

  static String m19(count) => "${count} GB";

  static String m20(kbps) => "${kbps} kbps";

  static String m21(name) => "Log out of ${name}?";

  static String m22(name) => "Log out of ${name}";

  static String m23(count) => "${count} MB";

  static String m24(count) => "${count} min";

  static String m25(count) =>
      "${Intl.plural(count, one: '1 minute', other: '${count} minutes')}";

  static String m26(minutes) => "${minutes} min";

  static String m27(name) => "More from ${name}";

  static String m28(name) => "${name} Mix";

  static String m29(name) => "No mix available for \"${name}\"";

  static String m30(query) => "No results for “${query}”";

  static String m31(name) => "No songs found for \"${name}\"";

  static String m32(name) => "Nothing to play in \"${name}\"";

  static String m33(name) => "Nothing to queue in \"${name}\"";

  static String m34(name) => "Playing on ${name}";

  static String m35(name) => "Playing on ${name}. Choose a device";

  static String m36(count) =>
      "${Intl.plural(count, one: '${count} playlist', other: '${count} playlists')}";

  static String m37(name) => "Removed \"${name}\" from downloads";

  static String m38(host) =>
      "${host} uses a self-signed certificate, so its identity cannot be verified automatically.";

  static String m39(count) =>
      "${Intl.plural(count, one: 'Send the details of the DLNA device on your network? It stays private and is only used to build proper support for different manufacturers.', other: 'Send the details of the ${count} DLNA devices on your network? It stays private and is only used to build proper support for different manufacturers.')}";

  static String m40(count) => "Show all ${count} songs";

  static String m41(artist) => "Song • ${artist}";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} song', other: '${count} songs')}";

  static String m43(host) =>
      "JellyBox will trust ${host} from now on, even if its certificate changes. Only continue if this is your server.";

  static String m44(host) =>
      "${host} uses a certificate that cannot be verified automatically.";

  static String m45(version) => "JellyBox ${version} is available";

  static String m46(version, build) => "Version ${version} (${build})";

  static String m47(version) => "Version ${version}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "addRemoteAddress": MessageLookupByLibrary.simpleMessage(
      "Add remote address",
    ),
    "addServer": MessageLookupByLibrary.simpleMessage("Add server"),
    "addToFavourites": MessageLookupByLibrary.simpleMessage(
      "Add to favourites",
    ),
    "addToPlaylist": MessageLookupByLibrary.simpleMessage("Add to playlist"),
    "addToQueue": MessageLookupByLibrary.simpleMessage("Add to queue"),
    "addedToQueue": MessageLookupByLibrary.simpleMessage("Added to queue"),
    "addressDidNotAnswer": MessageLookupByLibrary.simpleMessage(
      "That address did not answer.",
    ),
    "addressDifferentServer": MessageLookupByLibrary.simpleMessage(
      "That address answers as a different server.",
    ),
    "airplayAndBluetooth": MessageLookupByLibrary.simpleMessage(
      "AirPlay & Bluetooth",
    ),
    "album": MessageLookupByLibrary.simpleMessage("Album"),
    "albumArtTintSetting": MessageLookupByLibrary.simpleMessage(
      "Tint album pages with cover art colours",
    ),
    "albumArtist": MessageLookupByLibrary.simpleMessage("Album Artist"),
    "albumArtists": MessageLookupByLibrary.simpleMessage("Album Artists"),
    "albums": MessageLookupByLibrary.simpleMessage("Albums"),
    "albumsCount": m0,
    "always": MessageLookupByLibrary.simpleMessage("Always"),
    "alwaysShowControls": MessageLookupByLibrary.simpleMessage(
      "Always show controls",
    ),
    "animatedAlbumCovers": MessageLookupByLibrary.simpleMessage(
      "Animated album covers",
    ),
    "animatedCoversNote": MessageLookupByLibrary.simpleMessage(
      "Looks up for animated covers and plays them on Wi-Fi only.",
    ),
    "animationSpeed": MessageLookupByLibrary.simpleMessage("Animation speed"),
    "animationSpeedNote": MessageLookupByLibrary.simpleMessage(
      "Affects Studio Mode and Landscape Mode.",
    ),
    "apiUrl": MessageLookupByLibrary.simpleMessage("API URL"),
    "apiWithName": m1,
    "appVersionLabel": m2,
    "appearsOn": MessageLookupByLibrary.simpleMessage("Appears On"),
    "artist": MessageLookupByLibrary.simpleMessage("Artist"),
    "artistNoInformation": MessageLookupByLibrary.simpleMessage(
      "This artist does not have any information.",
    ),
    "artists": MessageLookupByLibrary.simpleMessage("Artists"),
    "artworkAccentSetting": MessageLookupByLibrary.simpleMessage(
      "Match button colours to the current track",
    ),
    "asleep": MessageLookupByLibrary.simpleMessage("Asleep"),
    "autoDiscovering": MessageLookupByLibrary.simpleMessage(
      "Auto discovering...",
    ),
    "basedOn": m3,
    "broadcasts": MessageLookupByLibrary.simpleMessage("Broadcasts"),
    "browse": MessageLookupByLibrary.simpleMessage("Browse"),
    "cache": MessageLookupByLibrary.simpleMessage("Cache"),
    "cacheAhead": MessageLookupByLibrary.simpleMessage("Cache ahead"),
    "cacheEmptied": MessageLookupByLibrary.simpleMessage("Cache emptied"),
    "cacheLimit": MessageLookupByLibrary.simpleMessage("Cache limit"),
    "cachedTrack": MessageLookupByLibrary.simpleMessage("Cached track"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cards": MessageLookupByLibrary.simpleMessage("Cards"),
    "castFailed": m4,
    "castFailureReported": MessageLookupByLibrary.simpleMessage(
      "An error report was submitted and Alex will look into whether this device can be supported.",
    ),
    "castTakenOver": m5,
    "cellular": MessageLookupByLibrary.simpleMessage("Cellular"),
    "certificateNotTrusted": MessageLookupByLibrary.simpleMessage(
      "The server\'s security certificate is not trusted.",
    ),
    "changeHomeAddress": MessageLookupByLibrary.simpleMessage(
      "Change home address",
    ),
    "changeRemoteAddress": MessageLookupByLibrary.simpleMessage(
      "Change remote address",
    ),
    "changelog": MessageLookupByLibrary.simpleMessage("Changelog"),
    "chooseWhichArtistsToBrowse": MessageLookupByLibrary.simpleMessage(
      "Choose which artists to browse",
    ),
    "clearImageCache": MessageLookupByLibrary.simpleMessage(
      "Clear image cache",
    ),
    "clearImageCacheQuestion": MessageLookupByLibrary.simpleMessage(
      "Clear the image cache?",
    ),
    "clearImageCacheWarning": MessageLookupByLibrary.simpleMessage(
      "Artwork will be downloaded again from your server as you browse.",
    ),
    "clearQueue": MessageLookupByLibrary.simpleMessage("Clear queue"),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "closeLyrics": MessageLookupByLibrary.simpleMessage("Close lyrics"),
    "cloudConnectNote": MessageLookupByLibrary.simpleMessage(
      "Hitting connect will either create new account or sign in to existing account.",
    ),
    "cloudSignInIntro": MessageLookupByLibrary.simpleMessage(
      "Sign in to play across your devices - start on one, carry on with another.",
    ),
    "collapseSidebar": MessageLookupByLibrary.simpleMessage("Collapse sidebar"),
    "connect": MessageLookupByLibrary.simpleMessage("Connect"),
    "connectListenBrainz": MessageLookupByLibrary.simpleMessage(
      "Connect ListenBrainz",
    ),
    "connectedAs": m6,
    "connectedToADifferentServer": MessageLookupByLibrary.simpleMessage(
      "Connected to a different server",
    ),
    "connecting": MessageLookupByLibrary.simpleMessage("Connecting…"),
    "connection": MessageLookupByLibrary.simpleMessage("Connection"),
    "connectionProblem": MessageLookupByLibrary.simpleMessage(
      "Connection problem",
    ),
    "connectionStatus": m7,
    "contentUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Content update interval",
    ),
    "contentUpdateIntervalNote": MessageLookupByLibrary.simpleMessage(
      "How often the home page refreshes and downloaded playlists check your server for changes.",
    ),
    "continuityExperimental": MessageLookupByLibrary.simpleMessage(
      "This feature is currently experimental, so there might be bugs, issues, delays.",
    ),
    "continuityNotAvailable": MessageLookupByLibrary.simpleMessage(
      "Continuity not available",
    ),
    "continuityNotYet": MessageLookupByLibrary.simpleMessage(
      "What\'s not working currently - you can\'t wake up a sleeping phone. If your phone plays music - you can control it even if the phone is in locked mode, but if you paused playback or the app wasn\'t running at all - currently there\'s no way to turn it on and start playback. This will be added in upcoming releases.",
    ),
    "continuityPrivacy": MessageLookupByLibrary.simpleMessage(
      "NO data is shared with 3rd parties. Your content stays on your devices, and this tool just orchestrates which device plays now and sends Item IDs between devices.",
    ),
    "continuityRemoteControl": MessageLookupByLibrary.simpleMessage(
      "This feature also allows you to remotely control your other connected devices - playback, position, queue, volume.",
    ),
    "continuityReport": MessageLookupByLibrary.simpleMessage(
      "Please report any issues in Discord or via GitHub issues.",
    ),
    "continuityWhatItDoes": MessageLookupByLibrary.simpleMessage(
      "Thanks for trying the continuity feature. This feature allows you to transfer playback between your connected devices - phones, desktops, etc.",
    ),
    "copied": MessageLookupByLibrary.simpleMessage("Copied"),
    "couldNotCreatePlaylist": MessageLookupByLibrary.simpleMessage(
      "Could not create the playlist",
    ),
    "couldNotLoadLyrics": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load lyrics",
    ),
    "couldNotLoadSection": MessageLookupByLibrary.simpleMessage(
      "Could not load this section.",
    ),
    "couldNotLoadThisAlbum": MessageLookupByLibrary.simpleMessage(
      "Could not load this album.",
    ),
    "couldNotOpen": m8,
    "couldNotQueue": m9,
    "couldNotStartInstantMixFor": m10,
    "couldNotStartMixFor": m11,
    "couldNotStartPlaying": m12,
    "couldNotTakeOver": MessageLookupByLibrary.simpleMessage(
      "Could not take over",
    ),
    "coverOverVideoSetting": MessageLookupByLibrary.simpleMessage(
      "Show cover art over video background",
    ),
    "createGithubIssue": MessageLookupByLibrary.simpleMessage(
      "Create a GitHub issue",
    ),
    "createGithubIssueSubtitle": MessageLookupByLibrary.simpleMessage(
      "Report a bug or request a feature",
    ),
    "createPlaylist": MessageLookupByLibrary.simpleMessage("Create playlist"),
    "currentOnlineDevices": m13,
    "dateAdded": MessageLookupByLibrary.simpleMessage("Date Added"),
    "dateLiked": MessageLookupByLibrary.simpleMessage("Date Liked"),
    "defaultBrowseTab": MessageLookupByLibrary.simpleMessage(
      "Default browse tab",
    ),
    "defaultStartPage": MessageLookupByLibrary.simpleMessage(
      "Default start page",
    ),
    "deleteDownloadedNameQuestion": m14,
    "deleteNameQuestion": m15,
    "deletePlaylist": MessageLookupByLibrary.simpleMessage("Delete playlist"),
    "deviceListSentThankYou": MessageLookupByLibrary.simpleMessage(
      "Device list sent. Thank you!",
    ),
    "direct": MessageLookupByLibrary.simpleMessage("Direct"),
    "disableAutoGeneratedPlaylists": MessageLookupByLibrary.simpleMessage(
      "Disable auto-generated playlists",
    ),
    "discNumber": m16,
    "discogsArtist": MessageLookupByLibrary.simpleMessage("Discogs artist"),
    "discogsMaster": MessageLookupByLibrary.simpleMessage("Discogs master"),
    "discogsRelease": MessageLookupByLibrary.simpleMessage("Discogs release"),
    "disconnect": MessageLookupByLibrary.simpleMessage("Disconnect"),
    "discordPresenceSetting": MessageLookupByLibrary.simpleMessage(
      "Share what I am listening to on Discord",
    ),
    "dismiss": MessageLookupByLibrary.simpleMessage("Dismiss"),
    "donate": MessageLookupByLibrary.simpleMessage("Donate"),
    "donateSubtitle": MessageLookupByLibrary.simpleMessage(
      "This will help me to buy new devices to develop for and test on",
    ),
    "download": MessageLookupByLibrary.simpleMessage("Download"),
    "downloadSyncNote": MessageLookupByLibrary.simpleMessage(
      "Downloaded playlists follow your server: new songs are downloaded and removed songs are deleted. Otherwise this only happens on Wi-Fi.",
    ),
    "downloadSyncOnCellularSetting": MessageLookupByLibrary.simpleMessage(
      "Update downloaded playlists on cellular",
    ),
    "downloads": MessageLookupByLibrary.simpleMessage("Downloads"),
    "downloadsDeletedNote": m17,
    "downloadsStillAvailable": MessageLookupByLibrary.simpleMessage(
      "Downloads are still available",
    ),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "emailMe": MessageLookupByLibrary.simpleMessage("Email me"),
    "emptyCache": MessageLookupByLibrary.simpleMessage("Empty cache"),
    "emptyCacheQuestion": MessageLookupByLibrary.simpleMessage(
      "Empty the cache?",
    ),
    "emptyCacheWarning": MessageLookupByLibrary.simpleMessage(
      "Tracks cached ahead for offline playback will be deleted.",
    ),
    "enterAServerAddress": MessageLookupByLibrary.simpleMessage(
      "Enter a server address",
    ),
    "enterTheServerAddress": MessageLookupByLibrary.simpleMessage(
      "Enter the server address.",
    ),
    "eps": MessageLookupByLibrary.simpleMessage("EPs"),
    "errorWithDetails": m18,
    "exitStudioMode": MessageLookupByLibrary.simpleMessage("Exit studio mode"),
    "expandSidebar": MessageLookupByLibrary.simpleMessage("Expand sidebar"),
    "experimental": MessageLookupByLibrary.simpleMessage("experimental"),
    "expired": MessageLookupByLibrary.simpleMessage("Expired"),
    "expires": MessageLookupByLibrary.simpleMessage("Expires"),
    "fast": MessageLookupByLibrary.simpleMessage("Fast"),
    "favourites": MessageLookupByLibrary.simpleMessage("Favourites"),
    "forgotPassword": MessageLookupByLibrary.simpleMessage("Forgot password?"),
    "frequentlyPlayed": MessageLookupByLibrary.simpleMessage(
      "Frequently played",
    ),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "genres": MessageLookupByLibrary.simpleMessage("Genres"),
    "getTokenFromListenBrainz": MessageLookupByLibrary.simpleMessage(
      "Get your token from listenbrainz.org",
    ),
    "gigabytesLabel": m19,
    "goToAlbum": MessageLookupByLibrary.simpleMessage("Go to album"),
    "goToArtist": MessageLookupByLibrary.simpleMessage("Go to artist"),
    "gotIt": MessageLookupByLibrary.simpleMessage("Got it"),
    "hideFavourites": MessageLookupByLibrary.simpleMessage("Hide favourites"),
    "hideLyrics": MessageLookupByLibrary.simpleMessage("Hide lyrics"),
    "hideQueue": MessageLookupByLibrary.simpleMessage("Hide queue"),
    "hideRecentlyPlayed": MessageLookupByLibrary.simpleMessage(
      "Hide recently played",
    ),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "homeAddress": MessageLookupByLibrary.simpleMessage("Home address"),
    "homeAddressDescription": MessageLookupByLibrary.simpleMessage(
      "The main address of this server. Change it when the server moved to a new IP or domain; you stay signed in.",
    ),
    "homePage": MessageLookupByLibrary.simpleMessage("Home Page"),
    "homePageRefreshed": MessageLookupByLibrary.simpleMessage(
      "Home page refreshed",
    ),
    "imageCacheCleared": MessageLookupByLibrary.simpleMessage(
      "Image cache cleared",
    ),
    "invalidCredentials": MessageLookupByLibrary.simpleMessage(
      "Incorrect login or password",
    ),
    "isPublic": MessageLookupByLibrary.simpleMessage("Is public"),
    "issuedBy": MessageLookupByLibrary.simpleMessage("Issued by"),
    "issuedTo": MessageLookupByLibrary.simpleMessage("Issued to"),
    "jellyboxCantConnect": MessageLookupByLibrary.simpleMessage(
      "JellyBox can\'t connect to your server",
    ),
    "joinDiscord": MessageLookupByLibrary.simpleMessage("Join Discord"),
    "joinDiscordSubtitle": MessageLookupByLibrary.simpleMessage(
      "Chat with the me (Alex, the developer) and other users",
    ),
    "kbpsLabel": m20,
    "keepTheScreenOn": MessageLookupByLibrary.simpleMessage(
      "Keep the screen on",
    ),
    "landscapePlayer": MessageLookupByLibrary.simpleMessage("Landscape player"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "left": MessageLookupByLibrary.simpleMessage("Left"),
    "letterRulerSetting": MessageLookupByLibrary.simpleMessage(
      "Show A–Z index on browse lists sorted by name",
    ),
    "librariesLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Could not load your libraries.",
    ),
    "librariesOfflineMessage": MessageLookupByLibrary.simpleMessage(
      "You\'re offline, so your libraries can\'t be loaded.",
    ),
    "library": MessageLookupByLibrary.simpleMessage("Library"),
    "like": MessageLookupByLibrary.simpleMessage("Like"),
    "liked": MessageLookupByLibrary.simpleMessage("Liked"),
    "likedSongs": MessageLookupByLibrary.simpleMessage("Liked songs"),
    "likedSongsNotDownloaded": MessageLookupByLibrary.simpleMessage(
      "Liked songs are not downloaded.",
    ),
    "loadMore": MessageLookupByLibrary.simpleMessage("Load more…"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading…"),
    "logOut": MessageLookupByLibrary.simpleMessage("Log out"),
    "logOutOfAllServers": MessageLookupByLibrary.simpleMessage(
      "Log out of all servers",
    ),
    "logOutOfName": m21,
    "logOutOfServer": m22,
    "logOutOfThisServer": MessageLookupByLibrary.simpleMessage(
      "Log out of this server",
    ),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "lrclibLyricsNote": MessageLookupByLibrary.simpleMessage(
      "When your server has no lyrics for a song, looks them up on lrclib.net, a free public lyrics library.",
    ),
    "lrclibLyricsSetting": MessageLookupByLibrary.simpleMessage(
      "Find missing lyrics on LRCLIB",
    ),
    "lyrics": MessageLookupByLibrary.simpleMessage("Lyrics"),
    "lyricsTextAlignment": MessageLookupByLibrary.simpleMessage(
      "Lyrics text alignment",
    ),
    "madeForYou": MessageLookupByLibrary.simpleMessage("Made for you"),
    "medium": MessageLookupByLibrary.simpleMessage("Medium"),
    "megabytesLabel": m23,
    "middle": MessageLookupByLibrary.simpleMessage("Middle"),
    "minutesAbbreviated": m24,
    "minutesCount": m25,
    "minutesShort": m26,
    "mixNoLongerAvailable": MessageLookupByLibrary.simpleMessage(
      "This mix is no longer available",
    ),
    "mixOrder": MessageLookupByLibrary.simpleMessage("Mix order"),
    "more": MessageLookupByLibrary.simpleMessage("More"),
    "moreFrom": m27,
    "mostPlayedLast30Days": MessageLookupByLibrary.simpleMessage(
      "Most played in the last 30 days",
    ),
    "musicBrainzArtist": MessageLookupByLibrary.simpleMessage(
      "MusicBrainz artist",
    ),
    "musicBrainzRecording": MessageLookupByLibrary.simpleMessage(
      "MusicBrainz recording",
    ),
    "musicBrainzRelease": MessageLookupByLibrary.simpleMessage(
      "MusicBrainz release",
    ),
    "musicBrainzReleaseGroup": MessageLookupByLibrary.simpleMessage(
      "MusicBrainz release group",
    ),
    "musicBrainzTrack": MessageLookupByLibrary.simpleMessage(
      "MusicBrainz track",
    ),
    "mute": MessageLookupByLibrary.simpleMessage("Mute"),
    "myNewPlaylist": MessageLookupByLibrary.simpleMessage("My new playlist"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameMix": m28,
    "never": MessageLookupByLibrary.simpleMessage("Never"),
    "newPlaylist": MessageLookupByLibrary.simpleMessage("New playlist"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noCastOrDlnaDevicesFound": MessageLookupByLibrary.simpleMessage(
      "No Cast or DLNA devices found on this network.",
    ),
    "noDlnaDevicesFound": MessageLookupByLibrary.simpleMessage(
      "No DLNA devices found on this network.",
    ),
    "noDownloads": MessageLookupByLibrary.simpleMessage("No downloads"),
    "noDownloadsYet": MessageLookupByLibrary.simpleMessage("No downloads yet"),
    "noFavouritesYet": MessageLookupByLibrary.simpleMessage(
      "You haven\'t favourited anything yet.",
    ),
    "noLibrariesFound": MessageLookupByLibrary.simpleMessage(
      "No libraries found :(",
    ),
    "noLyricsForThisTrack": MessageLookupByLibrary.simpleMessage(
      "No lyrics for this track",
    ),
    "noMixAvailableFor": m29,
    "noResults": MessageLookupByLibrary.simpleMessage("No results"),
    "noResultsFor": m30,
    "noSongsFoundFor": m31,
    "noSongsInThisAlbum": MessageLookupByLibrary.simpleMessage(
      "No songs in this album",
    ),
    "noSongsYet": MessageLookupByLibrary.simpleMessage(
      "There\'s no songs yet.",
    ),
    "none": MessageLookupByLibrary.simpleMessage("None"),
    "notAvailableOffline": MessageLookupByLibrary.simpleMessage(
      "Not available offline",
    ),
    "notNow": MessageLookupByLibrary.simpleMessage("Not now"),
    "nothingFound": MessageLookupByLibrary.simpleMessage("Nothing found"),
    "nothingHereYet": MessageLookupByLibrary.simpleMessage("Nothing here yet."),
    "nothingInQueue": MessageLookupByLibrary.simpleMessage("Nothing in queue"),
    "nothingPlayedLast30Days": MessageLookupByLibrary.simpleMessage(
      "Nothing played in the last 30 days.",
    ),
    "nothingPlaying": MessageLookupByLibrary.simpleMessage("Nothing playing"),
    "nothingToDownload": MessageLookupByLibrary.simpleMessage(
      "Nothing to download",
    ),
    "nothingToPlayIn": m32,
    "nothingToQueueIn": m33,
    "nowPlayingHaloSetting": MessageLookupByLibrary.simpleMessage(
      "Enable halo effect for currently playing media",
    ),
    "off": MessageLookupByLibrary.simpleMessage("Off"),
    "offline": MessageLookupByLibrary.simpleMessage("Offline"),
    "offlineAlbumNotDownloaded": MessageLookupByLibrary.simpleMessage(
      "You\'re offline and this album isn\'t downloaded.",
    ),
    "offlineFavouritesNotice": MessageLookupByLibrary.simpleMessage(
      "You\'re offline. Your favourites will be back once the server is reachable.",
    ),
    "offlineGenreNotice": MessageLookupByLibrary.simpleMessage(
      "You\'re offline. This genre needs a connection.",
    ),
    "offlineLibraryNotice": MessageLookupByLibrary.simpleMessage(
      "You\'re offline. Your library will be back once the server is reachable.",
    ),
    "offlineOnlyDownloads": MessageLookupByLibrary.simpleMessage(
      "Offline — only downloads are available",
    ),
    "offlinePlaylistsNotice": MessageLookupByLibrary.simpleMessage(
      "You\'re offline, so playlists need a connection.",
    ),
    "offlineSearchNotice": MessageLookupByLibrary.simpleMessage(
      "You\'re offline, so search needs a connection.",
    ),
    "onRepeat": MessageLookupByLibrary.simpleMessage("On repeat"),
    "open": MessageLookupByLibrary.simpleMessage("Open"),
    "openDownloads": MessageLookupByLibrary.simpleMessage("Open downloads"),
    "openJellyboxToConnect": MessageLookupByLibrary.simpleMessage(
      "Open JellyBox to connect to your server",
    ),
    "openOnIphoneToStart": MessageLookupByLibrary.simpleMessage(
      "Open JellyBox on your iPhone to get started",
    ),
    "original": MessageLookupByLibrary.simpleMessage("Original"),
    "other": MessageLookupByLibrary.simpleMessage("Other"),
    "paletteSettings": MessageLookupByLibrary.simpleMessage("Palette settings"),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "pasteListenBrainzToken": MessageLookupByLibrary.simpleMessage(
      "Paste the user token from your ListenBrainz settings.",
    ),
    "play": MessageLookupByLibrary.simpleMessage("Play"),
    "playAlbum": MessageLookupByLibrary.simpleMessage("Play album"),
    "playAll": MessageLookupByLibrary.simpleMessage("Play all"),
    "playArtist": MessageLookupByLibrary.simpleMessage("Play artist"),
    "playDisc": MessageLookupByLibrary.simpleMessage("Play disc"),
    "playGenre": MessageLookupByLibrary.simpleMessage("Play genre"),
    "playNext": MessageLookupByLibrary.simpleMessage("Play next"),
    "playOn": MessageLookupByLibrary.simpleMessage("Play on"),
    "playOnADevice": MessageLookupByLibrary.simpleMessage("Play on a device"),
    "playPlaylist": MessageLookupByLibrary.simpleMessage("Play playlist"),
    "playing": MessageLookupByLibrary.simpleMessage("Playing"),
    "playingNext": MessageLookupByLibrary.simpleMessage("Playing next"),
    "playingOn": m34,
    "playingOnADifferentServer": MessageLookupByLibrary.simpleMessage(
      "Playing on a different server",
    ),
    "playingOnChooseDevice": m35,
    "playlist": MessageLookupByLibrary.simpleMessage("Playlist"),
    "playlistName": MessageLookupByLibrary.simpleMessage("Playlist name"),
    "playlistNoSongsYet": MessageLookupByLibrary.simpleMessage(
      "This playlist has no songs yet.",
    ),
    "playlistOrder": MessageLookupByLibrary.simpleMessage("Playlist order"),
    "playlists": MessageLookupByLibrary.simpleMessage("Playlists"),
    "playlistsCount": m36,
    "pluginOutOfDateNotice": MessageLookupByLibrary.simpleMessage(
      "The JellyBox Relay plugin on this server is out of date. A server admin can update it under Dashboard → Plugins.",
    ),
    "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
    "queue": MessageLookupByLibrary.simpleMessage("Queue"),
    "queueCache": MessageLookupByLibrary.simpleMessage("Queue cache"),
    "queueIsEmpty": MessageLookupByLibrary.simpleMessage("Queue is empty"),
    "quickConnectExpired": MessageLookupByLibrary.simpleMessage(
      "The Quick Connect code expired. Try again.",
    ),
    "quickConnectInstructions": MessageLookupByLibrary.simpleMessage(
      "On a device where you are already signed in, open Quick Connect in your user settings and enter this code.",
    ),
    "quickConnectUnavailable": MessageLookupByLibrary.simpleMessage(
      "Quick Connect is not available on this server.",
    ),
    "random": MessageLookupByLibrary.simpleMessage("Random"),
    "readMore": MessageLookupByLibrary.simpleMessage("Read more"),
    "rebuildMixesDebug": MessageLookupByLibrary.simpleMessage(
      "Rebuild mixes (debug)",
    ),
    "recentlyAdded": MessageLookupByLibrary.simpleMessage("Recently added"),
    "recentlyPlayed": MessageLookupByLibrary.simpleMessage("Recently played"),
    "refreshNow": MessageLookupByLibrary.simpleMessage("Refresh now"),
    "relayNoPassword": MessageLookupByLibrary.simpleMessage(
      "Remote access needs a password on your Jellyfin user.",
    ),
    "relayNotSetUp": MessageLookupByLibrary.simpleMessage(
      "No remote access address for this server yet.",
    ),
    "relayPlanFull": MessageLookupByLibrary.simpleMessage(
      "This server\'s Jellybox Cloud plan has no free seat for your user. Ask the owner to make room.",
    ),
    "remote": MessageLookupByLibrary.simpleMessage("Remote"),
    "remoteAddress": MessageLookupByLibrary.simpleMessage("Remote address"),
    "remoteAddressDescription": MessageLookupByLibrary.simpleMessage(
      "A second address for the same server, such as a Tailscale, WireGuard or reverse proxy URL. Jellybox uses the home address when it answers and switches to this one when it does not.",
    ),
    "removeDownload": MessageLookupByLibrary.simpleMessage("Remove download"),
    "removeFromFavourites": MessageLookupByLibrary.simpleMessage(
      "Remove from favourites",
    ),
    "removeFromPlaylist": MessageLookupByLibrary.simpleMessage(
      "Remove from playlist",
    ),
    "removeFromQueue": MessageLookupByLibrary.simpleMessage(
      "Remove from queue",
    ),
    "removeRemoteAddress": MessageLookupByLibrary.simpleMessage(
      "Remove remote address",
    ),
    "removedFromDownloads": m37,
    "removedFromPlaylist": MessageLookupByLibrary.simpleMessage(
      "Successfully removed item from playlist",
    ),
    "repeat": MessageLookupByLibrary.simpleMessage("Repeat"),
    "repeatAll": MessageLookupByLibrary.simpleMessage("Repeat all"),
    "repeatOne": MessageLookupByLibrary.simpleMessage("Repeat one"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "right": MessageLookupByLibrary.simpleMessage("Right"),
    "rows": MessageLookupByLibrary.simpleMessage("Rows"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "scanAgain": MessageLookupByLibrary.simpleMessage("Scan again"),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "searchFailedTryAgain": MessageLookupByLibrary.simpleMessage(
      "Search failed. Try again.",
    ),
    "selectAPlaylist": MessageLookupByLibrary.simpleMessage(
      "Select a playlist",
    ),
    "selectLibrary": MessageLookupByLibrary.simpleMessage("Select Library"),
    "selfSignedCertificate": m38,
    "serverAlreadyAdded": MessageLookupByLibrary.simpleMessage(
      "This server is already added.",
    ),
    "serverSpeaksMultipleApis": MessageLookupByLibrary.simpleMessage(
      "This server speaks more than one API",
    ),
    "serverUrl": MessageLookupByLibrary.simpleMessage("Server URL"),
    "serverUrlAndLoginRequired": MessageLookupByLibrary.simpleMessage(
      "Server URL and login are required",
    ),
    "serverUrlInvalid": MessageLookupByLibrary.simpleMessage(
      "Server URL is invalid. Try something like 192.168.1.10:8096 or jellyfin.example.com",
    ),
    "serverUrlRequired": MessageLookupByLibrary.simpleMessage(
      "Server URL is required",
    ),
    "servers": MessageLookupByLibrary.simpleMessage("Servers"),
    "setUpRelayPlugin": MessageLookupByLibrary.simpleMessage(
      "Set up the JellyBox Relay plugin",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "share": MessageLookupByLibrary.simpleMessage("Share"),
    "shareDeviceListWithDeveloper": MessageLookupByLibrary.simpleMessage(
      "Share this device list with the developer",
    ),
    "shareDevicesDialogBody": m39,
    "shareWhatJellyboxFound": MessageLookupByLibrary.simpleMessage(
      "Share what JellyBox found?",
    ),
    "showAllSongs": m40,
    "showLess": MessageLookupByLibrary.simpleMessage("Show less"),
    "shuffle": MessageLookupByLibrary.simpleMessage("Shuffle"),
    "shuffleOn": MessageLookupByLibrary.simpleMessage("Shuffle on"),
    "shufflePlay": MessageLookupByLibrary.simpleMessage("Shuffle play"),
    "signIn": MessageLookupByLibrary.simpleMessage("Sign in"),
    "signInAgain": MessageLookupByLibrary.simpleMessage("Sign in again"),
    "signInOnYourPhone": MessageLookupByLibrary.simpleMessage(
      "Sign in on your phone",
    ),
    "signInToStartListening": MessageLookupByLibrary.simpleMessage(
      "Sign in to start listening",
    ),
    "signedOutOfThisServer": MessageLookupByLibrary.simpleMessage(
      "You will be signed out of this server.",
    ),
    "singles": MessageLookupByLibrary.simpleMessage("Singles"),
    "sleepTimer": MessageLookupByLibrary.simpleMessage("Sleep timer"),
    "sleepTimerAt": MessageLookupByLibrary.simpleMessage("at"),
    "sleepTimerStopIn": MessageLookupByLibrary.simpleMessage("Stop in"),
    "sleepTimerTracks": MessageLookupByLibrary.simpleMessage("tracks"),
    "slow": MessageLookupByLibrary.simpleMessage("Slow"),
    "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Uff! Something went wrong...",
    ),
    "song": MessageLookupByLibrary.simpleMessage("Song"),
    "songWithArtist": m41,
    "songs": MessageLookupByLibrary.simpleMessage("Songs"),
    "songsCount": m42,
    "sort": MessageLookupByLibrary.simpleMessage("Sort"),
    "sortBy": MessageLookupByLibrary.simpleMessage("Sort by"),
    "soundsLike": MessageLookupByLibrary.simpleMessage("Sounds like"),
    "startAlbumMix": MessageLookupByLibrary.simpleMessage("Start album mix"),
    "startArtistMix": MessageLookupByLibrary.simpleMessage("Start artist mix"),
    "startGenreMix": MessageLookupByLibrary.simpleMessage("Start genre mix"),
    "startGenreRadio": MessageLookupByLibrary.simpleMessage(
      "Start genre radio",
    ),
    "startSongMix": MessageLookupByLibrary.simpleMessage("Start song mix"),
    "stopDownload": MessageLookupByLibrary.simpleMessage("Stop download"),
    "stopTimer": MessageLookupByLibrary.simpleMessage("Stop timer"),
    "streaming": MessageLookupByLibrary.simpleMessage("Streaming"),
    "streamingQuality": MessageLookupByLibrary.simpleMessage(
      "Streaming quality",
    ),
    "streamingQualityNote": MessageLookupByLibrary.simpleMessage(
      "Songs above the limit are converted by your server. Changes apply from the next song. Downloads always keep the original quality.",
    ),
    "studioMode": MessageLookupByLibrary.simpleMessage("Studio Mode"),
    "studioModeFullscreenSetting": MessageLookupByLibrary.simpleMessage(
      "Make player full screen when Studio Mode enabled",
    ),
    "studioModeTooltip": MessageLookupByLibrary.simpleMessage("Studio mode"),
    "successfullyAddedToPlaylist": MessageLookupByLibrary.simpleMessage(
      "Successfully added to playlist",
    ),
    "successfullyDeletedAlbum": MessageLookupByLibrary.simpleMessage(
      "Successfully deleted album",
    ),
    "successfullyDeletedPlaylist": MessageLookupByLibrary.simpleMessage(
      "Successfully deleted playlist",
    ),
    "support": MessageLookupByLibrary.simpleMessage("Support"),
    "supportEmailSubject": MessageLookupByLibrary.simpleMessage(
      "JellyBox support",
    ),
    "supportIntro": MessageLookupByLibrary.simpleMessage(
      "Questions, problems or ideas? Get in touch. Please try to report as much details as possible - that will help me to identify issue and help you with resolving it.",
    ),
    "switchServer": MessageLookupByLibrary.simpleMessage("Switch server"),
    "system": MessageLookupByLibrary.simpleMessage("System"),
    "tapCodeToCopy": MessageLookupByLibrary.simpleMessage(
      "Tap the code to copy it",
    ),
    "tapToConnect": MessageLookupByLibrary.simpleMessage("Tap to connect"),
    "telemetryNote": MessageLookupByLibrary.simpleMessage(
      "Jellybox counts app launches and sends crash reports to help fix bugs. Nothing about your library or listening is collected.",
    ),
    "telemetryOptOutSetting": MessageLookupByLibrary.simpleMessage(
      "Opt out of analytics and crash reports",
    ),
    "theAudioDbAlbum": MessageLookupByLibrary.simpleMessage("TheAudioDB album"),
    "theAudioDbArtist": MessageLookupByLibrary.simpleMessage(
      "TheAudioDB artist",
    ),
    "thisActionNeedsAConnection": MessageLookupByLibrary.simpleMessage(
      "This action needs a connection",
    ),
    "thisDevice": MessageLookupByLibrary.simpleMessage("This device"),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "trust": MessageLookupByLibrary.simpleMessage("Trust"),
    "trustFromNowOn": m43,
    "tryAgain": MessageLookupByLibrary.simpleMessage("Try again"),
    "tunnel": MessageLookupByLibrary.simpleMessage("Tunnel"),
    "tunnelNotAnswering": MessageLookupByLibrary.simpleMessage(
      "Remote access is set up, but the tunnel is not answering.",
    ),
    "tunnelReady": MessageLookupByLibrary.simpleMessage(
      "Remote access is set up and the tunnel is ready.",
    ),
    "ui": MessageLookupByLibrary.simpleMessage("UI"),
    "unmute": MessageLookupByLibrary.simpleMessage("Unmute"),
    "untrustedCertificate": MessageLookupByLibrary.simpleMessage(
      "Untrusted certificate",
    ),
    "unverifiableCertificate": m44,
    "updateAvailable": m45,
    "useVideoCoversSetting": MessageLookupByLibrary.simpleMessage(
      "Use video covers when available",
    ),
    "userToken": MessageLookupByLibrary.simpleMessage("User token"),
    "versionBuildLabel": m46,
    "versionLabel": m47,
    "viewOn": MessageLookupByLibrary.simpleMessage("View on"),
    "waitingForApproval": MessageLookupByLibrary.simpleMessage(
      "Waiting for approval",
    ),
    "wakingUp": MessageLookupByLibrary.simpleMessage("Waking up…"),
    "whatsNew": MessageLookupByLibrary.simpleMessage("What\'s new"),
    "whileCharging": MessageLookupByLibrary.simpleMessage("While charging"),
    "wifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "youMayAlsoLike": MessageLookupByLibrary.simpleMessage("You may also like"),
    "yourDevice": MessageLookupByLibrary.simpleMessage("Your device"),
  };
}
