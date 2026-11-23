import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';

class TvRailItem {
  const TvRailItem({
    required this.icon,
    required this.label,
    required this.onSelect,
    this.selected = false,
    this.focusNode,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final bool selected;
  final FocusNode? focusNode;
}

class TvNavigationRail extends StatefulWidget {
  const TvNavigationRail({
    required this.items,
    this.footer = const [],
    this.onFocusChange,
    this.onExit,
    super.key,
  });

  final List<TvRailItem> items;
  final List<TvRailItem> footer;
  final ValueChanged<bool>? onFocusChange;

  final void Function(TraversalDirection direction)? onExit;

  @override
  State<TvNavigationRail> createState() => _TvNavigationRailState();
}

class _TvNavigationRailState extends State<TvNavigationRail> {
  final _scope = FocusScopeNode(debugLabel: 'tv-rail');

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _onFocusChange(bool focused) => widget.onFocusChange?.call(focused);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onExit == null || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    if (direction != TraversalDirection.right) {
      final focus = FocusManager.instance.primaryFocus;
      if (focus != null && focus.focusInDirection(direction)) {
        return KeyEventResult.handled;
      }
    }
    widget.onExit!(direction);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _scope,
      onFocusChange: _onFocusChange,
      onKeyEvent: _onKey,
      child: FocusTraversalGroup(
        child: Container(
          width: TvTokens.railWidth,
          color: Theme.of(context).navigationRailTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Logo(),
              const SizedBox(height: 24),
              for (final item in widget.items) _RailButton(item: item),
              const Spacer(),
              for (final item in widget.footer) _RailButton(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(SvgPictures.jellyboxLogo, width: 40, height: 40),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.item});

  final TvRailItem item;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: item.label,
      button: true,
      child: TvFocusable(
        onSelect: item.onSelect,
        focusNode: item.focusNode,
        scrollOnFocus: false,
        debugLabel: 'rail:${item.label}',
        builder: (context, focused) => AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          height: 48,
          color: focused
              ? Colors.white
              : (item.selected
                    ? TvTokens.railSelected(context)
                    : Colors.transparent),
          child: Center(
            child: Icon(
              item.icon,
              size: 22,
              color: focused
                  ? Colors.black
                  : (item.selected ? accent : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
