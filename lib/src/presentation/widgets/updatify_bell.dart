import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/widgets/hover_zoom.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

class UpdatifyBell extends ConsumerWidget {
  const UpdatifyBell({
    required this.isDesktop,
    this.iconSize = 28,
    this.tapSize = 40,
    super.key,
  });

  final bool isDesktop;
  final double iconSize;
  final double tapSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    return HoverZoom(
      builder: (context, hovered) => IconTheme.merge(
        data: IconThemeData(size: iconSize),
        child: IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.square(tapSize),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: hovered ? accent : null,
              overlayColor: Colors.transparent,
            ),
          ),
          child: UpdatifyTrigger(
            projectId: updatifyProjectId,
            popupType: isDesktop
                ? UpdatifyPopupType.modal
                : UpdatifyPopupType.bottomSheet,
            backgroundColor: Themes.changelogSurface,
            title: S.of(context).whatsNew,
            borderRadius: BorderRadius.circular(8),
            width: isDesktop
                ? MediaQuery.sizeOf(context).width / 2
                : double.infinity,
          ),
        ),
      ),
    );
  }
}
