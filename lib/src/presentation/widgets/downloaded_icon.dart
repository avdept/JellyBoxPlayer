import 'package:flutter/material.dart';
import 'package:jplayer/resources/j_player_icons.dart';

class DownloadedIcon extends StatelessWidget {
  const DownloadedIcon({this.size = 24, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.green,
      shape: BoxShape.circle,
    ),
    child: Icon(JPlayer.download, color: Colors.white, size: size * 0.55),
  );
}
