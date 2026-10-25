import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/sleep_timer_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';

class SleepTimerButton extends ConsumerWidget {
  const SleepTimerButton({this.color, this.iconSize, this.style, super.key});

  final Color? color;
  final double? iconSize;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(sleepTimerProvider) != null;
    return HoverIconButton(
      onPressed: () => unawaited(showSleepTimerModal(context)),
      color: color,
      selectedColor: Colors.redAccent,
      iconSize: iconSize,
      style: style,
      tooltip: 'Sleep timer',
      icon: const Icon(Icons.schedule),
      selectedIcon: const Icon(Icons.watch_later),
      isSelected: isActive,
    );
  }
}

Future<void> showSleepTimerModal(BuildContext context) =>
    showFormModal<void>(context, builder: (context) => const SleepTimerForm());

class SleepTimerForm extends ConsumerStatefulWidget {
  const SleepTimerForm({super.key});

  @override
  ConsumerState<SleepTimerForm> createState() => _SleepTimerFormState();
}

class _SleepTimerFormState extends ConsumerState<SleepTimerForm> {
  late SleepTimerMode _mode;
  late final TextEditingController _tracksController;
  late int _minutes;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final timer = ref.read(sleepTimerProvider);
    _mode = timer?.mode ?? SleepTimerMode.minutes;
    _tracksController = TextEditingController(text: '${timer?.tracks ?? 5}');
    _minutes = timer?.minutes ?? 15;
    _time = timer?.mode == SleepTimerMode.time
        ? TimeOfDay.fromDateTime(timer!.endsAt!)
        : TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  }

  @override
  void dispose() {
    _tracksController.dispose();
    super.dispose();
  }

  int? get _trackCount => int.tryParse(_tracksController.text);

  bool get _canSave =>
      _mode != SleepTimerMode.tracks || (_trackCount ?? 0) > 0;

  void _save() {
    final notifier = ref.read(sleepTimerProvider.notifier);
    switch (_mode) {
      case SleepTimerMode.tracks:
        final tracks = _trackCount;
        if (tracks == null || tracks < 1) return;
        notifier.startTracks(tracks);
      case SleepTimerMode.minutes:
        notifier.startMinutes(_minutes);
      case SleepTimerMode.time:
        notifier.startTime(_time.hour, _time.minute);
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickTime() async {
    setState(() => _mode = SleepTimerMode.time);
    final isDesktop = DeviceType.fromScreenSize(
      MediaQuery.sizeOf(context),
    ).isDesktop;
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      initialEntryMode: isDesktop
          ? TimePickerEntryMode.input
          : TimePickerEntryMode.dial,
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  void _cancel() {
    if (ref.read(sleepTimerProvider) != null) {
      ref.read(sleepTimerProvider.notifier).cancel();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ModalFormHeader('Stop in'),
        const SizedBox(height: 8),
        RadioGroup<SleepTimerMode>(
          groupValue: _mode,
          onChanged: (mode) => setState(() => _mode = mode ?? _mode),
          child: Column(
            children: [
              Row(
                children: [
                  const Radio(value: SleepTimerMode.tracks),
                  SizedBox(width: 64, child: _tracksField()),
                  const SizedBox(width: 10),
                  const Text('tracks'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Radio(value: SleepTimerMode.minutes),
                  Expanded(
                    child: Slider(
                      value: _minutes.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      label: '$_minutes min',
                      onChanged: (value) => setState(() {
                        _mode = SleepTimerMode.minutes;
                        _minutes = value.round();
                      }),
                    ),
                  ),
                  SizedBox(width: 56, child: Text('$_minutes min')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Radio(value: SleepTimerMode.time),
                  const Text('at'),
                  const SizedBox(width: 10),
                  _timeButton(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _cancel,
              style: ModalFormActions.buttonStyle(context),
              child: Text(
                ref.watch(sleepTimerProvider) != null
                    ? 'Stop timer'
                    : 'Cancel',
              ),
            ),
            TextButton(
              onPressed: _canSave ? _save : null,
              style: ModalFormActions.buttonStyle(context, primary: true),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _timeButton() => TextButton(
    onPressed: () => unawaited(_pickTime()),
    style: TextButton.styleFrom(
      backgroundColor: const Color(0xFFEEEEEE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    child: Text(
      _time.format(context),
      style: const TextStyle(color: Colors.black87),
    ),
  );

  Widget _tracksField() => TextField(
    controller: _tracksController,
    keyboardType: TextInputType.number,
    textAlign: TextAlign.center,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
    onTap: () => setState(() => _mode = SleepTimerMode.tracks),
    onChanged: (_) => setState(() => _mode = SleepTimerMode.tracks),
    style: const TextStyle(color: Colors.black87),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFFEEEEEE),
      isDense: true,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
  );
}
