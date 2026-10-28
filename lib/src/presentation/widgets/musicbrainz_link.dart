import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/providers/musicbrainz_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicBrainzLink extends ConsumerWidget {
  const MusicBrainzLink({required this.barcode, this.artistName, super.key});

  static const _brandColor = Color(0xFFBA478F);

  final String? barcode;
  final String? artistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barcode = this.barcode;
    if (barcode == null || barcode.isEmpty) return const SizedBox.shrink();
    final match = ref.watch(
      musicBrainzBarcodeMatchProvider((
        barcode: barcode,
        artistName: artistName,
      )),
    );
    final color = Theme.of(
      context,
    ).colorScheme.onPrimary.withValues(alpha: 0.6);
    final style = TextStyle(fontSize: 12, color: color);

    final url = match.valueOrNull?.releaseGroupId;
    if (url == null && !match.isLoading) return const SizedBox.shrink();
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _badge(),
        const SizedBox(width: 6),
        if (url == null) ...[
          Text('Looking up on MusicBrainz', style: style),
          const SizedBox(width: 6),
          SizedBox.square(
            dimension: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
          ),
        ] else ...[
          Text('View on MusicBrainz', style: style),
          const SizedBox(width: 4),
          Icon(Icons.open_in_new, size: 12, color: color),
        ],
      ],
    );
    if (url == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => unawaited(
        launchUrl(
          Uri.parse('https://musicbrainz.org/release-group/$url'),
          mode: LaunchMode.externalApplication,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: row,
      ),
    );
  }

  Widget _badge() => Container(
    width: 18,
    height: 18,
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(
      color: _brandColor,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 6)],
    ),
    child: SvgPicture.asset(
      SvgPictures.musicBrainzLogo,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
  );
}
