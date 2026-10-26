import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/presentation/utils/server_logo.dart';

class ServerApiSelector extends StatelessWidget {
  const ServerApiSelector({
    required this.choices,
    required this.selectedUrl,
    required this.onSelect,
    super.key,
  });

  static String get label => S.current.serverSpeaksMultipleApis;
  static String get experimentalLabel => S.current.experimental;

  final List<ServerIdentity> choices;
  final String? selectedUrl;
  final ValueChanged<ServerIdentity> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontFamily: FontFamily.inter,
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
      const SizedBox(height: 6),
      Row(
        spacing: 8,
        children: [
          for (final (index, choice) in choices.indexed)
            Expanded(child: _choice(context, choice, experimental: index > 0)),
        ],
      ),
    ],
  );

  Widget _choice(
    BuildContext context,
    ServerIdentity choice, {
    required bool experimental,
  }) {
    final selected = choice.serverUrl == selectedUrl;
    return Material(
      color: selected ? ServerApiSelector._fill : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: selected ? null : () => onSelect(choice),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.white38,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  serverLogoAsset(
                    choice.serverType,
                    productName: choice.productName,
                  ),
                  height: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).apiWithName(choice.serverType.label),
                  style: TextStyle(
                    fontFamily: FontFamily.inter,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.black87 : Colors.white,
                  ),
                ),
                if (experimental) ...[
                  const SizedBox(width: 6),
                  Text(
                    experimentalLabel,
                    style: TextStyle(
                      fontFamily: FontFamily.inter,
                      fontSize: 11,
                      color: selected ? Colors.black54 : Colors.white60,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _fill = Color(0xFFEEEEEE);
}
