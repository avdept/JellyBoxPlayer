import 'package:flutter/material.dart';

TextSpan boldNameSpan(String message, String name) {
  var target = '"$name"';
  var start = message.indexOf(target);
  if (start < 0) {
    target = name;
    start = message.indexOf(target);
  }
  if (start < 0) return TextSpan(text: message);
  return TextSpan(
    text: message.substring(0, start),
    children: [
      TextSpan(
        text: target,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(text: message.substring(start + target.length)),
    ],
  );
}
