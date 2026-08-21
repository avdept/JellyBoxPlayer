import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final devToolsEnabledProvider = Provider<bool>((ref) => kDebugMode);
