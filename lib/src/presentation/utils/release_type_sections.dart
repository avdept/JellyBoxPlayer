import 'package:jplayer/src/domain/models/models.dart';

class ReleaseTypeSection {
  const ReleaseTypeSection({required this.label, required this.albums});

  final String label;
  final List<LibraryItem> albums;
}

const _primaryOrder = ['album', 'ep', 'single', 'broadcast'];

List<ReleaseTypeSection> releaseTypeSections(List<LibraryItem> albums) {
  final groups = <String, _Group>{};
  for (final album in albums) {
    final types = [
      for (final type in album.releaseTypes)
        if (type.trim().isNotEmpty) type.trim().toLowerCase(),
    ];
    final primary = types.firstWhere(
      _primaryOrder.contains,
      orElse: () => 'album',
    );
    final secondaries = [
      ...{
        for (final type in types)
          if (type != primary) type,
      },
    ]..sort();
    final key = [primary, ...secondaries].join('|');
    final group = groups.putIfAbsent(
      key,
      () => _Group(primary: primary, secondaries: secondaries),
    );
    group.albums.add(album);
  }
  final ordered = groups.values.toList()
    ..sort((a, b) {
      final byPrimary = _primaryOrder
          .indexOf(a.primary)
          .compareTo(_primaryOrder.indexOf(b.primary));
      return byPrimary != 0 ? byPrimary : a.label.compareTo(b.label);
    });
  return [
    for (final group in ordered)
      ReleaseTypeSection(label: group.label, albums: group.albums),
  ];
}

class _Group {
  _Group({required this.primary, required this.secondaries});

  final String primary;
  final List<String> secondaries;
  final List<LibraryItem> albums = [];

  String get label {
    final head = '${_display(primary)}s';
    if (secondaries.isEmpty) return head;
    return '$head – ${secondaries.map(_display).join(' – ')}';
  }
}

String _display(String type) {
  if (type == 'ep') return 'EP';
  return type
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
      )
      .join(' ');
}
