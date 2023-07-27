import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late GoRouterState _router;

  static const _routes = {
    Routes.listen,
    Routes.search,
    Routes.settings,
    Routes.downloads,
  };

  int _getLocationIndex(String location) {
    for (var index = 0; index < _routes.length; index++) {
      final tabRoute = _routes.elementAt(index);
      if (location.startsWith(tabRoute)) return index;
    }

    return 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router = GoRouterState.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getLocationIndex(_router.uri.toString());

    return Scaffold(
      body: widget.child,
    );
  }
}
