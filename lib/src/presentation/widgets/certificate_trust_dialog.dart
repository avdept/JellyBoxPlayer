import 'package:flutter/material.dart';
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
      title: const Text('Untrusted certificate'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              certificate.selfSigned
                  ? '${certificate.host} uses a self-signed certificate, so '
                        'its identity cannot be verified automatically.'
                  : '${certificate.host} uses a certificate that cannot be '
                        'verified automatically.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _field(context, 'Issued to', certificate.commonName),
            _field(context, 'Issued by', certificate.issuerName),
            _field(
              context,
              certificate.expired ? 'Expired' : 'Expires',
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
              'Only continue if this fingerprint matches your server.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        AdaptiveDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
        AdaptiveDialogAction(
          onPressed: () => Navigator.of(context).pop(true),
          isDestructiveAction: true,
          child: const Text('Trust'),
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
