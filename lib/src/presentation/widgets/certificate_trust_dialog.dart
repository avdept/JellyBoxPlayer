import 'package:flutter/material.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
import 'package:jplayer/src/presentation/widgets/adaptive_dialog_action.dart';

class CertificateTrustDialog extends StatelessWidget {
  const CertificateTrustDialog({required this.certificate, super.key});

  final ServerCertificate certificate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog.adaptive(
      title: Text(S.of(context).untrustedCertificate),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              certificate.selfSigned
                  ? S.of(context).selfSignedCertificate(certificate.host)
                  : S.of(context).unverifiableCertificate(certificate.host),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _field(context, S.of(context).issuedTo, certificate.commonName),
            _field(context, S.of(context).issuedBy, certificate.issuerName),
            _field(
              context,
              certificate.expired
                  ? S.of(context).expired
                  : S.of(context).expires,
              localizations.formatShortDate(certificate.validTo.toLocal()),
              valueColor: certificate.expired ? theme.colorScheme.error : null,
            ),
            _field(
              context,
              'SHA-256',
              certificate.readableFingerprint,
              monospace: true,
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context).trustFromNowOn(certificate.host),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        AdaptiveDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          isDefaultAction: true,
          child: Text(S.of(context).cancel),
        ),
        AdaptiveDialogAction(
          onPressed: () => Navigator.of(context).pop(true),
          isDestructiveAction: true,
          child: Text(S.of(context).trust),
        ),
      ],
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    String value, {
    bool monospace = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          SelectableText(
            value,
            style:
                (monospace
                        ? theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'Courier',
                          )
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
