import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CatalogSourceBadge extends ConsumerWidget {
  const CatalogSourceBadge({
    required this.source,
    required this.size,
    super.key,
  });

  final String source;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(catalogBrandProvider(source));
    if (brand == null) return const SizedBox.shrink();
    return Tooltip(
      message: 'From ${brand.name}',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.22),
        decoration: BoxDecoration(
          color: Color(brand.color),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 6),
          ],
        ),
        child: SvgPicture.string(
          brand.logoSvg,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class CatalogAttribution extends ConsumerWidget {
  const CatalogAttribution({required this.source, this.url, super.key});

  final String source;
  final Uri? url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(catalogBrandProvider(source));
    if (brand == null) return const SizedBox.shrink();
    final url = this.url;
    final color = Theme.of(
      context,
    ).colorScheme.onPrimary.withValues(alpha: 0.6);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CatalogSourceBadge(source: source, size: 18),
        const SizedBox(width: 6),
        Text(
          url == null ? 'From ${brand.name}' : 'View on ${brand.name}',
          style: TextStyle(fontSize: 12, color: color),
        ),
        if (url != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.open_in_new, size: 12, color: color),
        ],
      ],
    );
    if (url == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          unawaited(launchUrl(url, mode: LaunchMode.externalApplication)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: row,
      ),
    );
  }
}
