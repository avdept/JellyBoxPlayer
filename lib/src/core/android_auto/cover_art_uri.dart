const coverArtAuthority = 'com.prodigytech.jellybox.covers';

Uri? androidCoverArtUri(Uri? uri) {
  if (uri == null || !uri.isScheme('file')) return uri;
  final segments = uri.pathSegments;
  if (segments.length < 2) return null;
  return Uri(
    scheme: 'content',
    host: coverArtAuthority,
    pathSegments: [segments[segments.length - 2]],
  );
}
