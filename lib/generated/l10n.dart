// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: '', args: []);
  }

  /// `Add remote address`
  String get addRemoteAddress {
    return Intl.message(
      'Add remote address',
      name: 'addRemoteAddress',
      desc: '',
      args: [],
    );
  }

  /// `Add server`
  String get addServer {
    return Intl.message('Add server', name: 'addServer', desc: '', args: []);
  }

  /// `Add to favourites`
  String get addToFavourites {
    return Intl.message(
      'Add to favourites',
      name: 'addToFavourites',
      desc: '',
      args: [],
    );
  }

  /// `Add to playlist`
  String get addToPlaylist {
    return Intl.message(
      'Add to playlist',
      name: 'addToPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Add to queue`
  String get addToQueue {
    return Intl.message('Add to queue', name: 'addToQueue', desc: '', args: []);
  }

  /// `Added to queue`
  String get addedToQueue {
    return Intl.message(
      'Added to queue',
      name: 'addedToQueue',
      desc: '',
      args: [],
    );
  }

  /// `That address did not answer.`
  String get addressDidNotAnswer {
    return Intl.message(
      'That address did not answer.',
      name: 'addressDidNotAnswer',
      desc: '',
      args: [],
    );
  }

  /// `That address answers as a different server.`
  String get addressDifferentServer {
    return Intl.message(
      'That address answers as a different server.',
      name: 'addressDifferentServer',
      desc: '',
      args: [],
    );
  }

  /// `AirPlay & Bluetooth`
  String get airplayAndBluetooth {
    return Intl.message(
      'AirPlay & Bluetooth',
      name: 'airplayAndBluetooth',
      desc: '',
      args: [],
    );
  }

  /// `Album`
  String get album {
    return Intl.message('Album', name: 'album', desc: '', args: []);
  }

  /// `Tint album pages with cover art colours`
  String get albumArtTintSetting {
    return Intl.message(
      'Tint album pages with cover art colours',
      name: 'albumArtTintSetting',
      desc: '',
      args: [],
    );
  }

  /// `Album Artist`
  String get albumArtist {
    return Intl.message(
      'Album Artist',
      name: 'albumArtist',
      desc: '',
      args: [],
    );
  }

  /// `Album Artists`
  String get albumArtists {
    return Intl.message(
      'Album Artists',
      name: 'albumArtists',
      desc: '',
      args: [],
    );
  }

  /// `Albums`
  String get albums {
    return Intl.message('Albums', name: 'albums', desc: '', args: []);
  }

  /// `{count, plural, one{{count} album} other{{count} albums}}`
  String albumsCount(int count) {
    return Intl.plural(
      count,
      one: '$count album',
      other: '$count albums',
      name: 'albumsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Always`
  String get always {
    return Intl.message('Always', name: 'always', desc: '', args: []);
  }

  /// `Always show controls`
  String get alwaysShowControls {
    return Intl.message(
      'Always show controls',
      name: 'alwaysShowControls',
      desc: '',
      args: [],
    );
  }

  /// `Animated album covers`
  String get animatedAlbumCovers {
    return Intl.message(
      'Animated album covers',
      name: 'animatedAlbumCovers',
      desc: '',
      args: [],
    );
  }

  /// `Looks up for animated covers and plays them on Wi-Fi only.`
  String get animatedCoversNote {
    return Intl.message(
      'Looks up for animated covers and plays them on Wi-Fi only.',
      name: 'animatedCoversNote',
      desc: '',
      args: [],
    );
  }

  /// `Animation speed`
  String get animationSpeed {
    return Intl.message(
      'Animation speed',
      name: 'animationSpeed',
      desc: '',
      args: [],
    );
  }

  /// `Affects Studio Mode and Landscape Mode.`
  String get animationSpeedNote {
    return Intl.message(
      'Affects Studio Mode and Landscape Mode.',
      name: 'animationSpeedNote',
      desc: '',
      args: [],
    );
  }

  /// `API URL`
  String get apiUrl {
    return Intl.message('API URL', name: 'apiUrl', desc: '', args: []);
  }

  /// `{name} API`
  String apiWithName(String name) {
    return Intl.message(
      '$name API',
      name: 'apiWithName',
      desc: '',
      args: [name],
    );
  }

  /// `App version: {version}`
  String appVersionLabel(String version) {
    return Intl.message(
      'App version: $version',
      name: 'appVersionLabel',
      desc: '',
      args: [version],
    );
  }

  /// `Appears On`
  String get appearsOn {
    return Intl.message('Appears On', name: 'appearsOn', desc: '', args: []);
  }

  /// `Artist`
  String get artist {
    return Intl.message('Artist', name: 'artist', desc: '', args: []);
  }

  /// `This artist does not have any information.`
  String get artistNoInformation {
    return Intl.message(
      'This artist does not have any information.',
      name: 'artistNoInformation',
      desc: '',
      args: [],
    );
  }

  /// `Artists`
  String get artists {
    return Intl.message('Artists', name: 'artists', desc: '', args: []);
  }

  /// `Match button colours to the current track`
  String get artworkAccentSetting {
    return Intl.message(
      'Match button colours to the current track',
      name: 'artworkAccentSetting',
      desc: '',
      args: [],
    );
  }

  /// `Asleep`
  String get asleep {
    return Intl.message('Asleep', name: 'asleep', desc: '', args: []);
  }

  /// `Auto discovering...`
  String get autoDiscovering {
    return Intl.message(
      'Auto discovering...',
      name: 'autoDiscovering',
      desc: '',
      args: [],
    );
  }

  /// `Based on {name}`
  String basedOn(String name) {
    return Intl.message(
      'Based on $name',
      name: 'basedOn',
      desc: '',
      args: [name],
    );
  }

  /// `Broadcasts`
  String get broadcasts {
    return Intl.message('Broadcasts', name: 'broadcasts', desc: '', args: []);
  }

  /// `Browse`
  String get browse {
    return Intl.message('Browse', name: 'browse', desc: '', args: []);
  }

  /// `Cache`
  String get cache {
    return Intl.message('Cache', name: 'cache', desc: '', args: []);
  }

  /// `Cache ahead`
  String get cacheAhead {
    return Intl.message('Cache ahead', name: 'cacheAhead', desc: '', args: []);
  }

  /// `Cache emptied`
  String get cacheEmptied {
    return Intl.message(
      'Cache emptied',
      name: 'cacheEmptied',
      desc: '',
      args: [],
    );
  }

  /// `Cache limit`
  String get cacheLimit {
    return Intl.message('Cache limit', name: 'cacheLimit', desc: '', args: []);
  }

  /// `Cached track`
  String get cachedTrack {
    return Intl.message(
      'Cached track',
      name: 'cachedTrack',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Cards`
  String get cards {
    return Intl.message('Cards', name: 'cards', desc: '', args: []);
  }

  /// `Unable to cast to {deviceName} — switched back to this device.`
  String castFailed(String deviceName) {
    return Intl.message(
      'Unable to cast to $deviceName — switched back to this device.',
      name: 'castFailed',
      desc: '',
      args: [deviceName],
    );
  }

  /// `An error report was submitted and Alex will look into whether this device can be supported.`
  String get castFailureReported {
    return Intl.message(
      'An error report was submitted and Alex will look into whether this device can be supported.',
      name: 'castFailureReported',
      desc: '',
      args: [],
    );
  }

  /// `{deviceName} is now playing something else — switched back to this device.`
  String castTakenOver(String deviceName) {
    return Intl.message(
      '$deviceName is now playing something else — switched back to this device.',
      name: 'castTakenOver',
      desc: '',
      args: [deviceName],
    );
  }

  /// `Cellular`
  String get cellular {
    return Intl.message('Cellular', name: 'cellular', desc: '', args: []);
  }

  /// `The server's security certificate is not trusted.`
  String get certificateNotTrusted {
    return Intl.message(
      'The server\'s security certificate is not trusted.',
      name: 'certificateNotTrusted',
      desc: '',
      args: [],
    );
  }

  /// `Change home address`
  String get changeHomeAddress {
    return Intl.message(
      'Change home address',
      name: 'changeHomeAddress',
      desc: '',
      args: [],
    );
  }

  /// `Change remote address`
  String get changeRemoteAddress {
    return Intl.message(
      'Change remote address',
      name: 'changeRemoteAddress',
      desc: '',
      args: [],
    );
  }

  /// `Changelog`
  String get changelog {
    return Intl.message('Changelog', name: 'changelog', desc: '', args: []);
  }

  /// `Choose which artists to browse`
  String get chooseWhichArtistsToBrowse {
    return Intl.message(
      'Choose which artists to browse',
      name: 'chooseWhichArtistsToBrowse',
      desc: '',
      args: [],
    );
  }

  /// `Clear image cache`
  String get clearImageCache {
    return Intl.message(
      'Clear image cache',
      name: 'clearImageCache',
      desc: '',
      args: [],
    );
  }

  /// `Clear the image cache?`
  String get clearImageCacheQuestion {
    return Intl.message(
      'Clear the image cache?',
      name: 'clearImageCacheQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Artwork will be downloaded again from your server as you browse.`
  String get clearImageCacheWarning {
    return Intl.message(
      'Artwork will be downloaded again from your server as you browse.',
      name: 'clearImageCacheWarning',
      desc: '',
      args: [],
    );
  }

  /// `Clear queue`
  String get clearQueue {
    return Intl.message('Clear queue', name: 'clearQueue', desc: '', args: []);
  }

  /// `Close`
  String get close {
    return Intl.message('Close', name: 'close', desc: '', args: []);
  }

  /// `Close lyrics`
  String get closeLyrics {
    return Intl.message(
      'Close lyrics',
      name: 'closeLyrics',
      desc: '',
      args: [],
    );
  }

  /// `Hitting connect will either create new account or sign in to existing account.`
  String get cloudConnectNote {
    return Intl.message(
      'Hitting connect will either create new account or sign in to existing account.',
      name: 'cloudConnectNote',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to play across your devices - start on one, carry on with another.`
  String get cloudSignInIntro {
    return Intl.message(
      'Sign in to play across your devices - start on one, carry on with another.',
      name: 'cloudSignInIntro',
      desc: '',
      args: [],
    );
  }

  /// `Collapse sidebar`
  String get collapseSidebar {
    return Intl.message(
      'Collapse sidebar',
      name: 'collapseSidebar',
      desc: '',
      args: [],
    );
  }

  /// `Connect`
  String get connect {
    return Intl.message('Connect', name: 'connect', desc: '', args: []);
  }

  /// `Connect ListenBrainz`
  String get connectListenBrainz {
    return Intl.message(
      'Connect ListenBrainz',
      name: 'connectListenBrainz',
      desc: '',
      args: [],
    );
  }

  /// `Connected as {name}`
  String connectedAs(String name) {
    return Intl.message(
      'Connected as $name',
      name: 'connectedAs',
      desc: '',
      args: [name],
    );
  }

  /// `Connected to a different server`
  String get connectedToADifferentServer {
    return Intl.message(
      'Connected to a different server',
      name: 'connectedToADifferentServer',
      desc: '',
      args: [],
    );
  }

  /// `Connecting…`
  String get connecting {
    return Intl.message('Connecting…', name: 'connecting', desc: '', args: []);
  }

  /// `Connection`
  String get connection {
    return Intl.message('Connection', name: 'connection', desc: '', args: []);
  }

  /// `Connection problem`
  String get connectionProblem {
    return Intl.message(
      'Connection problem',
      name: 'connectionProblem',
      desc: '',
      args: [],
    );
  }

  /// `Connection: {status}`
  String connectionStatus(String status) {
    return Intl.message(
      'Connection: $status',
      name: 'connectionStatus',
      desc: '',
      args: [status],
    );
  }

  /// `Content update interval`
  String get contentUpdateInterval {
    return Intl.message(
      'Content update interval',
      name: 'contentUpdateInterval',
      desc: '',
      args: [],
    );
  }

  /// `How often the home page refreshes and downloaded playlists check your server for changes.`
  String get contentUpdateIntervalNote {
    return Intl.message(
      'How often the home page refreshes and downloaded playlists check your server for changes.',
      name: 'contentUpdateIntervalNote',
      desc: '',
      args: [],
    );
  }

  /// `This feature is currently experimental, so there might be bugs, issues, delays.`
  String get continuityExperimental {
    return Intl.message(
      'This feature is currently experimental, so there might be bugs, issues, delays.',
      name: 'continuityExperimental',
      desc: '',
      args: [],
    );
  }

  /// `Continuity not available`
  String get continuityNotAvailable {
    return Intl.message(
      'Continuity not available',
      name: 'continuityNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `What's not working currently - you can't wake up a sleeping phone. If your phone plays music - you can control it even if the phone is in locked mode, but if you paused playback or the app wasn't running at all - currently there's no way to turn it on and start playback. This will be added in upcoming releases.`
  String get continuityNotYet {
    return Intl.message(
      'What\'s not working currently - you can\'t wake up a sleeping phone. If your phone plays music - you can control it even if the phone is in locked mode, but if you paused playback or the app wasn\'t running at all - currently there\'s no way to turn it on and start playback. This will be added in upcoming releases.',
      name: 'continuityNotYet',
      desc: '',
      args: [],
    );
  }

  /// `NO data is shared with 3rd parties. Your content stays on your devices, and this tool just orchestrates which device plays now and sends Item IDs between devices.`
  String get continuityPrivacy {
    return Intl.message(
      'NO data is shared with 3rd parties. Your content stays on your devices, and this tool just orchestrates which device plays now and sends Item IDs between devices.',
      name: 'continuityPrivacy',
      desc: '',
      args: [],
    );
  }

  /// `This feature also allows you to remotely control your other connected devices - playback, position, queue, volume.`
  String get continuityRemoteControl {
    return Intl.message(
      'This feature also allows you to remotely control your other connected devices - playback, position, queue, volume.',
      name: 'continuityRemoteControl',
      desc: '',
      args: [],
    );
  }

  /// `Please report any issues in Discord or via GitHub issues.`
  String get continuityReport {
    return Intl.message(
      'Please report any issues in Discord or via GitHub issues.',
      name: 'continuityReport',
      desc: '',
      args: [],
    );
  }

  /// `Thanks for trying the continuity feature. This feature allows you to transfer playback between your connected devices - phones, desktops, etc.`
  String get continuityWhatItDoes {
    return Intl.message(
      'Thanks for trying the continuity feature. This feature allows you to transfer playback between your connected devices - phones, desktops, etc.',
      name: 'continuityWhatItDoes',
      desc: '',
      args: [],
    );
  }

  /// `Copied`
  String get copied {
    return Intl.message('Copied', name: 'copied', desc: '', args: []);
  }

  /// `Could not create the playlist`
  String get couldNotCreatePlaylist {
    return Intl.message(
      'Could not create the playlist',
      name: 'couldNotCreatePlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load lyrics`
  String get couldNotLoadLyrics {
    return Intl.message(
      'Couldn\'t load lyrics',
      name: 'couldNotLoadLyrics',
      desc: '',
      args: [],
    );
  }

  /// `Could not load this section.`
  String get couldNotLoadSection {
    return Intl.message(
      'Could not load this section.',
      name: 'couldNotLoadSection',
      desc: '',
      args: [],
    );
  }

  /// `Could not load this album.`
  String get couldNotLoadThisAlbum {
    return Intl.message(
      'Could not load this album.',
      name: 'couldNotLoadThisAlbum',
      desc: '',
      args: [],
    );
  }

  /// `Could not open {name}`
  String couldNotOpen(String name) {
    return Intl.message(
      'Could not open $name',
      name: 'couldNotOpen',
      desc: '',
      args: [name],
    );
  }

  /// `Could not queue {name}`
  String couldNotQueue(String name) {
    return Intl.message(
      'Could not queue $name',
      name: 'couldNotQueue',
      desc: '',
      args: [name],
    );
  }

  /// `Could not start an instant mix for "{name}"`
  String couldNotStartInstantMixFor(String name) {
    return Intl.message(
      'Could not start an instant mix for "$name"',
      name: 'couldNotStartInstantMixFor',
      desc: '',
      args: [name],
    );
  }

  /// `Could not start a mix for "{name}"`
  String couldNotStartMixFor(String name) {
    return Intl.message(
      'Could not start a mix for "$name"',
      name: 'couldNotStartMixFor',
      desc: '',
      args: [name],
    );
  }

  /// `Could not start playing "{name}"`
  String couldNotStartPlaying(String name) {
    return Intl.message(
      'Could not start playing "$name"',
      name: 'couldNotStartPlaying',
      desc: '',
      args: [name],
    );
  }

  /// `Could not take over`
  String get couldNotTakeOver {
    return Intl.message(
      'Could not take over',
      name: 'couldNotTakeOver',
      desc: '',
      args: [],
    );
  }

  /// `Show cover art over video background`
  String get coverOverVideoSetting {
    return Intl.message(
      'Show cover art over video background',
      name: 'coverOverVideoSetting',
      desc: '',
      args: [],
    );
  }

  /// `Create a GitHub issue`
  String get createGithubIssue {
    return Intl.message(
      'Create a GitHub issue',
      name: 'createGithubIssue',
      desc: '',
      args: [],
    );
  }

  /// `Report a bug or request a feature`
  String get createGithubIssueSubtitle {
    return Intl.message(
      'Report a bug or request a feature',
      name: 'createGithubIssueSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Create playlist`
  String get createPlaylist {
    return Intl.message(
      'Create playlist',
      name: 'createPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Current online devices: {count}`
  String currentOnlineDevices(int count) {
    return Intl.message(
      'Current online devices: $count',
      name: 'currentOnlineDevices',
      desc: '',
      args: [count],
    );
  }

  /// `Date Added`
  String get dateAdded {
    return Intl.message('Date Added', name: 'dateAdded', desc: '', args: []);
  }

  /// `Date Liked`
  String get dateLiked {
    return Intl.message('Date Liked', name: 'dateLiked', desc: '', args: []);
  }

  /// `Default browse tab`
  String get defaultBrowseTab {
    return Intl.message(
      'Default browse tab',
      name: 'defaultBrowseTab',
      desc: '',
      args: [],
    );
  }

  /// `Default start page`
  String get defaultStartPage {
    return Intl.message(
      'Default start page',
      name: 'defaultStartPage',
      desc: '',
      args: [],
    );
  }

  /// `Delete downloaded "{name}"?`
  String deleteDownloadedNameQuestion(String name) {
    return Intl.message(
      'Delete downloaded "$name"?',
      name: 'deleteDownloadedNameQuestion',
      desc: '',
      args: [name],
    );
  }

  /// `Delete "{name}"?`
  String deleteNameQuestion(String name) {
    return Intl.message(
      'Delete "$name"?',
      name: 'deleteNameQuestion',
      desc: '',
      args: [name],
    );
  }

  /// `Delete playlist`
  String get deletePlaylist {
    return Intl.message(
      'Delete playlist',
      name: 'deletePlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Device list sent. Thank you!`
  String get deviceListSentThankYou {
    return Intl.message(
      'Device list sent. Thank you!',
      name: 'deviceListSentThankYou',
      desc: '',
      args: [],
    );
  }

  /// `Direct`
  String get direct {
    return Intl.message('Direct', name: 'direct', desc: '', args: []);
  }

  /// `Disable auto-generated playlists`
  String get disableAutoGeneratedPlaylists {
    return Intl.message(
      'Disable auto-generated playlists',
      name: 'disableAutoGeneratedPlaylists',
      desc: '',
      args: [],
    );
  }

  /// `Disc {number}`
  String discNumber(int number) {
    return Intl.message(
      'Disc $number',
      name: 'discNumber',
      desc: '',
      args: [number],
    );
  }

  /// `Discogs artist`
  String get discogsArtist {
    return Intl.message(
      'Discogs artist',
      name: 'discogsArtist',
      desc: '',
      args: [],
    );
  }

  /// `Discogs master`
  String get discogsMaster {
    return Intl.message(
      'Discogs master',
      name: 'discogsMaster',
      desc: '',
      args: [],
    );
  }

  /// `Discogs release`
  String get discogsRelease {
    return Intl.message(
      'Discogs release',
      name: 'discogsRelease',
      desc: '',
      args: [],
    );
  }

  /// `Disconnect`
  String get disconnect {
    return Intl.message('Disconnect', name: 'disconnect', desc: '', args: []);
  }

  /// `Share what I am listening to on Discord`
  String get discordPresenceSetting {
    return Intl.message(
      'Share what I am listening to on Discord',
      name: 'discordPresenceSetting',
      desc: '',
      args: [],
    );
  }

  /// `Dismiss`
  String get dismiss {
    return Intl.message('Dismiss', name: 'dismiss', desc: '', args: []);
  }

  /// `Donate`
  String get donate {
    return Intl.message('Donate', name: 'donate', desc: '', args: []);
  }

  /// `This will help me to buy new devices to develop for and test on`
  String get donateSubtitle {
    return Intl.message(
      'This will help me to buy new devices to develop for and test on',
      name: 'donateSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Download`
  String get download {
    return Intl.message('Download', name: 'download', desc: '', args: []);
  }

  /// `Downloaded playlists follow your server: new songs are downloaded and removed songs are deleted. Otherwise this only happens on Wi-Fi.`
  String get downloadSyncNote {
    return Intl.message(
      'Downloaded playlists follow your server: new songs are downloaded and removed songs are deleted. Otherwise this only happens on Wi-Fi.',
      name: 'downloadSyncNote',
      desc: '',
      args: [],
    );
  }

  /// `Update downloaded playlists on cellular`
  String get downloadSyncOnCellularSetting {
    return Intl.message(
      'Update downloaded playlists on cellular',
      name: 'downloadSyncOnCellularSetting',
      desc: '',
      args: [],
    );
  }

  /// `Downloads`
  String get downloads {
    return Intl.message('Downloads', name: 'downloads', desc: '', args: []);
  }

  /// `Its {count, plural, one{{count} downloaded song} other{{count} downloaded songs}} ({size}) will be deleted from this device.`
  String downloadsDeletedNote(int count, String size) {
    return Intl.message(
      'Its ${Intl.plural(count, one: '$count downloaded song', other: '$count downloaded songs')} ($size) will be deleted from this device.',
      name: 'downloadsDeletedNote',
      desc: '',
      args: [count, size],
    );
  }

  /// `Downloads are still available`
  String get downloadsStillAvailable {
    return Intl.message(
      'Downloads are still available',
      name: 'downloadsStillAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Email me`
  String get emailMe {
    return Intl.message('Email me', name: 'emailMe', desc: '', args: []);
  }

  /// `Empty cache`
  String get emptyCache {
    return Intl.message('Empty cache', name: 'emptyCache', desc: '', args: []);
  }

  /// `Empty the cache?`
  String get emptyCacheQuestion {
    return Intl.message(
      'Empty the cache?',
      name: 'emptyCacheQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Tracks cached ahead for offline playback will be deleted.`
  String get emptyCacheWarning {
    return Intl.message(
      'Tracks cached ahead for offline playback will be deleted.',
      name: 'emptyCacheWarning',
      desc: '',
      args: [],
    );
  }

  /// `Enter a server address`
  String get enterAServerAddress {
    return Intl.message(
      'Enter a server address',
      name: 'enterAServerAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter the server address.`
  String get enterTheServerAddress {
    return Intl.message(
      'Enter the server address.',
      name: 'enterTheServerAddress',
      desc: '',
      args: [],
    );
  }

  /// `EPs`
  String get eps {
    return Intl.message('EPs', name: 'eps', desc: '', args: []);
  }

  /// `Error: {error}`
  String errorWithDetails(String error) {
    return Intl.message(
      'Error: $error',
      name: 'errorWithDetails',
      desc: '',
      args: [error],
    );
  }

  /// `Exit studio mode`
  String get exitStudioMode {
    return Intl.message(
      'Exit studio mode',
      name: 'exitStudioMode',
      desc: '',
      args: [],
    );
  }

  /// `Expand sidebar`
  String get expandSidebar {
    return Intl.message(
      'Expand sidebar',
      name: 'expandSidebar',
      desc: '',
      args: [],
    );
  }

  /// `experimental`
  String get experimental {
    return Intl.message(
      'experimental',
      name: 'experimental',
      desc: '',
      args: [],
    );
  }

  /// `Expired`
  String get expired {
    return Intl.message('Expired', name: 'expired', desc: '', args: []);
  }

  /// `Expires`
  String get expires {
    return Intl.message('Expires', name: 'expires', desc: '', args: []);
  }

  /// `Fast`
  String get fast {
    return Intl.message('Fast', name: 'fast', desc: '', args: []);
  }

  /// `Favourites`
  String get favourites {
    return Intl.message('Favourites', name: 'favourites', desc: '', args: []);
  }

  /// `Forgot password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Frequently played`
  String get frequentlyPlayed {
    return Intl.message(
      'Frequently played',
      name: 'frequentlyPlayed',
      desc: '',
      args: [],
    );
  }

  /// `General`
  String get general {
    return Intl.message('General', name: 'general', desc: '', args: []);
  }

  /// `Genres`
  String get genres {
    return Intl.message('Genres', name: 'genres', desc: '', args: []);
  }

  /// `Get your token from listenbrainz.org`
  String get getTokenFromListenBrainz {
    return Intl.message(
      'Get your token from listenbrainz.org',
      name: 'getTokenFromListenBrainz',
      desc: '',
      args: [],
    );
  }

  /// `{count} GB`
  String gigabytesLabel(int count) {
    return Intl.message(
      '$count GB',
      name: 'gigabytesLabel',
      desc: '',
      args: [count],
    );
  }

  /// `Go to album`
  String get goToAlbum {
    return Intl.message('Go to album', name: 'goToAlbum', desc: '', args: []);
  }

  /// `Go to artist`
  String get goToArtist {
    return Intl.message('Go to artist', name: 'goToArtist', desc: '', args: []);
  }

  /// `Got it`
  String get gotIt {
    return Intl.message('Got it', name: 'gotIt', desc: '', args: []);
  }

  /// `Hide favourites`
  String get hideFavourites {
    return Intl.message(
      'Hide favourites',
      name: 'hideFavourites',
      desc: '',
      args: [],
    );
  }

  /// `Hide lyrics`
  String get hideLyrics {
    return Intl.message('Hide lyrics', name: 'hideLyrics', desc: '', args: []);
  }

  /// `Hide queue`
  String get hideQueue {
    return Intl.message('Hide queue', name: 'hideQueue', desc: '', args: []);
  }

  /// `Hide recently played`
  String get hideRecentlyPlayed {
    return Intl.message(
      'Hide recently played',
      name: 'hideRecentlyPlayed',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Home address`
  String get homeAddress {
    return Intl.message(
      'Home address',
      name: 'homeAddress',
      desc: '',
      args: [],
    );
  }

  /// `The main address of this server. Change it when the server moved to a new IP or domain; you stay signed in.`
  String get homeAddressDescription {
    return Intl.message(
      'The main address of this server. Change it when the server moved to a new IP or domain; you stay signed in.',
      name: 'homeAddressDescription',
      desc: '',
      args: [],
    );
  }

  /// `Home Page`
  String get homePage {
    return Intl.message('Home Page', name: 'homePage', desc: '', args: []);
  }

  /// `Home page refreshed`
  String get homePageRefreshed {
    return Intl.message(
      'Home page refreshed',
      name: 'homePageRefreshed',
      desc: '',
      args: [],
    );
  }

  /// `Image cache cleared`
  String get imageCacheCleared {
    return Intl.message(
      'Image cache cleared',
      name: 'imageCacheCleared',
      desc: '',
      args: [],
    );
  }

  /// `Incorrect login or password`
  String get invalidCredentials {
    return Intl.message(
      'Incorrect login or password',
      name: 'invalidCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Is public`
  String get isPublic {
    return Intl.message('Is public', name: 'isPublic', desc: '', args: []);
  }

  /// `Issued by`
  String get issuedBy {
    return Intl.message('Issued by', name: 'issuedBy', desc: '', args: []);
  }

  /// `Issued to`
  String get issuedTo {
    return Intl.message('Issued to', name: 'issuedTo', desc: '', args: []);
  }

  /// `JellyBox can't connect to your server`
  String get jellyboxCantConnect {
    return Intl.message(
      'JellyBox can\'t connect to your server',
      name: 'jellyboxCantConnect',
      desc: '',
      args: [],
    );
  }

  /// `Join Discord`
  String get joinDiscord {
    return Intl.message(
      'Join Discord',
      name: 'joinDiscord',
      desc: '',
      args: [],
    );
  }

  /// `Chat with the me (Alex, the developer) and other users`
  String get joinDiscordSubtitle {
    return Intl.message(
      'Chat with the me (Alex, the developer) and other users',
      name: 'joinDiscordSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `{kbps} kbps`
  String kbpsLabel(int kbps) {
    return Intl.message(
      '$kbps kbps',
      name: 'kbpsLabel',
      desc: '',
      args: [kbps],
    );
  }

  /// `Keep the screen on`
  String get keepTheScreenOn {
    return Intl.message(
      'Keep the screen on',
      name: 'keepTheScreenOn',
      desc: '',
      args: [],
    );
  }

  /// `Landscape player`
  String get landscapePlayer {
    return Intl.message(
      'Landscape player',
      name: 'landscapePlayer',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Left`
  String get left {
    return Intl.message('Left', name: 'left', desc: '', args: []);
  }

  /// `Show A–Z index on browse lists sorted by name`
  String get letterRulerSetting {
    return Intl.message(
      'Show A–Z index on browse lists sorted by name',
      name: 'letterRulerSetting',
      desc: '',
      args: [],
    );
  }

  /// `Could not load your libraries.`
  String get librariesLoadFailed {
    return Intl.message(
      'Could not load your libraries.',
      name: 'librariesLoadFailed',
      desc: '',
      args: [],
    );
  }

  /// `You're offline, so your libraries can't be loaded.`
  String get librariesOfflineMessage {
    return Intl.message(
      'You\'re offline, so your libraries can\'t be loaded.',
      name: 'librariesOfflineMessage',
      desc: '',
      args: [],
    );
  }

  /// `Library`
  String get library {
    return Intl.message('Library', name: 'library', desc: '', args: []);
  }

  /// `Like`
  String get like {
    return Intl.message('Like', name: 'like', desc: '', args: []);
  }

  /// `Liked`
  String get liked {
    return Intl.message('Liked', name: 'liked', desc: '', args: []);
  }

  /// `Liked songs`
  String get likedSongs {
    return Intl.message('Liked songs', name: 'likedSongs', desc: '', args: []);
  }

  /// `Liked songs are not downloaded.`
  String get likedSongsNotDownloaded {
    return Intl.message(
      'Liked songs are not downloaded.',
      name: 'likedSongsNotDownloaded',
      desc: '',
      args: [],
    );
  }

  /// `Load more…`
  String get loadMore {
    return Intl.message('Load more…', name: 'loadMore', desc: '', args: []);
  }

  /// `Loading…`
  String get loading {
    return Intl.message('Loading…', name: 'loading', desc: '', args: []);
  }

  /// `Log out`
  String get logOut {
    return Intl.message('Log out', name: 'logOut', desc: '', args: []);
  }

  /// `Log out of all servers`
  String get logOutOfAllServers {
    return Intl.message(
      'Log out of all servers',
      name: 'logOutOfAllServers',
      desc: '',
      args: [],
    );
  }

  /// `Log out of {name}?`
  String logOutOfName(String name) {
    return Intl.message(
      'Log out of $name?',
      name: 'logOutOfName',
      desc: '',
      args: [name],
    );
  }

  /// `Log out of {name}`
  String logOutOfServer(String name) {
    return Intl.message(
      'Log out of $name',
      name: 'logOutOfServer',
      desc: '',
      args: [name],
    );
  }

  /// `Log out of this server`
  String get logOutOfThisServer {
    return Intl.message(
      'Log out of this server',
      name: 'logOutOfThisServer',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `When your server has no lyrics for a song, looks them up on lrclib.net, a free public lyrics library.`
  String get lrclibLyricsNote {
    return Intl.message(
      'When your server has no lyrics for a song, looks them up on lrclib.net, a free public lyrics library.',
      name: 'lrclibLyricsNote',
      desc: '',
      args: [],
    );
  }

  /// `Find missing lyrics on LRCLIB`
  String get lrclibLyricsSetting {
    return Intl.message(
      'Find missing lyrics on LRCLIB',
      name: 'lrclibLyricsSetting',
      desc: '',
      args: [],
    );
  }

  /// `Lyrics`
  String get lyrics {
    return Intl.message('Lyrics', name: 'lyrics', desc: '', args: []);
  }

  /// `Lyrics text alignment`
  String get lyricsTextAlignment {
    return Intl.message(
      'Lyrics text alignment',
      name: 'lyricsTextAlignment',
      desc: '',
      args: [],
    );
  }

  /// `Made for you`
  String get madeForYou {
    return Intl.message('Made for you', name: 'madeForYou', desc: '', args: []);
  }

  /// `Medium`
  String get medium {
    return Intl.message('Medium', name: 'medium', desc: '', args: []);
  }

  /// `{count} MB`
  String megabytesLabel(int count) {
    return Intl.message(
      '$count MB',
      name: 'megabytesLabel',
      desc: '',
      args: [count],
    );
  }

  /// `Middle`
  String get middle {
    return Intl.message('Middle', name: 'middle', desc: '', args: []);
  }

  /// `{count} min`
  String minutesAbbreviated(int count) {
    return Intl.message(
      '$count min',
      name: 'minutesAbbreviated',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{1 minute} other{{count} minutes}}`
  String minutesCount(int count) {
    return Intl.plural(
      count,
      one: '1 minute',
      other: '$count minutes',
      name: 'minutesCount',
      desc: '',
      args: [count],
    );
  }

  /// `{minutes} min`
  String minutesShort(int minutes) {
    return Intl.message(
      '$minutes min',
      name: 'minutesShort',
      desc: '',
      args: [minutes],
    );
  }

  /// `This mix is no longer available`
  String get mixNoLongerAvailable {
    return Intl.message(
      'This mix is no longer available',
      name: 'mixNoLongerAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Mix order`
  String get mixOrder {
    return Intl.message('Mix order', name: 'mixOrder', desc: '', args: []);
  }

  /// `More`
  String get more {
    return Intl.message('More', name: 'more', desc: '', args: []);
  }

  /// `More from {name}`
  String moreFrom(String name) {
    return Intl.message(
      'More from $name',
      name: 'moreFrom',
      desc: '',
      args: [name],
    );
  }

  /// `Most played in the last 30 days`
  String get mostPlayedLast30Days {
    return Intl.message(
      'Most played in the last 30 days',
      name: 'mostPlayedLast30Days',
      desc: '',
      args: [],
    );
  }

  /// `MusicBrainz artist`
  String get musicBrainzArtist {
    return Intl.message(
      'MusicBrainz artist',
      name: 'musicBrainzArtist',
      desc: '',
      args: [],
    );
  }

  /// `MusicBrainz recording`
  String get musicBrainzRecording {
    return Intl.message(
      'MusicBrainz recording',
      name: 'musicBrainzRecording',
      desc: '',
      args: [],
    );
  }

  /// `MusicBrainz release`
  String get musicBrainzRelease {
    return Intl.message(
      'MusicBrainz release',
      name: 'musicBrainzRelease',
      desc: '',
      args: [],
    );
  }

  /// `MusicBrainz release group`
  String get musicBrainzReleaseGroup {
    return Intl.message(
      'MusicBrainz release group',
      name: 'musicBrainzReleaseGroup',
      desc: '',
      args: [],
    );
  }

  /// `MusicBrainz track`
  String get musicBrainzTrack {
    return Intl.message(
      'MusicBrainz track',
      name: 'musicBrainzTrack',
      desc: '',
      args: [],
    );
  }

  /// `Mute`
  String get mute {
    return Intl.message('Mute', name: 'mute', desc: '', args: []);
  }

  /// `My new playlist`
  String get myNewPlaylist {
    return Intl.message(
      'My new playlist',
      name: 'myNewPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }

  /// `{name} Mix`
  String nameMix(String name) {
    return Intl.message('$name Mix', name: 'nameMix', desc: '', args: [name]);
  }

  /// `Never`
  String get never {
    return Intl.message('Never', name: 'never', desc: '', args: []);
  }

  /// `New playlist`
  String get newPlaylist {
    return Intl.message(
      'New playlist',
      name: 'newPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `No Cast or DLNA devices found on this network.`
  String get noCastOrDlnaDevicesFound {
    return Intl.message(
      'No Cast or DLNA devices found on this network.',
      name: 'noCastOrDlnaDevicesFound',
      desc: '',
      args: [],
    );
  }

  /// `No DLNA devices found on this network.`
  String get noDlnaDevicesFound {
    return Intl.message(
      'No DLNA devices found on this network.',
      name: 'noDlnaDevicesFound',
      desc: '',
      args: [],
    );
  }

  /// `No downloads`
  String get noDownloads {
    return Intl.message(
      'No downloads',
      name: 'noDownloads',
      desc: '',
      args: [],
    );
  }

  /// `No downloads yet`
  String get noDownloadsYet {
    return Intl.message(
      'No downloads yet',
      name: 'noDownloadsYet',
      desc: '',
      args: [],
    );
  }

  /// `You haven't favourited anything yet.`
  String get noFavouritesYet {
    return Intl.message(
      'You haven\'t favourited anything yet.',
      name: 'noFavouritesYet',
      desc: '',
      args: [],
    );
  }

  /// `No libraries found :(`
  String get noLibrariesFound {
    return Intl.message(
      'No libraries found :(',
      name: 'noLibrariesFound',
      desc: '',
      args: [],
    );
  }

  /// `No lyrics for this track`
  String get noLyricsForThisTrack {
    return Intl.message(
      'No lyrics for this track',
      name: 'noLyricsForThisTrack',
      desc: '',
      args: [],
    );
  }

  /// `No mix available for "{name}"`
  String noMixAvailableFor(String name) {
    return Intl.message(
      'No mix available for "$name"',
      name: 'noMixAvailableFor',
      desc: '',
      args: [name],
    );
  }

  /// `No results`
  String get noResults {
    return Intl.message('No results', name: 'noResults', desc: '', args: []);
  }

  /// `No results for “{query}”`
  String noResultsFor(String query) {
    return Intl.message(
      'No results for “$query”',
      name: 'noResultsFor',
      desc: '',
      args: [query],
    );
  }

  /// `No songs found for "{name}"`
  String noSongsFoundFor(String name) {
    return Intl.message(
      'No songs found for "$name"',
      name: 'noSongsFoundFor',
      desc: '',
      args: [name],
    );
  }

  /// `No songs in this album`
  String get noSongsInThisAlbum {
    return Intl.message(
      'No songs in this album',
      name: 'noSongsInThisAlbum',
      desc: '',
      args: [],
    );
  }

  /// `There's no songs yet.`
  String get noSongsYet {
    return Intl.message(
      'There\'s no songs yet.',
      name: 'noSongsYet',
      desc: '',
      args: [],
    );
  }

  /// `None`
  String get none {
    return Intl.message('None', name: 'none', desc: '', args: []);
  }

  /// `Not available offline`
  String get notAvailableOffline {
    return Intl.message(
      'Not available offline',
      name: 'notAvailableOffline',
      desc: '',
      args: [],
    );
  }

  /// `Not now`
  String get notNow {
    return Intl.message('Not now', name: 'notNow', desc: '', args: []);
  }

  /// `Nothing found`
  String get nothingFound {
    return Intl.message(
      'Nothing found',
      name: 'nothingFound',
      desc: '',
      args: [],
    );
  }

  /// `Nothing here yet.`
  String get nothingHereYet {
    return Intl.message(
      'Nothing here yet.',
      name: 'nothingHereYet',
      desc: '',
      args: [],
    );
  }

  /// `Nothing in queue`
  String get nothingInQueue {
    return Intl.message(
      'Nothing in queue',
      name: 'nothingInQueue',
      desc: '',
      args: [],
    );
  }

  /// `Nothing played in the last 30 days.`
  String get nothingPlayedLast30Days {
    return Intl.message(
      'Nothing played in the last 30 days.',
      name: 'nothingPlayedLast30Days',
      desc: '',
      args: [],
    );
  }

  /// `Nothing playing`
  String get nothingPlaying {
    return Intl.message(
      'Nothing playing',
      name: 'nothingPlaying',
      desc: '',
      args: [],
    );
  }

  /// `Nothing to download`
  String get nothingToDownload {
    return Intl.message(
      'Nothing to download',
      name: 'nothingToDownload',
      desc: '',
      args: [],
    );
  }

  /// `Nothing to play in "{name}"`
  String nothingToPlayIn(String name) {
    return Intl.message(
      'Nothing to play in "$name"',
      name: 'nothingToPlayIn',
      desc: '',
      args: [name],
    );
  }

  /// `Nothing to queue in "{name}"`
  String nothingToQueueIn(String name) {
    return Intl.message(
      'Nothing to queue in "$name"',
      name: 'nothingToQueueIn',
      desc: '',
      args: [name],
    );
  }

  /// `Enable halo effect for currently playing media`
  String get nowPlayingHaloSetting {
    return Intl.message(
      'Enable halo effect for currently playing media',
      name: 'nowPlayingHaloSetting',
      desc: '',
      args: [],
    );
  }

  /// `Off`
  String get off {
    return Intl.message('Off', name: 'off', desc: '', args: []);
  }

  /// `Offline`
  String get offline {
    return Intl.message('Offline', name: 'offline', desc: '', args: []);
  }

  /// `You're offline and this album isn't downloaded.`
  String get offlineAlbumNotDownloaded {
    return Intl.message(
      'You\'re offline and this album isn\'t downloaded.',
      name: 'offlineAlbumNotDownloaded',
      desc: '',
      args: [],
    );
  }

  /// `You're offline. Your favourites will be back once the server is reachable.`
  String get offlineFavouritesNotice {
    return Intl.message(
      'You\'re offline. Your favourites will be back once the server is reachable.',
      name: 'offlineFavouritesNotice',
      desc: '',
      args: [],
    );
  }

  /// `You're offline. This genre needs a connection.`
  String get offlineGenreNotice {
    return Intl.message(
      'You\'re offline. This genre needs a connection.',
      name: 'offlineGenreNotice',
      desc: '',
      args: [],
    );
  }

  /// `You're offline. Your library will be back once the server is reachable.`
  String get offlineLibraryNotice {
    return Intl.message(
      'You\'re offline. Your library will be back once the server is reachable.',
      name: 'offlineLibraryNotice',
      desc: '',
      args: [],
    );
  }

  /// `Offline — only downloads are available`
  String get offlineOnlyDownloads {
    return Intl.message(
      'Offline — only downloads are available',
      name: 'offlineOnlyDownloads',
      desc: '',
      args: [],
    );
  }

  /// `You're offline, so playlists need a connection.`
  String get offlinePlaylistsNotice {
    return Intl.message(
      'You\'re offline, so playlists need a connection.',
      name: 'offlinePlaylistsNotice',
      desc: '',
      args: [],
    );
  }

  /// `You're offline, so search needs a connection.`
  String get offlineSearchNotice {
    return Intl.message(
      'You\'re offline, so search needs a connection.',
      name: 'offlineSearchNotice',
      desc: '',
      args: [],
    );
  }

  /// `On repeat`
  String get onRepeat {
    return Intl.message('On repeat', name: 'onRepeat', desc: '', args: []);
  }

  /// `Open`
  String get open {
    return Intl.message('Open', name: 'open', desc: '', args: []);
  }

  /// `Open downloads`
  String get openDownloads {
    return Intl.message(
      'Open downloads',
      name: 'openDownloads',
      desc: '',
      args: [],
    );
  }

  /// `Open JellyBox to connect to your server`
  String get openJellyboxToConnect {
    return Intl.message(
      'Open JellyBox to connect to your server',
      name: 'openJellyboxToConnect',
      desc: '',
      args: [],
    );
  }

  /// `Open JellyBox on your iPhone to get started`
  String get openOnIphoneToStart {
    return Intl.message(
      'Open JellyBox on your iPhone to get started',
      name: 'openOnIphoneToStart',
      desc: '',
      args: [],
    );
  }

  /// `Original`
  String get original {
    return Intl.message('Original', name: 'original', desc: '', args: []);
  }

  /// `Other`
  String get other {
    return Intl.message('Other', name: 'other', desc: '', args: []);
  }

  /// `Palette settings`
  String get paletteSettings {
    return Intl.message(
      'Palette settings',
      name: 'paletteSettings',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Paste the user token from your ListenBrainz settings.`
  String get pasteListenBrainzToken {
    return Intl.message(
      'Paste the user token from your ListenBrainz settings.',
      name: 'pasteListenBrainzToken',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get play {
    return Intl.message('Play', name: 'play', desc: '', args: []);
  }

  /// `Play album`
  String get playAlbum {
    return Intl.message('Play album', name: 'playAlbum', desc: '', args: []);
  }

  /// `Play all`
  String get playAll {
    return Intl.message('Play all', name: 'playAll', desc: '', args: []);
  }

  /// `Play artist`
  String get playArtist {
    return Intl.message('Play artist', name: 'playArtist', desc: '', args: []);
  }

  /// `Play disc`
  String get playDisc {
    return Intl.message('Play disc', name: 'playDisc', desc: '', args: []);
  }

  /// `Play genre`
  String get playGenre {
    return Intl.message('Play genre', name: 'playGenre', desc: '', args: []);
  }

  /// `Play next`
  String get playNext {
    return Intl.message('Play next', name: 'playNext', desc: '', args: []);
  }

  /// `Play on`
  String get playOn {
    return Intl.message('Play on', name: 'playOn', desc: '', args: []);
  }

  /// `Play on a device`
  String get playOnADevice {
    return Intl.message(
      'Play on a device',
      name: 'playOnADevice',
      desc: '',
      args: [],
    );
  }

  /// `Play playlist`
  String get playPlaylist {
    return Intl.message(
      'Play playlist',
      name: 'playPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Playing`
  String get playing {
    return Intl.message('Playing', name: 'playing', desc: '', args: []);
  }

  /// `Playing next`
  String get playingNext {
    return Intl.message(
      'Playing next',
      name: 'playingNext',
      desc: '',
      args: [],
    );
  }

  /// `Playing on {name}`
  String playingOn(String name) {
    return Intl.message(
      'Playing on $name',
      name: 'playingOn',
      desc: '',
      args: [name],
    );
  }

  /// `Playing on a different server`
  String get playingOnADifferentServer {
    return Intl.message(
      'Playing on a different server',
      name: 'playingOnADifferentServer',
      desc: '',
      args: [],
    );
  }

  /// `Playing on {name}. Choose a device`
  String playingOnChooseDevice(String name) {
    return Intl.message(
      'Playing on $name. Choose a device',
      name: 'playingOnChooseDevice',
      desc: '',
      args: [name],
    );
  }

  /// `Playlist`
  String get playlist {
    return Intl.message('Playlist', name: 'playlist', desc: '', args: []);
  }

  /// `Playlist name`
  String get playlistName {
    return Intl.message(
      'Playlist name',
      name: 'playlistName',
      desc: '',
      args: [],
    );
  }

  /// `This playlist has no songs yet.`
  String get playlistNoSongsYet {
    return Intl.message(
      'This playlist has no songs yet.',
      name: 'playlistNoSongsYet',
      desc: '',
      args: [],
    );
  }

  /// `Playlist order`
  String get playlistOrder {
    return Intl.message(
      'Playlist order',
      name: 'playlistOrder',
      desc: '',
      args: [],
    );
  }

  /// `Playlists`
  String get playlists {
    return Intl.message('Playlists', name: 'playlists', desc: '', args: []);
  }

  /// `{count, plural, one{{count} playlist} other{{count} playlists}}`
  String playlistsCount(int count) {
    return Intl.plural(
      count,
      one: '$count playlist',
      other: '$count playlists',
      name: 'playlistsCount',
      desc: '',
      args: [count],
    );
  }

  /// `The JellyBox Relay plugin on this server is out of date. A server admin can update it under Dashboard → Plugins.`
  String get pluginOutOfDateNotice {
    return Intl.message(
      'The JellyBox Relay plugin on this server is out of date. A server admin can update it under Dashboard → Plugins.',
      name: 'pluginOutOfDateNotice',
      desc: '',
      args: [],
    );
  }

  /// `Privacy`
  String get privacy {
    return Intl.message('Privacy', name: 'privacy', desc: '', args: []);
  }

  /// `Queue`
  String get queue {
    return Intl.message('Queue', name: 'queue', desc: '', args: []);
  }

  /// `Queue cache`
  String get queueCache {
    return Intl.message('Queue cache', name: 'queueCache', desc: '', args: []);
  }

  /// `Queue is empty`
  String get queueIsEmpty {
    return Intl.message(
      'Queue is empty',
      name: 'queueIsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `The Quick Connect code expired. Try again.`
  String get quickConnectExpired {
    return Intl.message(
      'The Quick Connect code expired. Try again.',
      name: 'quickConnectExpired',
      desc: '',
      args: [],
    );
  }

  /// `On a device where you are already signed in, open Quick Connect in your user settings and enter this code.`
  String get quickConnectInstructions {
    return Intl.message(
      'On a device where you are already signed in, open Quick Connect in your user settings and enter this code.',
      name: 'quickConnectInstructions',
      desc: '',
      args: [],
    );
  }

  /// `Quick Connect is not available on this server.`
  String get quickConnectUnavailable {
    return Intl.message(
      'Quick Connect is not available on this server.',
      name: 'quickConnectUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Random`
  String get random {
    return Intl.message('Random', name: 'random', desc: '', args: []);
  }

  /// `Read more`
  String get readMore {
    return Intl.message('Read more', name: 'readMore', desc: '', args: []);
  }

  /// `Rebuild mixes (debug)`
  String get rebuildMixesDebug {
    return Intl.message(
      'Rebuild mixes (debug)',
      name: 'rebuildMixesDebug',
      desc: '',
      args: [],
    );
  }

  /// `Recently added`
  String get recentlyAdded {
    return Intl.message(
      'Recently added',
      name: 'recentlyAdded',
      desc: '',
      args: [],
    );
  }

  /// `Recently played`
  String get recentlyPlayed {
    return Intl.message(
      'Recently played',
      name: 'recentlyPlayed',
      desc: '',
      args: [],
    );
  }

  /// `Refresh now`
  String get refreshNow {
    return Intl.message('Refresh now', name: 'refreshNow', desc: '', args: []);
  }

  /// `Remote access needs a password on your Jellyfin user.`
  String get relayNoPassword {
    return Intl.message(
      'Remote access needs a password on your Jellyfin user.',
      name: 'relayNoPassword',
      desc: '',
      args: [],
    );
  }

  /// `No remote access address for this server yet.`
  String get relayNotSetUp {
    return Intl.message(
      'No remote access address for this server yet.',
      name: 'relayNotSetUp',
      desc: '',
      args: [],
    );
  }

  /// `This server's Jellybox Cloud plan has no free seat for your user. Ask the owner to make room.`
  String get relayPlanFull {
    return Intl.message(
      'This server\'s Jellybox Cloud plan has no free seat for your user. Ask the owner to make room.',
      name: 'relayPlanFull',
      desc: '',
      args: [],
    );
  }

  /// `Remote`
  String get remote {
    return Intl.message('Remote', name: 'remote', desc: '', args: []);
  }

  /// `Remote address`
  String get remoteAddress {
    return Intl.message(
      'Remote address',
      name: 'remoteAddress',
      desc: '',
      args: [],
    );
  }

  /// `A second address for the same server, such as a Tailscale, WireGuard or reverse proxy URL. Jellybox uses the home address when it answers and switches to this one when it does not.`
  String get remoteAddressDescription {
    return Intl.message(
      'A second address for the same server, such as a Tailscale, WireGuard or reverse proxy URL. Jellybox uses the home address when it answers and switches to this one when it does not.',
      name: 'remoteAddressDescription',
      desc: '',
      args: [],
    );
  }

  /// `Remove download`
  String get removeDownload {
    return Intl.message(
      'Remove download',
      name: 'removeDownload',
      desc: '',
      args: [],
    );
  }

  /// `Remove from favourites`
  String get removeFromFavourites {
    return Intl.message(
      'Remove from favourites',
      name: 'removeFromFavourites',
      desc: '',
      args: [],
    );
  }

  /// `Remove from playlist`
  String get removeFromPlaylist {
    return Intl.message(
      'Remove from playlist',
      name: 'removeFromPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Remove from queue`
  String get removeFromQueue {
    return Intl.message(
      'Remove from queue',
      name: 'removeFromQueue',
      desc: '',
      args: [],
    );
  }

  /// `Remove remote address`
  String get removeRemoteAddress {
    return Intl.message(
      'Remove remote address',
      name: 'removeRemoteAddress',
      desc: '',
      args: [],
    );
  }

  /// `Removed "{name}" from downloads`
  String removedFromDownloads(String name) {
    return Intl.message(
      'Removed "$name" from downloads',
      name: 'removedFromDownloads',
      desc: '',
      args: [name],
    );
  }

  /// `Successfully removed item from playlist`
  String get removedFromPlaylist {
    return Intl.message(
      'Successfully removed item from playlist',
      name: 'removedFromPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Repeat`
  String get repeat {
    return Intl.message('Repeat', name: 'repeat', desc: '', args: []);
  }

  /// `Repeat all`
  String get repeatAll {
    return Intl.message('Repeat all', name: 'repeatAll', desc: '', args: []);
  }

  /// `Repeat one`
  String get repeatOne {
    return Intl.message('Repeat one', name: 'repeatOne', desc: '', args: []);
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `Right`
  String get right {
    return Intl.message('Right', name: 'right', desc: '', args: []);
  }

  /// `Rows`
  String get rows {
    return Intl.message('Rows', name: 'rows', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Scan again`
  String get scanAgain {
    return Intl.message('Scan again', name: 'scanAgain', desc: '', args: []);
  }

  /// `Search`
  String get search {
    return Intl.message('Search', name: 'search', desc: '', args: []);
  }

  /// `Search failed. Try again.`
  String get searchFailedTryAgain {
    return Intl.message(
      'Search failed. Try again.',
      name: 'searchFailedTryAgain',
      desc: '',
      args: [],
    );
  }

  /// `Select a playlist`
  String get selectAPlaylist {
    return Intl.message(
      'Select a playlist',
      name: 'selectAPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Select Library`
  String get selectLibrary {
    return Intl.message(
      'Select Library',
      name: 'selectLibrary',
      desc: '',
      args: [],
    );
  }

  /// `{host} uses a self-signed certificate, so its identity cannot be verified automatically.`
  String selfSignedCertificate(String host) {
    return Intl.message(
      '$host uses a self-signed certificate, so its identity cannot be verified automatically.',
      name: 'selfSignedCertificate',
      desc: '',
      args: [host],
    );
  }

  /// `This server is already added.`
  String get serverAlreadyAdded {
    return Intl.message(
      'This server is already added.',
      name: 'serverAlreadyAdded',
      desc: '',
      args: [],
    );
  }

  /// `This server speaks more than one API`
  String get serverSpeaksMultipleApis {
    return Intl.message(
      'This server speaks more than one API',
      name: 'serverSpeaksMultipleApis',
      desc: '',
      args: [],
    );
  }

  /// `Server URL`
  String get serverUrl {
    return Intl.message('Server URL', name: 'serverUrl', desc: '', args: []);
  }

  /// `Server URL and login are required`
  String get serverUrlAndLoginRequired {
    return Intl.message(
      'Server URL and login are required',
      name: 'serverUrlAndLoginRequired',
      desc: '',
      args: [],
    );
  }

  /// `Server URL is invalid. Try something like 192.168.1.10:8096 or jellyfin.example.com`
  String get serverUrlInvalid {
    return Intl.message(
      'Server URL is invalid. Try something like 192.168.1.10:8096 or jellyfin.example.com',
      name: 'serverUrlInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Server URL is required`
  String get serverUrlRequired {
    return Intl.message(
      'Server URL is required',
      name: 'serverUrlRequired',
      desc: '',
      args: [],
    );
  }

  /// `Servers`
  String get servers {
    return Intl.message('Servers', name: 'servers', desc: '', args: []);
  }

  /// `Set up the JellyBox Relay plugin`
  String get setUpRelayPlugin {
    return Intl.message(
      'Set up the JellyBox Relay plugin',
      name: 'setUpRelayPlugin',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Share`
  String get share {
    return Intl.message('Share', name: 'share', desc: '', args: []);
  }

  /// `Share this device list with the developer`
  String get shareDeviceListWithDeveloper {
    return Intl.message(
      'Share this device list with the developer',
      name: 'shareDeviceListWithDeveloper',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{Send the details of the DLNA device on your network? It stays private and is only used to build proper support for different manufacturers.} other{Send the details of the {count} DLNA devices on your network? It stays private and is only used to build proper support for different manufacturers.}}`
  String shareDevicesDialogBody(int count) {
    return Intl.plural(
      count,
      one:
          'Send the details of the DLNA device on your network? It stays private and is only used to build proper support for different manufacturers.',
      other:
          'Send the details of the $count DLNA devices on your network? It stays private and is only used to build proper support for different manufacturers.',
      name: 'shareDevicesDialogBody',
      desc: '',
      args: [count],
    );
  }

  /// `Share what JellyBox found?`
  String get shareWhatJellyboxFound {
    return Intl.message(
      'Share what JellyBox found?',
      name: 'shareWhatJellyboxFound',
      desc: '',
      args: [],
    );
  }

  /// `Show all {count} songs`
  String showAllSongs(int count) {
    return Intl.message(
      'Show all $count songs',
      name: 'showAllSongs',
      desc: '',
      args: [count],
    );
  }

  /// `Show less`
  String get showLess {
    return Intl.message('Show less', name: 'showLess', desc: '', args: []);
  }

  /// `Shuffle`
  String get shuffle {
    return Intl.message('Shuffle', name: 'shuffle', desc: '', args: []);
  }

  /// `Shuffle on`
  String get shuffleOn {
    return Intl.message('Shuffle on', name: 'shuffleOn', desc: '', args: []);
  }

  /// `Shuffle play`
  String get shufflePlay {
    return Intl.message(
      'Shuffle play',
      name: 'shufflePlay',
      desc: '',
      args: [],
    );
  }

  /// `Sign in`
  String get signIn {
    return Intl.message('Sign in', name: 'signIn', desc: '', args: []);
  }

  /// `Sign in again`
  String get signInAgain {
    return Intl.message(
      'Sign in again',
      name: 'signInAgain',
      desc: '',
      args: [],
    );
  }

  /// `Sign in on your phone`
  String get signInOnYourPhone {
    return Intl.message(
      'Sign in on your phone',
      name: 'signInOnYourPhone',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to start listening`
  String get signInToStartListening {
    return Intl.message(
      'Sign in to start listening',
      name: 'signInToStartListening',
      desc: '',
      args: [],
    );
  }

  /// `You will be signed out of this server.`
  String get signedOutOfThisServer {
    return Intl.message(
      'You will be signed out of this server.',
      name: 'signedOutOfThisServer',
      desc: '',
      args: [],
    );
  }

  /// `Singles`
  String get singles {
    return Intl.message('Singles', name: 'singles', desc: '', args: []);
  }

  /// `Sleep timer`
  String get sleepTimer {
    return Intl.message('Sleep timer', name: 'sleepTimer', desc: '', args: []);
  }

  /// `at`
  String get sleepTimerAt {
    return Intl.message('at', name: 'sleepTimerAt', desc: '', args: []);
  }

  /// `Stop in`
  String get sleepTimerStopIn {
    return Intl.message(
      'Stop in',
      name: 'sleepTimerStopIn',
      desc: '',
      args: [],
    );
  }

  /// `tracks`
  String get sleepTimerTracks {
    return Intl.message('tracks', name: 'sleepTimerTracks', desc: '', args: []);
  }

  /// `Slow`
  String get slow {
    return Intl.message('Slow', name: 'slow', desc: '', args: []);
  }

  /// `Uff! Something went wrong...`
  String get somethingWentWrong {
    return Intl.message(
      'Uff! Something went wrong...',
      name: 'somethingWentWrong',
      desc: '',
      args: [],
    );
  }

  /// `Song`
  String get song {
    return Intl.message('Song', name: 'song', desc: '', args: []);
  }

  /// `Song • {artist}`
  String songWithArtist(String artist) {
    return Intl.message(
      'Song • $artist',
      name: 'songWithArtist',
      desc: '',
      args: [artist],
    );
  }

  /// `Songs`
  String get songs {
    return Intl.message('Songs', name: 'songs', desc: '', args: []);
  }

  /// `{count, plural, one{{count} song} other{{count} songs}}`
  String songsCount(int count) {
    return Intl.plural(
      count,
      one: '$count song',
      other: '$count songs',
      name: 'songsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Sort`
  String get sort {
    return Intl.message('Sort', name: 'sort', desc: '', args: []);
  }

  /// `Sort by`
  String get sortBy {
    return Intl.message('Sort by', name: 'sortBy', desc: '', args: []);
  }

  /// `Sounds like`
  String get soundsLike {
    return Intl.message('Sounds like', name: 'soundsLike', desc: '', args: []);
  }

  /// `Start album mix`
  String get startAlbumMix {
    return Intl.message(
      'Start album mix',
      name: 'startAlbumMix',
      desc: '',
      args: [],
    );
  }

  /// `Start artist mix`
  String get startArtistMix {
    return Intl.message(
      'Start artist mix',
      name: 'startArtistMix',
      desc: '',
      args: [],
    );
  }

  /// `Start genre mix`
  String get startGenreMix {
    return Intl.message(
      'Start genre mix',
      name: 'startGenreMix',
      desc: '',
      args: [],
    );
  }

  /// `Start genre radio`
  String get startGenreRadio {
    return Intl.message(
      'Start genre radio',
      name: 'startGenreRadio',
      desc: '',
      args: [],
    );
  }

  /// `Start song mix`
  String get startSongMix {
    return Intl.message(
      'Start song mix',
      name: 'startSongMix',
      desc: '',
      args: [],
    );
  }

  /// `Stop download`
  String get stopDownload {
    return Intl.message(
      'Stop download',
      name: 'stopDownload',
      desc: '',
      args: [],
    );
  }

  /// `Stop timer`
  String get stopTimer {
    return Intl.message('Stop timer', name: 'stopTimer', desc: '', args: []);
  }

  /// `Streaming`
  String get streaming {
    return Intl.message('Streaming', name: 'streaming', desc: '', args: []);
  }

  /// `Streaming quality`
  String get streamingQuality {
    return Intl.message(
      'Streaming quality',
      name: 'streamingQuality',
      desc: '',
      args: [],
    );
  }

  /// `Songs above the limit are converted by your server. Changes apply from the next song. Downloads always keep the original quality.`
  String get streamingQualityNote {
    return Intl.message(
      'Songs above the limit are converted by your server. Changes apply from the next song. Downloads always keep the original quality.',
      name: 'streamingQualityNote',
      desc: '',
      args: [],
    );
  }

  /// `Studio Mode`
  String get studioMode {
    return Intl.message('Studio Mode', name: 'studioMode', desc: '', args: []);
  }

  /// `Make player full screen when Studio Mode enabled`
  String get studioModeFullscreenSetting {
    return Intl.message(
      'Make player full screen when Studio Mode enabled',
      name: 'studioModeFullscreenSetting',
      desc: '',
      args: [],
    );
  }

  /// `Studio mode`
  String get studioModeTooltip {
    return Intl.message(
      'Studio mode',
      name: 'studioModeTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Successfully added to playlist`
  String get successfullyAddedToPlaylist {
    return Intl.message(
      'Successfully added to playlist',
      name: 'successfullyAddedToPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Successfully deleted album`
  String get successfullyDeletedAlbum {
    return Intl.message(
      'Successfully deleted album',
      name: 'successfullyDeletedAlbum',
      desc: '',
      args: [],
    );
  }

  /// `Successfully deleted playlist`
  String get successfullyDeletedPlaylist {
    return Intl.message(
      'Successfully deleted playlist',
      name: 'successfullyDeletedPlaylist',
      desc: '',
      args: [],
    );
  }

  /// `Support`
  String get support {
    return Intl.message('Support', name: 'support', desc: '', args: []);
  }

  /// `JellyBox support`
  String get supportEmailSubject {
    return Intl.message(
      'JellyBox support',
      name: 'supportEmailSubject',
      desc: '',
      args: [],
    );
  }

  /// `Questions, problems or ideas? Get in touch. Please try to report as much details as possible - that will help me to identify issue and help you with resolving it.`
  String get supportIntro {
    return Intl.message(
      'Questions, problems or ideas? Get in touch. Please try to report as much details as possible - that will help me to identify issue and help you with resolving it.',
      name: 'supportIntro',
      desc: '',
      args: [],
    );
  }

  /// `Switch server`
  String get switchServer {
    return Intl.message(
      'Switch server',
      name: 'switchServer',
      desc: '',
      args: [],
    );
  }

  /// `System`
  String get system {
    return Intl.message('System', name: 'system', desc: '', args: []);
  }

  /// `Tap the code to copy it`
  String get tapCodeToCopy {
    return Intl.message(
      'Tap the code to copy it',
      name: 'tapCodeToCopy',
      desc: '',
      args: [],
    );
  }

  /// `Tap to connect`
  String get tapToConnect {
    return Intl.message(
      'Tap to connect',
      name: 'tapToConnect',
      desc: '',
      args: [],
    );
  }

  /// `Jellybox counts app launches and sends crash reports to help fix bugs. Nothing about your library or listening is collected.`
  String get telemetryNote {
    return Intl.message(
      'Jellybox counts app launches and sends crash reports to help fix bugs. Nothing about your library or listening is collected.',
      name: 'telemetryNote',
      desc: '',
      args: [],
    );
  }

  /// `Opt out of analytics and crash reports`
  String get telemetryOptOutSetting {
    return Intl.message(
      'Opt out of analytics and crash reports',
      name: 'telemetryOptOutSetting',
      desc: '',
      args: [],
    );
  }

  /// `TheAudioDB album`
  String get theAudioDbAlbum {
    return Intl.message(
      'TheAudioDB album',
      name: 'theAudioDbAlbum',
      desc: '',
      args: [],
    );
  }

  /// `TheAudioDB artist`
  String get theAudioDbArtist {
    return Intl.message(
      'TheAudioDB artist',
      name: 'theAudioDbArtist',
      desc: '',
      args: [],
    );
  }

  /// `This action needs a connection`
  String get thisActionNeedsAConnection {
    return Intl.message(
      'This action needs a connection',
      name: 'thisActionNeedsAConnection',
      desc: '',
      args: [],
    );
  }

  /// `This device`
  String get thisDevice {
    return Intl.message('This device', name: 'thisDevice', desc: '', args: []);
  }

  /// `Title`
  String get title {
    return Intl.message('Title', name: 'title', desc: '', args: []);
  }

  /// `Trust`
  String get trust {
    return Intl.message('Trust', name: 'trust', desc: '', args: []);
  }

  /// `JellyBox will trust {host} from now on, even if its certificate changes. Only continue if this is your server.`
  String trustFromNowOn(String host) {
    return Intl.message(
      'JellyBox will trust $host from now on, even if its certificate changes. Only continue if this is your server.',
      name: 'trustFromNowOn',
      desc: '',
      args: [host],
    );
  }

  /// `Try again`
  String get tryAgain {
    return Intl.message('Try again', name: 'tryAgain', desc: '', args: []);
  }

  /// `Tunnel`
  String get tunnel {
    return Intl.message('Tunnel', name: 'tunnel', desc: '', args: []);
  }

  /// `Remote access is set up, but the tunnel is not answering.`
  String get tunnelNotAnswering {
    return Intl.message(
      'Remote access is set up, but the tunnel is not answering.',
      name: 'tunnelNotAnswering',
      desc: '',
      args: [],
    );
  }

  /// `Remote access is set up and the tunnel is ready.`
  String get tunnelReady {
    return Intl.message(
      'Remote access is set up and the tunnel is ready.',
      name: 'tunnelReady',
      desc: '',
      args: [],
    );
  }

  /// `UI`
  String get ui {
    return Intl.message('UI', name: 'ui', desc: '', args: []);
  }

  /// `Unmute`
  String get unmute {
    return Intl.message('Unmute', name: 'unmute', desc: '', args: []);
  }

  /// `Untrusted certificate`
  String get untrustedCertificate {
    return Intl.message(
      'Untrusted certificate',
      name: 'untrustedCertificate',
      desc: '',
      args: [],
    );
  }

  /// `{host} uses a certificate that cannot be verified automatically.`
  String unverifiableCertificate(String host) {
    return Intl.message(
      '$host uses a certificate that cannot be verified automatically.',
      name: 'unverifiableCertificate',
      desc: '',
      args: [host],
    );
  }

  /// `JellyBox {version} is available`
  String updateAvailable(String version) {
    return Intl.message(
      'JellyBox $version is available',
      name: 'updateAvailable',
      desc: '',
      args: [version],
    );
  }

  /// `Use video covers when available`
  String get useVideoCoversSetting {
    return Intl.message(
      'Use video covers when available',
      name: 'useVideoCoversSetting',
      desc: '',
      args: [],
    );
  }

  /// `User token`
  String get userToken {
    return Intl.message('User token', name: 'userToken', desc: '', args: []);
  }

  /// `Version {version} ({build})`
  String versionBuildLabel(String version, String build) {
    return Intl.message(
      'Version $version ($build)',
      name: 'versionBuildLabel',
      desc: '',
      args: [version, build],
    );
  }

  /// `Version {version}`
  String versionLabel(String version) {
    return Intl.message(
      'Version $version',
      name: 'versionLabel',
      desc: '',
      args: [version],
    );
  }

  /// `View on`
  String get viewOn {
    return Intl.message('View on', name: 'viewOn', desc: '', args: []);
  }

  /// `Waiting for approval`
  String get waitingForApproval {
    return Intl.message(
      'Waiting for approval',
      name: 'waitingForApproval',
      desc: '',
      args: [],
    );
  }

  /// `Waking up…`
  String get wakingUp {
    return Intl.message('Waking up…', name: 'wakingUp', desc: '', args: []);
  }

  /// `What's new`
  String get whatsNew {
    return Intl.message('What\'s new', name: 'whatsNew', desc: '', args: []);
  }

  /// `While charging`
  String get whileCharging {
    return Intl.message(
      'While charging',
      name: 'whileCharging',
      desc: '',
      args: [],
    );
  }

  /// `Wi-Fi`
  String get wifi {
    return Intl.message('Wi-Fi', name: 'wifi', desc: '', args: []);
  }

  /// `Yes`
  String get yes {
    return Intl.message('Yes', name: 'yes', desc: '', args: []);
  }

  /// `You may also like`
  String get youMayAlsoLike {
    return Intl.message(
      'You may also like',
      name: 'youMayAlsoLike',
      desc: '',
      args: [],
    );
  }

  /// `Your device`
  String get yourDevice {
    return Intl.message('Your device', name: 'yourDevice', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
