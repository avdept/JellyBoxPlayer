import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/scrollable_page_scaffold.dart';
import 'package:jplayer/src/presentation/widgets/song_list_sliver.dart';

class InstantMixPage extends ConsumerStatefulWidget {
  const InstantMixPage({required this.mix, super.key});

  final LibraryItem mix;

  @override
  ConsumerState<InstantMixPage> createState() => _InstantMixPageState();
}

class _InstantMixPageState extends ConsumerState<InstantMixPage> {
  late ThemeData _theme;
  late DeviceType _device;

  @override
  void initState() {
    super.initState();
    ref.read(instantMixesProvider.notifier).refresh(widget.mix.id).ignore();
  }

  double get _horizontalPadding => _device.isMobile ? 16 : 30;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final mixId = widget.mix.id;
    final mix = ref.watch(
      instantMixesProvider.select(
        (mixes) => mixes.where((mix) => mix.item.id == mixId).firstOrNull,
      ),
    );

    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(_device.isMobile ? 60 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Row(
            children: [
              CupertinoNavigationBarBackButton(
                color: _theme.colorScheme.onPrimary,
                onPressed: () => context.pop(),
              ),
              SizedBox(width: _device.isMobile ? 12 : 20),
              Expanded(
                child: Text(
                  widget.mix.name,
                  style: TextStyle(
                    fontSize: _device.isMobile ? 20 : 26,
                    fontWeight: FontWeight.w600,
                    color: _theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      contentPadding: const EdgeInsets.only(bottom: 30),
      slivers: [
        if (mix == null)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('This mix is no longer available')),
            ),
          )
        else
          SongListSliver(
            songs: mix.songs,
            set: mix.item,
            edgePadding: _horizontalPadding,
            onItemUpdated: (song) =>
                ref.read(instantMixesProvider.notifier).updateSong(mixId, song),
          ),
      ],
    );
  }
}
