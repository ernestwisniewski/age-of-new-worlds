part of 'gamepad_map_input_source_test.dart';

void bindingInputTests() {
  test('a signed stick assigned to zoom retains both directions', () async {
    final h = _BindingHarness();
    addTearDown(h.close);
    h.source.configureGamepad(
      ClientGamepadSettings(
        bindings: GamepadBindings.defaults.bindAxis(
          GamepadAxisAction.zoomIn,
          GamepadAxisControl.leftStickX,
        ),
      ),
    );
    h.events.add(_axis(GamepadAxis.leftStickX, -0.7));
    expect(h.last.zoom, -0.7);
    h.events.add(_axis(GamepadAxis.leftStickX, 0.7));
    expect(h.last.zoom, 0.7);
    h.events.add(_axis(GamepadAxis.leftStickX, 0));
    expect(h.last, MapGamepadInput.idle);
  });

  test('remaps physical buttons and axes to action fields', () async {
    final h = _BindingHarness();
    addTearDown(h.close);
    h.source.configureGamepad(
      ClientGamepadSettings(
        bindings: GamepadBindings.defaults
            .bindButton(
              GamepadButtonAction.primaryAction,
              GamepadButtonControl.a,
            )
            .bindAxis(GamepadAxisAction.cameraY, GamepadAxisControl.leftStickX),
      ),
    );
    h.events.add(_button(GamepadButton.a, 1));
    expect(h.last.primaryAction, isTrue);
    expect(h.last.activate, isFalse);
    h.events.add(_button(GamepadButton.a, 0));
    h.events.add(_button(GamepadButton.start, 1));
    expect(h.last, MapGamepadInput.idle);
    h.events.add(_axis(GamepadAxis.leftStickX, -0.8));
    expect(h.last.cameraY, -0.8);
    expect(h.last.cursorX, 0);
    h.events.add(_axis(GamepadAxis.rightStickY, 0.9));
    expect(h.last.cameraY, -0.8);
  });

  test('releasing one cancel alias does not release the other', () async {
    final h = _BindingHarness();
    addTearDown(h.close);
    h.events.add(_button(GamepadButton.b, 1));
    h.events.add(_button(GamepadButton.back, 1));
    h.events.add(_button(GamepadButton.b, 0));
    expect(h.last.cancel, isTrue);
    h.events.add(_button(GamepadButton.back, 0));
    expect(h.last, MapGamepadInput.idle);
  });

  test('analog and digital trigger contributions remain independent', () async {
    final h = _BindingHarness();
    addTearDown(h.close);
    h.events.add(_axis(GamepadAxis.rightTrigger, 0.8));
    h.events.add(_button(GamepadButton.rightTrigger, 1));
    expect(h.last.zoomIn, 1);
    h.events.add(_button(GamepadButton.rightTrigger, 0));
    expect(h.last.zoomIn, 0.8);
    h.events.add(_button(GamepadButton.rightTrigger, 1));
    h.events.add(_axis(GamepadAxis.rightTrigger, 0));
    expect(h.last.zoomIn, 1);
    h.events.add(_button(GamepadButton.rightTrigger, 0));
    expect(h.last.zoomIn, 0);
  });

  test(
    'rebinding a held button requires release before the new action',
    () async {
      final h = _BindingHarness();
      addTearDown(h.close);
      h.events.add(_button(GamepadButton.a, 1));
      expect(h.last.activate, isTrue);
      h.source.configureGamepad(
        ClientGamepadSettings(
          bindings: GamepadBindings.defaults.bindButton(
            GamepadButtonAction.primaryAction,
            GamepadButtonControl.a,
          ),
        ),
      );
      expect(h.last, MapGamepadInput.idle);
      h.events.add(_button(GamepadButton.a, 1));
      h.events.add(_button(GamepadButton.y, 1));
      expect(h.last.primaryAction, isFalse);
      expect(h.last.inspectHex, isTrue);
      h.events.add(_button(GamepadButton.a, 0));
      h.events.add(_button(GamepadButton.a, 1));
      expect(h.last.primaryAction, isTrue);
      expect(h.last.activate, isFalse);
    },
  );

  test(
    'rebinding a deflected axis waits for the configured neutral zone',
    () async {
      final h = _BindingHarness();
      addTearDown(h.close);
      h.events.add(_axis(GamepadAxis.leftStickX, 0.7));
      h.source.configureGamepad(
        ClientGamepadSettings(
          deadzone: 0.4,
          bindings: GamepadBindings.defaults.bindAxis(
            GamepadAxisAction.cameraX,
            GamepadAxisControl.leftStickX,
          ),
        ),
      );
      expect(h.last, MapGamepadInput.idle);
      h.events.add(_axis(GamepadAxis.leftStickX, 0.8));
      expect(h.last, MapGamepadInput.idle);
      h.events.add(_axis(GamepadAxis.leftStickX, 0.3));
      h.events.add(_axis(GamepadAxis.leftStickX, 0.8));
      expect(h.last.cameraX, 0.8);
      expect(h.last.cursorX, 0);
    },
  );

  test(
    'all normalized controls can be assigned and non-finite events are ignored',
    () async {
      final h = _BindingHarness();
      addTearDown(h.close);
      expect(
        GamepadButton.values.map((v) => v.name),
        GamepadButtonControl.values.map((v) => v.name),
      );
      expect(
        GamepadAxis.values.map((v) => v.name),
        GamepadAxisControl.values.map((v) => v.name),
      );
      for (final control in GamepadButton.values) {
        h.source.configureGamepad(
          ClientGamepadSettings(
            bindings: GamepadBindings.defaults.bindButton(
              GamepadButtonAction.confirm,
              GamepadButtonControl.values.byName(control.name),
            ),
          ),
        );
        h.events.add(_button(control, 1));
        expect(h.last.activate, isTrue, reason: control.name);
        h.events.add(_button(control, 0));
      }
      h.events.add(_axis(GamepadAxis.leftStickX, double.nan));
      h.events.add(_button(GamepadButton.a, double.infinity));
      expect(h.last, MapGamepadInput.idle);
    },
  );
}

final class _BindingHarness {
  _BindingHarness() {
    source = GamepadMapInputSource(events: events.stream);
    subscription = source.continuousInputs.listen((value) => last = value);
  }
  final events = StreamController<NormalizedGamepadEvent>(sync: true);
  late final GamepadMapInputSource source;
  late final StreamSubscription<MapGamepadInput> subscription;
  MapGamepadInput last = MapGamepadInput.idle;

  Future<void> close() async {
    await subscription.cancel();
    await source.close();
    await events.close();
  }
}
