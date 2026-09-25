import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingMediaPlayProvider = Provider<bool Function()>(
  (ref) =>
      () => false,
);
