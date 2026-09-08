import 'package:aonw_flutter/design_system/aonw_text_scaler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves nonlinear system scaling for every font size', () {
    const system = _NonlinearTextScaler();
    const scaler = AonwTextScaler(system: system, factor: 1.3);
    for (final size in [12.0, 16.0, 24.0, 48.0]) {
      expect(scaler.scale(size), closeTo(system.scale(size) * 1.3, 1e-10));
    }
    expect(scaler.scale(12) / 12, isNot(scaler.scale(48) / 48));
    expect(scaler, const AonwTextScaler(system: system, factor: 1.3));
    expect(scaler, isNot(const AonwTextScaler(system: system, factor: 1.15)));
  });

  test('standard size retains system scaling without a ceiling', () {
    const system = TextScaler.linear(2.5);
    const scaler = AonwTextScaler(system: system, factor: 1);
    expect(scaler.scale(16), 40);
    expect(
      scaler.hashCode,
      const AonwTextScaler(system: system, factor: 1).hashCode,
    );
  });
}

final class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();

  @override
  double scale(double fontSize) => fontSize + 8;

  @override
  double get textScaleFactor => scale(14) / 14;
}
