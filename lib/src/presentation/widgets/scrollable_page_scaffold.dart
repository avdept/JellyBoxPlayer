import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class ScrollablePageScaffold extends StatefulWidget {
  const ScrollablePageScaffold({
    this.controller,
    this.useGradientBackground = false,
    this.navigationBar,
    this.loadMoreData,
    this.contentPadding = EdgeInsets.zero,
    this.slivers = const [],
    super.key,
  });

  final ScrollController? controller;
  final bool useGradientBackground;
  final Future<void> Function()? loadMoreData;
  final PreferredSizeWidget? navigationBar;
  final EdgeInsets contentPadding;
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

  double get _appBarHeight => widget.navigationBar?.preferredSize.height ?? 0;

  void _onScroll() {
    _blurAppBar.value = _effectiveScrollController.offset > 0;
    if (_effectiveScrollController.position.maxScrollExtent - _effectiveScrollController.position.pixels < 300) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.useGradientBackground ? GradientBackground(child: _body()) : _body(),
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

  Widget _body() => Stack(
        children: [
          SafeArea(
            child: MediaQuery(
              data: _mediaQuery.copyWith(
                padding: EdgeInsets.only(top: _appBarHeight),
              ),
              child: CustomScrollbar(
                controller: _effectiveScrollController,
                child: CustomScrollView(
                  controller: _effectiveScrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: _appBarHeight + widget.contentPadding.top,
                      ),
                    ),
                    for (final sliver in widget.slivers!)
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left: widget.contentPadding.left,
                          right: widget.contentPadding.right,
                        ),
                        sliver: sliver,
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: widget.contentPadding.bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.navigationBar != null) ...[
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
                data: _mediaQuery.copyWith(textScaleFactor: 1),
                child: _appBar(),
              ),
            ),
          ],
        ],
      );
}
