import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';

class TvTextField extends StatefulWidget {
  const TvTextField({
    required this.controller,
    this.label,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.onSubmitted,
    this.suffix,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  State<TvTextField> createState() => _TvTextFieldState();
}

class _TvTextFieldState extends State<TvTextField> {
  FocusNode? _ownInner;
  late FocusNode _inner;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(TvTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _inner.removeListener(_onInnerFocus);
      _attach();
    }
  }

  void _attach() {
    _inner = widget.focusNode ?? (_ownInner ??= FocusNode());
    _inner.skipTraversal = true;
    _inner.addListener(_onInnerFocus);
  }

  void _onInnerFocus() => setState(() {});

  @override
  void dispose() {
    _inner.removeListener(_onInnerFocus);
    _ownInner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = _inner.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 6),
        ],
        TvFocusable(
          autofocus: widget.autofocus,
          scrollOnFocus: false,
          onSelect: _inner.requestFocus,
          debugLabel: 'field:${widget.label}',
          builder: (context, focused) {
            final active = focused || editing;
            return AnimatedContainer(
              duration: TvTokens.focusDuration,
              curve: TvTokens.focusCurve,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: active ? 0.16 : 0.08),
                borderRadius: TvTokens.cardRadius,
                border: Border.all(
                  color: editing
                      ? Theme.of(context).colorScheme.primary
                      : (focused ? TvTokens.focusRing : Colors.transparent),
                  width: 2,
                ),
                boxShadow: active ? TvTokens.glow(alpha: 0.2) : const [],
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _inner,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onSubmitted: widget.onSubmitted,
                autocorrect: false,
                enableSuggestions: false,
                cursorColor: Colors.white,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  suffixIcon: widget.suffix,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
