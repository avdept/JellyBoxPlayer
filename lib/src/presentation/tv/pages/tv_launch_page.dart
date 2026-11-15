import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';

class TvLaunchPage extends StatelessWidget {
  const TvLaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvTokens.pageBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(SvgPictures.jellyboxLogo, width: 96, height: 96),
            const SizedBox(height: 20),
            const Text(
              'JellyBox',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
