import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  bool isLoading = true;
  List<LibraryDTO> libraries = [];

  late DeviceType _device;

  Future<void> _onLibraryTap(LibraryDTO lib) async {
    await ref.read(currentLibraryProvider.notifier).setSelectLibrary(lib);
  }

  @override
  void initState() {
    super.initState();
    ref.read(currentLibraryProvider.notifier).fetchLibraries().then((value) {
      setState(() {
        libraries = value
            .where((element) =>
                element.type == 'CollectionFolder' &&
                element.collectionType == 'music')
            .toList();
        isLoading = false;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      onKeyEvent: (value) {
        if (value.logicalKey == LogicalKeyboardKey.enter) {
          _onLibraryTap(libraries[0])
              .then((value) => context.go(Routes.listen));
        }
      },
      focusNode: FocusNode(
        onKeyEvent: (node, event) {
          debugPrint(
              'Focus node ${node.debugLabel} got key event: ${event.logicalKey}');
          return KeyEventResult.handled;
        },
      ),
      child: ScrollablePageScaffold(
        navigationBar: PreferredSize(
          preferredSize: Size.fromHeight(_device.isMobile ? 48 : 100),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _device.isMobile ? 16 : 30,
            ),
            child: Row(
              children: [
                CircleAvatar(radius: _device.isDesktop ? 22.5 : 13),
                const SizedBox(width: 10),
                _titleText(),
                const Spacer(),
                _searchButton(),
                TextButton(
                  onPressed: ref.read(authProvider.notifier).logout,
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
        contentPadding: EdgeInsets.only(
          left: _device.isMobile ? 16 : 30,
          right: _device.isMobile ? 16 : 30,
          bottom: _device.isMobile ? 8 : 20,
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: _device.isMobile ? 16 : 30,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: (_device.isDesktop || _device.isTablet)
                  ? SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: _device.isTablet ? 370 : 358,
                      mainAxisSpacing: _device.isMobile ? 13 : 34,
                      crossAxisSpacing:
                          _device.isDesktop ? 24 : (_device.isMobile ? 16 : 34),
                      childAspectRatio: 370 / 255,
                    )
                  : const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisExtent: 250,
                    ),
              itemBuilder: (context, index) => LibraryView(
                library: libraries[index],
                onTap: () => _onLibraryTap(libraries[index])
                    .then((value) => context.go(Routes.listen)),
              ),
              itemCount: libraries.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleText() => const Text(
        'Select Library',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );

  Widget _searchButton() => IconButton(
        onPressed: () {},
        icon: const Icon(JPlayer.search),
      );
}
