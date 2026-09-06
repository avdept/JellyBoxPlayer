const _containerMimeTypes = <String, String>{
  'mp3': 'audio/mpeg',
  'aac': 'audio/aac',
  'm4a': 'audio/mp4',
  'm4b': 'audio/mp4',
  'flac': 'audio/flac',
  'wav': 'audio/wav',
  'aiff': 'audio/aiff',
  'ogg': 'audio/ogg',
  'oga': 'audio/ogg',
  'opus': 'audio/opus',
  'wma': 'audio/x-ms-wma',
  'm3u8': 'application/vnd.apple.mpegurl',
};

const _mimeTypeAliases = <String, String>{
  'audio/mp3': 'audio/mpeg',
  'audio/x-mp3': 'audio/mpeg',
  'audio/mpeg3': 'audio/mpeg',
  'audio/x-mpeg': 'audio/mpeg',
  'audio/x-mpegaudio': 'audio/mpeg',
  'audio/x-flac': 'audio/flac',
  'audio/x-m4a': 'audio/mp4',
  'audio/m4a': 'audio/mp4',
  'audio/mp4a-latm': 'audio/mp4',
  'audio/x-aac': 'audio/aac',
  'audio/vnd.dlna.adts': 'audio/aac',
  'audio/aacp': 'audio/aac',
  'audio/x-wav': 'audio/wav',
  'audio/wave': 'audio/wav',
  'audio/vnd.wave': 'audio/wav',
  'audio/x-aiff': 'audio/aiff',
  'audio/vorbis': 'audio/ogg',
  'audio/x-ogg': 'audio/ogg',
  'audio/x-vorbis+ogg': 'audio/ogg',
};

String mimeTypeForContainer(String container) =>
    _containerMimeTypes[container.toLowerCase()] ?? 'application/octet-stream';

String normalizeAudioMimeType(String mimeType) {
  final lower = mimeType.trim().toLowerCase();
  return _mimeTypeAliases[lower] ?? lower;
}

Set<String> containersForMimeType(String mimeType) {
  final canonical = normalizeAudioMimeType(mimeType);
  return {
    for (final entry in _containerMimeTypes.entries)
      if (entry.value == canonical) entry.key,
  };
}
