import 'package:optional_features/jellybox_cloud.dart';
import 'package:test/test.dart';

class _Host implements CloudHost<String> {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  test('the stub reports itself unavailable', () {
    expect(JellyboxCloud<String>(host: _Host()).available, isFalse);
  });

  test('the stub never signs in', () async {
    final cloud = JellyboxCloud<String>(host: _Host());
    expect(
      await cloud.signIn(address: 'x', email: 'y', password: 'z'),
      isFalse,
    );
    expect(cloud.state.signedIn, isFalse);
  });
}
