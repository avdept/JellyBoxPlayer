
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';

Provider<JellyfinApi> jellyfinApiProvider = Provider<JellyfinApi>(
  (ref) => JellyfinApi(
    ref.watch(dioProvider),
    baseUrl: ref.watch(baseUrlProvider) ?? '',
  ),
);
