import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadsRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final downloadsRevisionProvider = NotifierProvider<DownloadsRevision, int>(
  DownloadsRevision.new,
);
