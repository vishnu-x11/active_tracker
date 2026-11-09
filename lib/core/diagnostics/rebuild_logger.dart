import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class RebuildLogger extends ProviderObserver {
  RebuildLogger({this.verbose = false});

  final bool verbose;
  final Map<String, int> updates = {};

  @override
  void didUpdateProvider(ProviderObserverContext context, Object? previousValue, Object? newValue) {
    final name = context.provider.name ?? context.provider.runtimeType.toString();
    final n = (updates[name] ?? 0) + 1;
    updates[name] = n;
    if (verbose && kDebugMode) {
      developer.log('$name update #$n', name: 'rebuild');
    }
  }
}
