import 'package:flutter/material.dart';

class AudioQualityBadge extends StatelessWidget {
  const AudioQualityBadge({
    this.codec,
    this.bitRate,
    this.sampleRate,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 10,
    super.key,
  });

  final String? codec;
  final int? bitRate;
  final int? sampleRate;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bitrateLabel =
        bitRate != null ? '${(bitRate! / 1000).round()}kbps' : null;
    final freqLabel = sampleRate != null
        ? '${(sampleRate! / 1000.0).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}kHz'
        : null;

    final qualityParts = [
      if (bitrateLabel != null) bitrateLabel,
      if (freqLabel != null) freqLabel,
    ].join('/');

    final label = [
      if (codec != null) codec!.toUpperCase(),
      if (qualityParts.isNotEmpty) qualityParts,
    ].join(' ');

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}
