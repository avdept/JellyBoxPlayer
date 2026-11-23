import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/telemetry/telemetry.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/lidarr_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/lidarr_connect_form.dart';
import 'package:optional_features/lidarr.dart';

Future<void> showLidarrAddSheet(BuildContext context, LidarrTarget target) =>
    showFormModal<void>(
      context,
      builder: (context) => LidarrAddSheet(target: target),
    );

class LidarrAddSheet extends ConsumerStatefulWidget {
  const LidarrAddSheet({
    required this.target,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  final LidarrTarget target;
  final EdgeInsets padding;

  @override
  ConsumerState<LidarrAddSheet> createState() => _LidarrAddSheetState();
}

class _LidarrAddSheetState extends ConsumerState<LidarrAddSheet> {
  LidarrAddPlan? _plan;
  String? _error;
  var _selected = 0;
  var _monitorArtist = true;
  var _submitting = false;
  var _confirmingMonitor = false;

  @override
  void initState() {
    super.initState();
    final connected = ref.read(lidarrClientProvider) != null;
    Telemetry.track(
      'lidarr-add-opened',
      props: {'kind': _kind, 'connected': '$connected'},
    );
    if (connected) unawaited(_load());
  }

  String get _kind => switch (widget.target) {
    LidarrAlbumTarget() => 'album',
    LidarrArtistTarget() => 'artist',
  };

  void _trackSubmit(String result) => Telemetry.track(
    'lidarr-add-confirmed',
    props: {
      'kind': _kind,
      'result': result,
      if (widget.target is LidarrAlbumTarget)
        'monitor-artist': '$_monitorArtist',
    },
  );

  Future<void> _load() async {
    try {
      final plan = await ref.read(lidarrAdderProvider).plan(widget.target);
      if (!mounted) return;
      setState(() => _plan = plan);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _describe(error));
    }
  }

  void _onAdd() {
    final plan = _plan;
    if (plan == null) return;
    final confirmed = ref.read(
      settingProvider(AppSetting.lidarrMonitorArtistConfirmed),
    );
    if (_artistIsNew(plan) && _monitorArtist && !confirmed) {
      setState(() => _confirmingMonitor = true);
      return;
    }
    unawaited(_submit());
  }

  void _confirmMonitor() {
    ref
        .read(appSettingsProvider.notifier)
        .setEnabled(AppSetting.lidarrMonitorArtistConfirmed, value: true);
    setState(() => _confirmingMonitor = false);
    unawaited(_submit());
  }

  Future<void> _submit() async {
    final plan = _plan;
    final placement = ref.read(lidarrPlacementProvider).valueOrNull;
    if (plan == null || placement == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final adder = ref.read(lidarrAdderProvider);
    final search = ref.read(settingProvider(AppSetting.lidarrSearchOnAdd));
    try {
      final outcome = plan.albums.isNotEmpty
          ? await adder.addAlbum(
              plan.albums[_selected],
              defaults: placement.defaults,
              search: search,
              monitorArtist: _monitorArtist,
            )
          : await adder.addArtist(
              plan.artists[_selected],
              defaults: placement.defaults,
              search: search,
            );
      _trackSubmit(switch (outcome) {
        LidarrAddOutcome.added => 'added',
        LidarrAddOutcome.alreadyAdded => 'already-added',
      });
      if (!mounted) return;
      final name = plan.albums.isNotEmpty
          ? plan.albums[_selected].title
          : plan.artists[_selected].name;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (outcome) {
            LidarrAddOutcome.added => 'Added "$name" to Lidarr',
            LidarrAddOutcome.alreadyAdded => '"$name" is already in Lidarr',
          }),
        ),
      );
    } on Object catch (error) {
      _trackSubmit('failed');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _describe(error);
      });
    }
  }

  static String _describe(Object error) => error is LidarrException
      ? error.message
      : 'Lidarr request failed: $error';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    final connected = ref.watch(lidarrClientProvider) != null;
    final placement = ref.watch(lidarrPlacementProvider);
    final plan = _plan;
    final status = switch (widget.target) {
      LidarrAlbumTarget(:final album) =>
        ref
            .watch(
              lidarrAlbumStatusProvider((
                upc: album.upc,
                artistName: album.artistName,
              )),
            )
            .valueOrNull,
      LidarrArtistTarget() => null,
    };
    final inLidarr =
        plan != null &&
        plan.exact &&
        _alreadyAdded(plan) &&
        status != null &&
        status.state != LidarrEntityState.notAdded;

    return SafeArea(
      top: false,
      minimum: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModalFormHeader(inLidarr ? widget.target.title : 'Add to Lidarr'),
          const SizedBox(height: 12),
          if (_confirmingMonitor) ...[
            Text(
              'Monitoring the artist tells Lidarr to monitor every album '
              'by ${plan?.albums[_selected].artist?.name ?? 'this artist'}, '
              'not only this one. Lidarr will also keep adding new '
              'releases as they come out.',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Uncheck "Monitor artist" to add only this album. '
              'This notice is shown once.',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _confirmingMonitor = false),
                  style: ModalFormActions.buttonStyle(context),
                  child: const Text('Back'),
                ),
                TextButton(
                  onPressed: _confirmMonitor,
                  style: ModalFormActions.buttonStyle(context, primary: true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ] else if (!connected) ...[
            Text(
              'Connect your Lidarr server first.',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 8),
            LidarrConnectForm.embedded(onConnected: () => unawaited(_load())),
          ] else if (plan == null && _error == null) ...[
            Row(
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Looking up "${widget.target.title}" in Lidarr…',
                  style: TextStyle(fontSize: 14, color: muted),
                ),
              ],
            ),
          ] else ...[
            if (plan != null) ...[
              if (plan.candidateCount == 0)
                Text(
                  'Lidarr could not find "${widget.target.title}".',
                  style: TextStyle(fontSize: 14, color: muted),
                )
              else if (inLidarr) ...[
                Text(
                  _statusLine(status),
                  style: TextStyle(fontSize: 14, color: muted),
                ),
              ] else ...[
                Text(
                  plan.exact
                      ? 'Lidarr will add:'
                      : 'Lidarr found these, pick the right one:',
                  style: TextStyle(fontSize: 14, color: muted),
                ),
                const SizedBox(height: 8),
                ..._candidates(plan, theme),
                if (_artistIsNew(plan))
                  CheckboxListTile(
                    value: _monitorArtist,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Monitor artist'),
                    subtitle: const Text(
                      'Lidarr will also monitor artist for new releases',
                    ),
                    onChanged: _submitting
                        ? null
                        : (value) =>
                              setState(() => _monitorArtist = value ?? true),
                  ),
                const SizedBox(height: 12),
                _placementSummary(placement, muted, plan),
              ],
            ],
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (plan != null && plan.candidateCount > 0 && !_alreadyAdded(plan))
              ModalFormActions(
                submitLabel: 'Add',
                onSubmit: placement.valueOrNull == null ? () {} : _onAdd,
                busy: _submitting || placement.isLoading,
              ),
          ],
        ],
      ),
    );
  }

  String _statusLine(LidarrEntityStatus status) {
    final title = widget.target.title;
    return switch (status.state) {
      LidarrEntityState.monitored => 'Lidarr monitors "$title"',
      LidarrEntityState.downloading =>
        'Lidarr adds "$title" at ${((status.progress ?? 0) * 100).round()}%',
      LidarrEntityState.downloaded => 'Lidarr added "$title"',
      LidarrEntityState.added || LidarrEntityState.notAdded =>
        'Lidarr has "$title" but does not monitor it',
    };
  }

  bool _alreadyAdded(LidarrAddPlan plan) => plan.albums.isNotEmpty
      ? plan.albums[_selected].isAdded
      : plan.artists[_selected].isAdded;

  bool _artistIsNew(LidarrAddPlan plan) =>
      plan.albums.isNotEmpty &&
      !plan.albums[_selected].isAdded &&
      !(plan.albums[_selected].artist?.isAdded ?? true);

  List<Widget> _candidates(LidarrAddPlan plan, ThemeData theme) {
    final rows = <({String title, String subtitle, bool added})>[
      for (final album in plan.albums)
        (
          title: album.title,
          subtitle: [
            ?album.artist?.name,
            ?album.albumType,
            if (album.releaseDate case final date?) '${date.year}',
            if (album.isAdded) 'already in Lidarr',
          ].join(' · '),
          added: album.isAdded,
        ),
      for (final artist in plan.artists)
        (
          title: artist.name,
          subtitle: [
            ?artist.disambiguation,
            if (artist.isAdded) 'already in Lidarr',
          ].join(' · '),
          added: artist.isAdded,
        ),
    ];
    if (rows.length == 1) {
      final row = rows.single;
      return [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            row.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: row.subtitle.isEmpty ? null : Text(row.subtitle),
        ),
      ];
    }
    return [
      RadioGroup<int>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value ?? 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < rows.length; index++)
              RadioListTile<int>(
                value: index,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  rows[index].title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: rows[index].subtitle.isEmpty
                    ? null
                    : Text(rows[index].subtitle),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _placementSummary(
    AsyncValue<LidarrPlacement?> placement,
    Color muted,
    LidarrAddPlan plan,
  ) {
    final value = placement.valueOrNull;
    final text = switch (placement) {
      AsyncError() => 'Could not read the Lidarr root folders.',
      AsyncData() when value == null =>
        'Choose a root folder for Lidarr in Settings first.',
      AsyncData() => [
        'Root folder: ${value!.rootFolder.label}',
        'Quality: ${value.qualityProfile?.name ?? '?'}',
        'Metadata: ${value.metadataProfile?.name ?? '?'}',
        switch (widget.target) {
          LidarrArtistTarget() => 'All albums will be monitored',
          LidarrAlbumTarget() when _artistIsNew(plan) && _monitorArtist =>
            'All albums will be monitored',
          LidarrAlbumTarget() => 'Only this album will be monitored',
        },
      ].join(' · '),
      _ => 'Reading Lidarr settings…',
    };
    return Text(text, style: TextStyle(fontSize: 12, color: muted));
  }
}
