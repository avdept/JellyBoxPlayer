import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';

void main() {
  group('networkTypeFor', () {
    test('- treats mobile data as cellular', () {
      expect(networkTypeFor([ConnectivityResult.mobile]), NetworkType.cellular);
    });

    test('- treats a VPN over mobile data as cellular', () {
      expect(
        networkTypeFor([ConnectivityResult.vpn, ConnectivityResult.mobile]),
        NetworkType.cellular,
      );
    });

    test('- prefers Wi-Fi or ethernet when mobile data is also up', () {
      expect(
        networkTypeFor([ConnectivityResult.mobile, ConnectivityResult.wifi]),
        NetworkType.wifi,
      );
      expect(
        networkTypeFor([
          ConnectivityResult.mobile,
          ConnectivityResult.ethernet,
        ]),
        NetworkType.wifi,
      );
    });

    test('- treats any other link as Wi-Fi', () {
      expect(networkTypeFor([ConnectivityResult.vpn]), NetworkType.wifi);
      expect(networkTypeFor([ConnectivityResult.other]), NetworkType.wifi);
      expect(networkTypeFor([ConnectivityResult.bluetooth]), NetworkType.wifi);
    });

    test('- has no answer without a connection', () {
      expect(networkTypeFor([ConnectivityResult.none]), isNull);
      expect(networkTypeFor(const []), isNull);
    });
  });

  test('- assumes Wi-Fi on devices without a cellular radio', () {
    final notifier = NetworkTypeNotifier(hasCellular: false);
    addTearDown(notifier.dispose);

    expect(notifier.state, NetworkType.wifi);
  });
}
