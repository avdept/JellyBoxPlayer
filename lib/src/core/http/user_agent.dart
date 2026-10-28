import 'package:jplayer/main.dart';

const _project = 'https://github.com/avdept/JellyBoxPlayer';

String jellyboxUserAgent() {
  try {
    return 'JellyBox/${appInfo.version} ($_project)';
  } on Object {
    return 'JellyBox ($_project)';
  }
}
