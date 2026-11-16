import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';

class DesktopDialog extends StatelessWidget {
  const DesktopDialog({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              HoverIconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                iconSize: 24,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(),
          SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
