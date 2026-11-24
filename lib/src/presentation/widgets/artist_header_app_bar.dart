import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';
import 'package:jplayer/src/presentation/widgets/floating_panels.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';
import 'package:jplayer/src/presentation/widgets/scroll_title_fade.dart';

({PreferredSizeWidget? navigationBar, Widget? sliver}) artistHeaderBars(
  BuildContext context, {
  required ScrollController controller,
  required ValueListenable<double> fade,
  required String name,
  required ImageProvider image,
  Color? barColor,
  Widget? trailing,
}) => FloatingPanels.enabled(context)
    ? (
        navigationBar: ArtistFloatingBar(
          fade: fade,
          name: name,
          titleImage: image,
          trailing: trailing,
        ),
        sliver: null,
      )
    : (
        navigationBar: null,
        sliver: ArtistHeaderAppBar(
          controller: controller,
          fade: fade,
          name: name,
          titleImage: image,
          barColor: barColor,
          trailing: trailing,
        ),
      );

class ArtistHeaderAppBar extends StatelessWidget {
  const ArtistHeaderAppBar({
    required this.controller,
    required this.fade,
    required this.name,
    required this.titleImage,
    this.barColor,
    this.trailing,
    super.key,
  });

  final ScrollController controller;
  final ValueListenable<double> fade;
  final String name;
  final ImageProvider titleImage;
  final Color? barColor;
  final Widget? trailing;

  static double heightOf(BuildContext context) =>
      kToolbarHeight +
      (FloatingPanels.enabled(context) ? FloatingPanels.margin : 0);

  double get _barOpacity => controller.hasClients
      ? (controller.offset / ScrollFadingPanel.fadeDistance).clamp(0.0, 1.0)
      : 0;

  Widget _hardBar(ThemeData theme) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ClipRect(
      child: BackdropFilter(
        enabled: _barOpacity > 0,
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ColoredBox(
          color: (barColor ?? theme.scaffoldBackgroundColor).withValues(
            alpha: 0.9 * _barOpacity,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      centerTitle: true,
      title: FadingNavTitle(
        opacity: fade,
        child: _ArtistTitle(name: name, image: titleImage),
      ),
      leading: _canPop(context) ? const Center(child: _BackCircle()) : null,
      actions: [
        if (trailing case final trailing?)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: FadingNavAction(fade: fade, child: trailing),
            ),
          ),
      ],
      automaticallyImplyLeading: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      flexibleSpace: _hardBar(theme),
    );
  }
}

bool _canPop(BuildContext context) =>
    ModalRoute.of(context)?.impliesAppBarDismissal ?? false;

class ArtistFloatingBar extends StatelessWidget implements PreferredSizeWidget {
  const ArtistFloatingBar({
    required this.fade,
    required this.name,
    required this.titleImage,
    this.trailing,
    super.key,
  });

  final ValueListenable<double> fade;
  final String name;
  final ImageProvider titleImage;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: _canPop(context) ? const _BackCircle() : null,
        ),
        Expanded(
          child: Center(
            child: FadingNavTitle(
              opacity: fade,
              child: _ArtistTitle(name: name, image: titleImage),
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: switch (trailing) {
            final trailing? => FadingNavAction(fade: fade, child: trailing),
            null => null,
          },
        ),
      ],
    ),
  );
}

class _ArtistTitle extends StatelessWidget {
  const _ArtistTitle({required this.name, required this.image});

  final String name;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipOval(
        child: Image(image: image, width: 32, height: 32, fit: BoxFit.cover),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    ],
  );
}

class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.from(context);
    return HoverIconButton(
      icon: const BackButtonIcon(),
      onPressed: () => Navigator.maybePop(context),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      color: colors.onPrimaryFill,
      hoverColor: colors.onPrimaryFill,
      style: IconButton.styleFrom(
        backgroundColor: colors.primary,
        fixedSize: const Size.square(36),
        minimumSize: const Size.square(36),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
      ),
    );
  }
}

class ArtistHeaderBody extends StatelessWidget {
  const ArtistHeaderBody({
    required this.image,
    required this.panel,
    required this.headerHeight,
    required this.horizontalPadding,
    required this.isMobile,
    super.key,
  });

  static const avatarSize = 120.0;
  static const avatarTop = 32.0;

  final Widget image;
  final Widget panel;
  final double headerHeight;
  final double horizontalPadding;
  final bool isMobile;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: SizedBox(
      height: headerHeight - ArtistHeaderAppBar.heightOf(context),
      child: isMobile ? _mobile() : _desktop(),
    ),
  );

  Widget _mobile() => Padding(
    padding: const EdgeInsets.only(left: 20, top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: AspectRatio(aspectRatio: 1, child: image)),
        Flexible(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: panel,
          ),
        ),
      ],
    ),
  );

  Widget _desktop() => Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: avatarTop),
        SizedBox.square(dimension: avatarSize, child: image),
        const Spacer(),
        panel,
        const SizedBox(height: 8),
      ],
    ),
  );
}
