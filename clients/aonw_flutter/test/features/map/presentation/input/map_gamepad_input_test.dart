import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies the original deadzone and camera sensitivity', () {
    final controller = MapGamepadFrameController(cameraSensitivity: 2);

    expect(
      controller.advance(input: const MapGamepadInput(cameraX: 0.24), dt: 0),
      _matchesFrame(cameraX: 0),
    );
    expect(
      controller.advance(
        input: const MapGamepadInput(
          cameraX: 0.62,
          cameraY: -0.62,
          zoomIn: 0.62,
        ),
        dt: 0,
      ),
      _matchesFrame(cameraX: 1, cameraY: -1, zoom: 0.5),
    );
  });

  test('repeats D-pad and left-stick cursor steps at original timings', () {
    final controller = MapGamepadFrameController();
    const held = MapGamepadInput(dpadRight: true);

    expect(
      controller.advance(input: held, dt: 0).cursorStep,
      MapInputCommand.cursorRight,
    );
    expect(controller.advance(input: held, dt: 0.27).cursorStep, isNull);
    expect(
      controller.advance(input: held, dt: 0.02).cursorStep,
      MapInputCommand.cursorRight,
    );
    expect(controller.advance(input: held, dt: 0.09).cursorStep, isNull);
    expect(
      controller.advance(input: held, dt: 0.02).cursorStep,
      MapInputCommand.cursorRight,
    );

    expect(
      controller
          .advance(input: const MapGamepadInput(cursorY: 1), dt: 0)
          .cursorStep,
      MapInputCommand.cursorUp,
    );
  });

  test('dispatches cursor before edge-triggered actions in one frame', () {
    final controller = MapGamepadFrameController();
    const pressed = MapGamepadInput(dpadLeft: true, activate: true);

    final first = controller.advance(input: pressed, dt: 0);
    expect(first.cursorStep, MapInputCommand.cursorLeft);
    expect(first.activatePressed, isTrue);

    final held = controller.advance(input: pressed, dt: 0.1);
    expect(held.activatePressed, isFalse);

    controller.advance(input: MapGamepadInput.idle, dt: 0);
    expect(
      controller
          .advance(input: const MapGamepadInput(activate: true), dt: 0)
          .activatePressed,
      isTrue,
    );
  });
}

Matcher _matchesFrame({
  double cameraX = 0,
  double cameraY = 0,
  double zoom = 0,
}) => isA<MapGamepadFrame>()
    .having((frame) => frame.cameraX, 'cameraX', closeTo(cameraX, 1e-9))
    .having((frame) => frame.cameraY, 'cameraY', closeTo(cameraY, 1e-9))
    .having((frame) => frame.zoom, 'zoom', closeTo(zoom, 1e-9));
