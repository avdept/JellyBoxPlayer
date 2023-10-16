import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    required this.label,
    required this.keyboardType,
    this.controller,
    this.textInputAction,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
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
        ),
      );

  Widget _textField() => TextField(
        controller: controller,
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
