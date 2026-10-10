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
  bool _expanded = false;

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _onFocusChange(bool focused) {
    setState(() => _expanded = focused);
    widget.onFocusChange?.call(focused);
  }

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
        child: AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          width: _expanded
              ? TvTokens.railExpandedWidth
              : TvTokens.railCollapsedWidth,
          color: TvTokens.railBackground,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(expanded: _expanded),
              const SizedBox(height: 24),
              for (final item in widget.items)
                _RailButton(item: item, expanded: _expanded),
              const Spacer(),
              for (final item in widget.footer)
                _RailButton(item: item, expanded: _expanded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SvgPicture.asset(SvgPictures.jellyboxLogo, width: 40, height: 40),
          Expanded(
            child: ClipRect(
              child: AnimatedOpacity(
                duration: TvTokens.focusDuration,
                opacity: expanded ? 1 : 0,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'JellyBox',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.item, required this.expanded});

  final TvRailItem item;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return TvFocusable(
      onSelect: item.onSelect,
      focusNode: item.focusNode,
      scrollOnFocus: false,
      debugLabel: 'rail:${item.label}',
      builder: (context, focused) {
        final foreground = focused
            ? Colors.black
            : (item.selected ? accent : Colors.white);
        return AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: focused
                ? Colors.white
                : (item.selected ? Colors.white12 : Colors.transparent),
            borderRadius: TvTokens.cardRadius,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 22, color: foreground),
              Expanded(
                child: ClipRect(
                  child: AnimatedOpacity(
                    duration: TvTokens.focusDuration,
                    opacity: expanded ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
