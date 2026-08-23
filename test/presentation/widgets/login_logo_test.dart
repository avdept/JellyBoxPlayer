import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('logo assets', () {
    for (final asset in [
      SvgPictures.jellyboxLogo,
      SvgPictures.jellyfinLogo,
      SvgPictures.embyLogo,
    ]) {
      test('- $asset is an SVG flutter_svg can compile', () async {
        final bytes = await SvgAssetLoader(asset).loadBytes(null);

        expect(bytes.lengthInBytes, greaterThan(0));
      });
    }
  });

  Widget wrap(ServerType? serverType) => MaterialApp(
    home: Scaffold(
      body: Center(child: LoginLogo(serverType: serverType)),
    ),
  );

  Finder assetSvg(String asset) => find.byWidgetPredicate(
    (widget) =>
        widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName == asset,
  );

  Finder jellybox() => assetSvg(SvgPictures.jellyboxLogo);

  double badgeOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .ancestor(
              of: assetSvg(SvgPictures.embyLogo),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

  testWidgets('- shows the JellyBox logo alone, filling the box', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(null));
    await tester.pumpAndSettle();

    expect(jellybox(), findsOneWidget);
    expect(tester.getSize(find.byType(LoginLogo)), const Size(160, 160));
    expect(tester.getSize(jellybox()), const Size(160, 160));
  });

  testWidgets('- keeps the same footprint once a server is discovered', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(ServerType.emby));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(LoginLogo)), const Size(160, 160));
  });

  testWidgets('- shrinks the JellyBox logo into the top left corner', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(null));
    await tester.pumpAndSettle();
    final box = tester.getRect(find.byType(LoginLogo));

    await tester.pumpWidget(wrap(ServerType.emby));
    await tester.pumpAndSettle();
    final shrunk = tester.getRect(jellybox());

    expect(shrunk.width, lessThan(box.width));
    expect(shrunk.left, lessThan(box.center.dx));
    expect(shrunk.top, lessThan(box.center.dy));
    expect(shrunk.left - box.left, closeTo(5, 0.001));
    expect(shrunk.top - box.top, closeTo(5, 0.001));
  });

  testWidgets('- draws both marks at the same size once paired', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(ServerType.emby));
    await tester.pumpAndSettle();

    final logo = tester.getSize(jellybox());
    final badge = tester.getSize(assetSvg(SvgPictures.embyLogo));

    expect(logo, badge);
    expect(logo, const Size(100, 100));
  });

  testWidgets('- keeps the marks equally sized mid-animation too', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(null));
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(ServerType.jellyfin));
    await tester.pump(const Duration(milliseconds: 200));

    final logo = tester.getSize(jellybox());
    final badge = tester.getSize(assetSvg(SvgPictures.jellyfinLogo));

    expect(logo.width, greaterThan(badge.width));
    expect(badge, const Size(100, 100));
  });

  testWidgets('- settles the server badge diagonally, slightly overlapping', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(ServerType.emby));
    await tester.pumpAndSettle();

    final box = tester.getRect(find.byType(LoginLogo));
    final logo = tester.getRect(jellybox());
    final badge = tester.getRect(assetSvg(SvgPictures.embyLogo));

    expect(badge.left, greaterThan(logo.left));
    expect(badge.top, greaterThan(logo.top));
    expect(logo.overlaps(badge), isTrue);
    expect(logo.intersect(badge).width, closeTo(50, 0.001));
    expect(
      logo.intersect(badge).width / logo.width,
      greaterThanOrEqualTo(0.5),
    );
    expect(logo.left - box.left, closeTo(box.right - badge.right, 0.001));
    expect(logo.top - box.top, closeTo(box.bottom - badge.bottom, 0.001));
  });

  testWidgets('- fades and slides the badge in rather than snapping it', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(null));
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(ServerType.emby));
    await tester.pump();
    expect(badgeOpacity(tester), 0);
    final entryRect = tester.getRect(assetSvg(SvgPictures.embyLogo));

    await tester.pump(const Duration(milliseconds: 260));
    final midOpacity = badgeOpacity(tester);
    final midRect = tester.getRect(assetSvg(SvgPictures.embyLogo));

    await tester.pumpAndSettle();

    expect(midOpacity, greaterThan(0));
    expect(midOpacity, lessThan(1));
    expect(badgeOpacity(tester), 1);
    expect(midRect.left, lessThan(entryRect.left));
    expect(
      tester.getRect(assetSvg(SvgPictures.embyLogo)).left,
      lessThan(midRect.left),
    );
  });

  testWidgets('- uses the Jellyfin badge for a Jellyfin server', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(ServerType.jellyfin));
    await tester.pumpAndSettle();

    expect(assetSvg(SvgPictures.jellyfinLogo), findsOneWidget);
    expect(assetSvg(SvgPictures.embyLogo), findsNothing);
  });

  testWidgets('- returns to the lone JellyBox logo when discovery is cleared', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(ServerType.emby));
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(null));
    await tester.pumpAndSettle();

    expect(tester.getSize(jellybox()), const Size(160, 160));
    expect(badgeOpacity(tester), 0);
  });
}
