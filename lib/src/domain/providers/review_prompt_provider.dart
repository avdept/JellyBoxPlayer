import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewPromptPolicy {
  const ReviewPromptPolicy({
    this.minCompletedTracks = 25,
    this.minAge = const Duration(days: 3),
    this.cooldown = const Duration(days: 120),
  });

  final int minCompletedTracks;
  final Duration minAge;
  final Duration cooldown;
}

bool storeReviewSupported() =>
    Platform.isIOS ||
    Platform.isAndroid ||
    (Platform.isMacOS && !kDirectDownloadBuild);

class ReviewPromptNotifier extends StateNotifier<bool> {
  ReviewPromptNotifier(
    this._prefs, {
    this.policy = const ReviewPromptPolicy(),
    bool? supported,
    DateTime Function()? now,
  }) : _supported = supported ?? storeReviewSupported(),
       _now = now ?? DateTime.now,
       super(false) {
    final prefs = _prefs;
    if (prefs != null && !prefs.containsKey(_firstSeenKey)) {
      unawaited(prefs.setInt(_firstSeenKey, _now().millisecondsSinceEpoch));
    }
  }

  static const _completedKey = 'review_completed_tracks';
  static const _firstSeenKey = 'review_first_seen_ms';
  static const _promptedKey = 'review_last_prompt_ms';

  final SharedPreferences? _prefs;
  final ReviewPromptPolicy policy;
  final bool _supported;
  final DateTime Function() _now;

  void recordTrackCompleted() {
    final prefs = _prefs;
    if (prefs == null || !_supported || state) return;
    final count = (prefs.getInt(_completedKey) ?? 0) + 1;
    unawaited(prefs.setInt(_completedKey, count));
    if (_isDue(prefs, count)) state = true;
  }

  Future<void> markPrompted() async {
    state = false;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setInt(_promptedKey, _now().millisecondsSinceEpoch);
    await prefs.setInt(_completedKey, 0);
  }

  bool _isDue(SharedPreferences prefs, int count) {
    if (count < policy.minCompletedTracks) return false;
    final now = _now();
    final firstSeen = _readTime(prefs, _firstSeenKey);
    if (firstSeen == null || now.difference(firstSeen) < policy.minAge) {
      return false;
    }
    final prompted = _readTime(prefs, _promptedKey);
    if (prompted != null && now.difference(prompted) < policy.cooldown) {
      return false;
    }
    return true;
  }

  DateTime? _readTime(SharedPreferences prefs, String key) {
    final ms = prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}

final reviewPromptProvider = StateNotifierProvider<ReviewPromptNotifier, bool>(
  (ref) => ReviewPromptNotifier(
    ref.watch(sharedPreferencesProvider).valueOrNull,
  ),
);
