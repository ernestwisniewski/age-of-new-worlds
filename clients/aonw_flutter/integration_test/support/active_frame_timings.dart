import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Measures consecutive live frames without the timeline helper's idle flush.
/// Engine timestamps exclude batched warmup timings, including late delivery.
Future<Map<String, dynamic>> measureActiveFrameTimings(
  WidgetTester tester, {
  required int warmupFrames,
  required int timedFrames,
}) async {
  final binding = tester.binding;
  final timings = <FrameTiming>[];
  void collect(List<FrameTiming> batch) => timings.addAll(batch);
  binding.addTimingsCallback(collect);
  try {
    for (var frame = 0; frame < warmupFrames; frame++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    final start = binding.currentSystemFrameTimeStamp.inMicroseconds;
    for (var frame = 0; frame < timedFrames; frame++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    final end = binding.currentSystemFrameTimeStamp.inMicroseconds;
    for (var attempt = 0; attempt < 40; attempt++) {
      if (timings.isNotEmpty && _vsync(timings.last) >= end) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final measured = timings
        .where((frame) => _vsync(frame) > start && _vsync(frame) <= end)
        .toList();
    expect(measured.length, greaterThanOrEqualTo(timedFrames));
    return FrameTimingSummarizer(measured).summary;
  } finally {
    binding.removeTimingsCallback(collect);
  }
}

int _vsync(FrameTiming timing) =>
    timing.timestampInMicroseconds(FramePhase.vsyncStart);
