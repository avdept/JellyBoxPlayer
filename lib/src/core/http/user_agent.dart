import 'package:jplayer/main.dart';

const _project = 'https://github.com/avdept/JellyBoxPlayer';

String jellyboxUserAgent() {
  try {
    return 'JellyBox v${appInfo.version} ($_project)';
  } catch (_) {
    return 'JellyBox ($_project)';
  }
}
