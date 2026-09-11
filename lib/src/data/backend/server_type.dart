enum ServerType {
  jellyfin,
  emby;

  String get label => switch (this) {
    ServerType.jellyfin => 'Jellyfin',
    ServerType.emby => 'Emby',
  };
}
