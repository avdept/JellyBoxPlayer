import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';

class TvCollectionScaffold extends ConsumerStatefulWidget {
  const TvCollectionScaffold({
    required this.cover,
    required this.title,
    required this.actions,
    required this.body,
    this.subtitle,
    this.details,
    this.circularCover = false,
    super.key,
  });

  final Widget cover;
  final String title;
  final String? subtitle;
  final Widget? details;
  final List<Widget> actions;
  final Widget body;
  final bool circularCover;

  static const panelWidth = 272.0;
  static const coverSize = 240.0;
  static const gap = 36.0;

  @override
  ConsumerState<TvCollectionScaffold> createState() =>
      _TvCollectionScaffoldState();
}

class _TvCollectionScaffoldState extends ConsumerState<TvCollectionScaffold> {
  final _bodyNode = FocusNode(
    debugLabel: 'collection-body',
    skipTraversal: true,
  );
  final _panelNode = FocusNode(
    debugLabel: 'collection-panel',
    skipTraversal: true,
  );
  late final _policy = _CollectionTraversalPolicy(
    leavesPage: _leavesPage,
    requestFocusCallback: _requestFocus,
  );
  FocusNode? _lastBodyFocus;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_trackBodyFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_trackBodyFocus);
    _bodyNode.dispose();
    _panelNode.dispose();
    super.dispose();
  }

  bool _leavesPage(FocusNode node, TraversalDirection direction) =>
      direction == TraversalDirection.down &&
      node.ancestors.contains(_panelNode) &&
      ref.read(settingProvider(AppSetting.tvMiniPlayer));

  bool _inBody(FocusNode? node) =>
      node != null && node.ancestors.contains(_bodyNode);

  void _trackBodyFocus() {
    final focus = FocusManager.instance.primaryFocus;
    if (_inBody(focus)) _lastBodyFocus = focus;
  }

  void _requestFocus(
    FocusNode node, {
    ScrollPositionAlignmentPolicy? alignmentPolicy,
    double? alignment,
    Duration? duration,
    Curve? curve,
  }) {
    final enteringBody =
        _inBody(node) && !_inBody(FocusManager.instance.primaryFocus);
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
      enteringBody ? _bodyEntry() ?? node : node,
      alignmentPolicy: alignmentPolicy,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }

  FocusNode? _bodyEntry() {
    final last = _lastBodyFocus;
    if (last != null &&
        last.context != null &&
        last.canRequestFocus &&
        _inBody(last)) {
      return last;
    }
    final nodes = _bodyNode.traversalDescendants;
    if (nodes.isEmpty) return null;
    return nodes.reduce((a, b) => a.rect.top <= b.rect.top ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvTokens.pageBackground,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          TvTokens.pagePaddingH,
          TvTokens.pagePaddingV,
          0,
          0,
        ),
        child: FocusTraversalGroup(
          policy: _policy,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: TvCollectionScaffold.panelWidth,
                child: Focus(
                  focusNode: _panelNode,
                  child: _panel(),
                ),
              ),
              const SizedBox(width: TvCollectionScaffold.gap),
              Expanded(
                child: Focus(
                  focusNode: _bodyNode,
                  child: ClipRect(
                    clipper: const _BodyClipper(),
                    child: widget.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel() {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(bottom: TvTokens.pagePaddingV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: widget.circularCover
                ? BorderRadius.circular(TvCollectionScaffold.coverSize)
                : TvTokens.panelRadius,
            child: SizedBox.square(
              dimension: TvCollectionScaffold.coverSize,
              child: widget.cover,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (widget.subtitle case final subtitle?
              when subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ],
          if (widget.details case final details?) ...[
            const SizedBox(height: 10),
            details,
          ],
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: widget.actions),
        ],
      ),
    );
  }
}

class _CollectionTraversalPolicy extends ReadingOrderTraversalPolicy {
  _CollectionTraversalPolicy({
    required this.leavesPage,
    super.requestFocusCallback,
  });

  final bool Function(FocusNode node, TraversalDirection direction) leavesPage;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    if (leavesPage(currentNode, direction)) return false;
    return super.inDirection(currentNode, direction);
  }
}

class _BodyClipper extends CustomClipper<Rect> {
  const _BodyClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-TvCollectionScaffold.gap, 0, size.width, size.height);

  @override
  bool shouldReclip(_BodyClipper oldClipper) => false;
}
