import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class ScrollablePageScaffold extends StatefulWidget {
  const ScrollablePageScaffold({
    this.controller,
    this.useGradientBackground = false,
    this.navigationBar,
    this.loadMoreData,
    this.contentPadding = EdgeInsets.zero,
    this.background,
    this.backgroundColor,
    this.slivers = const [],
    this.showScrollbar = true,
    this.barOpacity,
    super.key,
  });

  final ScrollController? controller;
  final bool useGradientBackground;
  final bool showScrollbar;
  final ValueListenable<double>? barOpacity;
  final Future<void> Function()? loadMoreData;
  final PreferredSizeWidget? navigationBar;
  final EdgeInsets contentPadding;
  final Widget? background;
  final Color? backgroundColor;
  final List<Widget>? slivers;

  @override
  State<ScrollablePageScaffold> createState() => _ScrollablePageScaffoldState();
}

class _ScrollablePageScaffoldState extends State<ScrollablePageScaffold> {
  late final ScrollController _effectiveScrollController;
  final _blurAppBar = ValueNotifier<bool>(false);

  bool isLoading = false;
  late MediaQueryData _mediaQuery;
  late ThemeData _theme;

  bool get _hasExternalController => widget.controller != null;

  double get _appBarHeight => switch (widget.navigationBar) {
    final PageNavigationBar bar => bar.heightIn(context),
    final bar? => bar.preferredSize.height,
    null => 0,
  };

  double get _backgroundScroll => _effectiveScrollController.hasClients
      ? max(0, _effectiveScrollController.offset).roundToDouble()
      : 0;

  void _onScroll() {
    _blurAppBar.value = _effectiveScrollController.offset > 0;
    if (_effectiveScrollController.position.maxScrollExtent -
            _effectiveScrollController.position.pixels <
        300) {
      if (widget.loadMoreData != null && !isLoading) {
        setState(() {
          isLoading = true;
        });
        widget.loadMoreData!().then((value) {
          setState(() {
            isLoading = false;
          });
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _effectiveScrollController = widget.controller ?? ScrollController();
    _effectiveScrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaQuery = MediaQuery.of(context);
    _theme = Theme.of(context);
  }

  Widget _withBackground(Widget child) =>
      widget.useGradientBackground ? GradientBackground(child: child) : child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: _withBackground(_body()),
    );
  }

  @override
  void dispose() {
    if (_hasExternalController) {
      _effectiveScrollController.removeListener(_onScroll);
    } else {
      _effectiveScrollController.dispose();
    }
    _blurAppBar.dispose();
    super.dispose();
  }

  Widget _appBar() => ClipRect(
    child: ValueListenableBuilder(
      valueListenable: _blurAppBar,
      builder: (context, blur, child) => BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur ? 8 : 0,
          sigmaY: blur ? 8 : 0,
        ),
        child: child,
      ),
      child: GradientPanelDecoration(
        child: widget.navigationBar,
      ),
    ),
  );

  Widget? _backgroundLayer() => switch (widget.background) {
    final background? => Positioned(
      left: 0,
      top: 0,
      right: 0,
      child: ListenableBuilder(
        listenable: _effectiveScrollController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -_backgroundScroll),
          child: child,
        ),
        child: background,
      ),
    ),
    null => null,
  };

  Widget _scrollLayer(double top) => SafeArea(
    child: MediaQuery(
      data: _mediaQuery.copyWith(padding: EdgeInsets.only(top: top)),
      child: CustomScrollbar(
        key: GlobalObjectKey(_effectiveScrollController),
        controller: _effectiveScrollController,
        enabled: widget.showScrollbar,
        child: CustomScrollView(
          controller: _effectiveScrollController,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: top + widget.contentPadding.top),
            ),
            ...FloatingPanels.slivers(context, [
              for (final sliver in widget.slivers!)
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: widget.contentPadding.left,
                    right: widget.contentPadding.right,
                  ),
                  sliver: sliver,
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: widget.contentPadding.bottom),
              ),
            ]),
          ],
        ),
      ),
    ),
  );

  Widget _body() {
    final navigationBar = widget.navigationBar;
    if (navigationBar != null && FloatingPanels.enabled(context)) {
      return FloatingBarFrame(
        bar: MediaQuery(
          data: _mediaQuery.copyWith(textScaler: TextScaler.noScaling),
          child: navigationBar,
        ),
        barHeight: _appBarHeight,
        controller: _effectiveScrollController,
        fade: widget.barOpacity,
        background: _backgroundLayer(),
        scrollView: _scrollLayer,
      );
    }
    return Stack(
      children: [
        ?_backgroundLayer(),
        _scrollLayer(_appBarHeight),
        if (navigationBar != null) ...[
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: _mediaQuery.padding.top,
            child: ColoredBox(color: _theme.scaffoldBackgroundColor),
          ),
          Positioned(
            left: 0,
            top: _mediaQuery.padding.top,
            right: 0,
            height: _appBarHeight,
            child: MediaQuery(
              data: _mediaQuery.copyWith(textScaler: TextScaler.noScaling),
              child: _appBar(),
            ),
          ),
        ],
      ],
    );
  }
}
