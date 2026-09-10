import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
import 'package:jplayer/src/presentation/widgets/certificate_trust_dialog.dart';

void main() {
  ServerCertificate certificate({
    String subject = '/CN=jelly.local',
    String issuer = '/CN=jelly.local',
    DateTime? validTo,
  }) => ServerCertificate(
    host: 'jelly.local',
    port: 8920,
    fingerprint: 'a1b2c3',
    subject: subject,
    issuer: issuer,
    validFrom: DateTime.utc(2026),
    validTo: validTo ?? DateTime.utc(2027, 3, 4),
  );

  Future<bool?> showDialogFor(
    WidgetTester tester,
    ServerCertificate cert,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          S.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAdaptiveDialog<bool>(
                context: context,
                builder: (context) => CertificateTrustDialog(certificate: cert),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows the fingerprint and certificate details', (tester) async {
    await showDialogFor(tester, certificate());

    expect(find.text('Untrusted certificate'), findsOneWidget);
    expect(find.text('A1:B2:C3'), findsOneWidget);
    expect(find.text('Expires'), findsOneWidget);
    expect(find.text('Mar 4, 2027'), findsOneWidget);
    expect(find.textContaining('self-signed certificate'), findsOneWidget);
  });

  testWidgets('marks an expired certificate', (tester) async {
    await showDialogFor(
      tester,
      certificate(validTo: DateTime.utc(2020, 5, 6)),
    );

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('May 6, 2020'), findsOneWidget);
  });

  testWidgets('reports a certificate signed by another issuer', (tester) async {
    await showDialogFor(tester, certificate(issuer: '/CN=my-home-ca'));

    expect(find.textContaining('cannot be\nverified'), findsNothing);
    expect(find.text('my-home-ca'), findsOneWidget);
  });

  testWidgets('returns true only when Trust is tapped', (tester) async {
    await showDialogFor(tester, certificate());
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trust'));
    await tester.pumpAndSettle();

    expect(find.text('Untrusted certificate'), findsNothing);
  });
}
