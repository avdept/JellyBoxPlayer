import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    this.label,
    this.placeholder,
    this.keyboardType,
    this.controller,
    this.obscureText = false,
    this.textInputAction,
    this.autofocus = false,
    super.key,
  });

  final String? label;
  final String? placeholder;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          _labelText(label!),
          const SizedBox(height: 4),
        ],
        _textField(),
      ],
    );
  }

  Widget _labelText(String value) => Text(
        value,
        style: const TextStyle(
          fontFamily: FontFamily.inter,
          fontSize: 12,
        ),
      );

  Widget _textField() => TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEEEEEE),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        autofocus: autofocus,
      );
}
