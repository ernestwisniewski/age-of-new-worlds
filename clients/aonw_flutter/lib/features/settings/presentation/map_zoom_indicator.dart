import 'dart:async';

import 'package:flutter/foundation.dart';

final class MapZoomIndicator extends ChangeNotifier
    implements ValueListenable<double?> {
  Object? _owner;
  ValueListenable<double?>? _source;
  double? _value;
  var _queued = false;
  var _disposed = false;

  @override
  double? get value => _value;

  void attach(Object owner, ValueListenable<double?> source) {
    if (_disposed || (identical(owner, _owner) && identical(source, _source))) {
      return;
    }
    _source?.removeListener(_observe);
    _owner = owner;
    _source = source;
    source.addListener(_observe);
    _observe();
  }

  void detach(Object owner) {
    if (_disposed || !identical(owner, _owner)) return;
    _source?.removeListener(_observe);
    _source = null;
    _owner = null;
    _observe();
  }

  void _observe() {
    final next = _source?.value;
    if (_value == next) return;
    _value = next;
    if (_queued) return;
    _queued = true;
    scheduleMicrotask(() {
      _queued = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _source?.removeListener(_observe);
    _source = null;
    super.dispose();
  }
}
