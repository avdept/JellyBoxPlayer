import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/cloud/cloud_host_adapter.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';

Future<void> editDeviceName(BuildContext context) =>
    showFormModal<void>(context, builder: (context) => const DeviceNameForm());

class DeviceNameForm extends ConsumerStatefulWidget {
  const DeviceNameForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  final EdgeInsets padding;

  @override
  ConsumerState<DeviceNameForm> createState() => _DeviceNameFormState();
}

class _DeviceNameFormState extends ConsumerState<DeviceNameForm> {
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

  void _submit() {
    ref
        .read(appSettingsProvider.notifier)
        .setValue(AppSetting.deviceName, _name.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);

    return SafeArea(
      top: false,
      minimum: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalFormHeader('Device name'),
          const SizedBox(height: 8),
          Text(
            'Other devices see this name in the continuity device picker. '
            'Leave it empty to use the default.',
            style: TextStyle(fontSize: 14, color: muted),
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            controller: _name,
            label: 'Name',
            placeholder: continuityDeviceName(),
            autofocus: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          ModalFormActions(submitLabel: 'Save', onSubmit: _submit),
        ],
      ),
    );
  }
}
