final _trailingSlashes = RegExp(r'/+$');
final _leadingSlashes = RegExp(r'^/+');

Uri joinServerLocation(String base, Uri location) {
  final root = Uri.parse(base);
  final prefix = root.path.replaceAll(_trailingSlashes, '');
  final path = location.path.replaceAll(_leadingSlashes, '');
  return root.replace(
    path: '$prefix/$path',
    query: location.hasQuery ? location.query : null,
  );
}

Uri? serverLocationOf(Uri uri, String base) {
  final root = Uri.parse(base);
  if (uri.scheme != root.scheme || uri.host != root.host) return null;
  if (uri.port != root.port) return null;
  final prefix = root.path.replaceAll(_trailingSlashes, '');
  if (!uri.path.startsWith('$prefix/')) return null;
  return Uri(
    path: uri.path.substring(prefix.length + 1),
    query: uri.hasQuery ? uri.query : null,
  );
}
