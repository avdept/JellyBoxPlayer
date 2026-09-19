enum ServerType {
  jellyfin,
  emby,
  subsonic;

  String get label => switch (this) {
    ServerType.jellyfin => 'Jellyfin',
    ServerType.emby => 'Emby',
    ServerType.subsonic => 'Subsonic',
  };
}
