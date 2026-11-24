import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';
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
    this.focusNode,
    this.suffixIcon,
    super.key,
  });

  final String? label;
  final String? placeholder;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final FocusNode? focusNode;
  final Widget? suffixIcon;

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
        _textField(context),
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

  Widget _textField(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    obscureText: obscureText,
    style: const TextStyle(color: AppColors.onFieldFill),
    decoration: InputDecoration(
      filled: true,
      fillColor: AppColors.from(context).field,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(10),
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: (suffixIcon != null)
          ? const BoxConstraints(minWidth: 44)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      hintText: placeholder,
      hintStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.onFieldHint,
      ),
    ),
    autofocus: autofocus,
  );
}
