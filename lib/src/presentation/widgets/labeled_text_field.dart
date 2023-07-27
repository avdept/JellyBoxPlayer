import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    required this.label,
    this.keyboardType,
    this.textInputAction,
    super.key,
  });

  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(),
        const SizedBox(height: 4),
        _textField(),
      ],
    );
  }

  Widget _labelText() => Text(
        label,
        style: const TextStyle(
          fontFamily: FontFamily.inter,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      );

  Widget _textField() => TextField(
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEEEEEE),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(21.391),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      );
}
