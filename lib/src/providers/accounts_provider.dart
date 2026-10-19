import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/storages/account_store.dart';

final accountsProvider = StateProvider<List<ServerAccount>>((ref) => const []);
