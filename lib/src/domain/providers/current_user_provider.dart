import 'package:flutter_riverpod/flutter_riverpod.dart';

class User {
  User({required this.userId, required this.token});
  final String userId;
  final String token;
}

final currentUserProvider = StateProvider<User?>((ref) => null);
