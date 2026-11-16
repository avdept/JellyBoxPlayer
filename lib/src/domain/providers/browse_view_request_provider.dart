import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';

final browseViewRequestProvider = StateProvider<ItemList?>((ref) => null);

final browseTabSelectedProvider = StateProvider<int>((ref) => 0);
