import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/providers/pins_database_provider.dart';
import 'package:jplayer/src/data/storages/pins_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';

class PinsNotifier extends StateNotifier<List<PinnedItem>> {
  PinsNotifier(
    this._ref,
    this._database, {
    required Duration maxAge,
    DateTime Function()? now,
  }) : _maxAge = maxAge,
       _now = now ?? DateTime.now,
       super(const []) {
    restored = _restore();
  }

  final Ref _ref;
  final PinsDatabase _database;
  final Duration _maxAge;
  final DateTime Function() _now;

  late final Future<void> restored;

  Future<void> _restore() async {
    final List<PinnedItem> stored;
    try {
      stored = await _database.getPins(maxAge: _maxAge, now: _now);
    } on Object {
      return;
    }
    if (mounted) state = stored;
  }

  static bool canPin(LibraryItem item) =>
      pinnableKinds.contains(item.kind) &&
      !item.isRadioStream &&
      !EphemeralPlaylistId.isEphemeral(item.id);

  bool isPinned(String itemId) => state.any((pin) => pin.itemId == itemId);

  Future<void> toggle(LibraryItem item) =>
      isPinned(item.id) ? unpin(item.id) : pin(item);

  Future<void> pin(LibraryItem item) async {
    if (!canPin(item)) return;
    final pin = (
      itemId: item.id,
      kind: item.kind,
      name: item.name,
      imageUrl: _imageUrlOf(item),
      pinnedAt: _now(),
    );
    state = [pin, ...state.where((other) => other.itemId != item.id)];
    await _database.pin(pin);
  }

  Future<void> unpin(String itemId) async {
    state = [
      for (final pin in state)
        if (pin.itemId != itemId) pin,
    ];
    await _database.unpin(itemId);
  }

  Uri? _imageUrlOf(LibraryItem item) {
    if (!item.images.hasCover) return null;
    try {
      return _ref.read(mediaServerClientProvider).imageUri(item);
    } on Object {
      return null;
    }
  }
}

final pinsProvider = StateNotifierProvider<PinsNotifier, List<PinnedItem>>(
  (ref) => PinsNotifier(
    ref,
    ref.watch(pinsDatabaseProvider),
    maxAge: ref.watch(pinLongevityProvider).maxAge,
  ),
);

final ProviderFamily<bool, String> isPinnedProvider = Provider.family(
  (ref, itemId) => ref.watch(
    pinsProvider.select((pins) => pins.any((p) => p.itemId == itemId)),
  ),
);
