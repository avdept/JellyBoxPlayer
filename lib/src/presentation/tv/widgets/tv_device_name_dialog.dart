import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/cloud/cloud_host_adapter.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_button.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_text_field.dart';

class TvDeviceNameDialog extends ConsumerStatefulWidget {
  const TvDeviceNameDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const TvDeviceNameDialog(),
  );

  @override
  ConsumerState<TvDeviceNameDialog> createState() => _TvDeviceNameDialogState();
}

class _TvDeviceNameDialogState extends ConsumerState<TvDeviceNameDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.deviceName),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    ref
        .read(appSettingsProvider.notifier)
        .setValue(AppSetting.deviceName, _name.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Other devices see this name in the continuity device picker. '
              'Leave it empty to use "${continuityDeviceName()}".',
              style: TvTokens.body,
            ),
            const SizedBox(height: 20),
            TvTextField(
              label: 'Name',
              controller: _name,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              autofocus: true,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TvButton(
                  label: 'Cancel',
                  onSelect: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                TvButton(
                  label: 'Save',
                  icon: Icons.check,
                  primary: true,
                  onSelect: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
