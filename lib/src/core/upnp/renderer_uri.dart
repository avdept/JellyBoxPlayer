import 'dart:io';

class RendererUriResolver {
  RendererUriResolver({
    Future<List<InternetAddress>> Function(String host)? lookup,
  }) : _lookup = lookup ?? InternetAddress.lookup;

  final Future<List<InternetAddress>> Function(String host) _lookup;
  final _resolved = <String, String?>{};

  Future<Uri> resolve(Uri uri) async {
    if (uri.host.isEmpty) return uri;
    if (InternetAddress.tryParse(uri.host) != null) return uri;

    final address = _resolved.containsKey(uri.host)
        ? _resolved[uri.host]
        : _resolved[uri.host] = await _addressOf(uri.host);

    return address == null ? uri : uri.replace(host: address);
  }

  Future<String?> _addressOf(String host) async {
    try {
      final addresses = await _lookup(host);
      for (final address in addresses) {
        if (address.type == InternetAddressType.IPv4) return address.address;
      }
    } on Object {
      return null;
    }
    return null;
  }
}

final rendererUriResolver = RendererUriResolver();
