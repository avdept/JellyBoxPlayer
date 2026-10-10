import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/pages/album/mobile/blurred_cover_art.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';

class TvCollectionScaffold extends StatelessWidget {
  const TvCollectionScaffold({
    required this.backdrop,
    required this.cover,
    required this.title,
    required this.actions,
    required this.body,
    this.subtitle,
    this.details,
    super.key,
  });

  final ImageProvider backdrop;
  final Widget cover;
  final String title;
  final String? subtitle;
  final Widget? details;
  final List<Widget> actions;
  final Widget body;

  static const panelWidth = 272.0;
  static const coverSize = 240.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            BlurredCoverArt(
              image: backdrop,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              background: Colors.black,
              blurStart: 0,
              sigma: 70,
            ),
            const ColoredBox(color: Color(0xA6000000)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TvTokens.pagePaddingH,
                TvTokens.pagePaddingV,
                0,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: panelWidth, child: _panel()),
                  const SizedBox(width: 36),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: TvTokens.pagePaddingV),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: TvTokens.panelRadius,
            child: SizedBox.square(dimension: coverSize, child: cover),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ],
          if (details != null) ...[const SizedBox(height: 10), details!],
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ),
    );
  }
}
