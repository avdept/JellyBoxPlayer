import 'package:flutter/material.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

class UpdatifyBell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: IconThemeData(size: iconSize),
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.square(tapSize),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        child: UpdatifyTrigger(
          projectId: updatifyProjectId,
          popupType: isDesktop
              ? UpdatifyPopupType.modal
              : UpdatifyPopupType.bottomSheet,
          backgroundColor: Themes.changelogSurface,
          title: changelogTitle,
          borderRadius: BorderRadius.circular(8),
          width: isDesktop
              ? MediaQuery.sizeOf(context).width / 2
              : double.infinity,
        ),
      ),
    );
  }
}
