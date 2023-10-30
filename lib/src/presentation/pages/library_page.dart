import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  Future<void> _onLibraryTap(LibraryDTO lib) async {
    await ref.read(currentLibraryProvider.notifier).setSelectLibrary(lib);
  }

  bool isLoading = true;
  List<LibraryDTO> libraries = [];

  @override
  void initState() {
    super.initState();
    ref.read(currentLibraryProvider.notifier).fetchLibraries().then((value) {
      setState(() {
        libraries = value.where((element) => element.type == 'CollectionFolder' && element.collectionType == 'music').toList();
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return ScrollablePageScaffold(
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 48 : 100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 30),
          child: Row(
            children: [
              CircleAvatar(
                radius: isDesktop ? 22.5 : 13,
              ),
              const SizedBox(width: 10),
              _titleText(),
              const Spacer(),
              _searchButton(),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: isMobile ? 16 : 30,
        right: isMobile ? 16 : 30,
        bottom: isMobile ? 8 : 20,
      ),
      slivers: [
        SliverGrid.builder(
          gridDelegate: isDesktop || isTablet
              ? SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isTablet ? 370 : 358,
            mainAxisSpacing: isMobile ? 13 : 34,
            crossAxisSpacing: isDesktop ? 24 : (isMobile ? 16 : 34),
            childAspectRatio: 370 / 255,
                )
              : const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisExtent: 250),
          itemBuilder: (context, index) => LibraryView(
            library: libraries[index],
            onTap: () => _onLibraryTap(libraries[index]).then((value) => context.go(Routes.listen)),
          ),
          itemCount: libraries.length,
        ),
      ],
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
