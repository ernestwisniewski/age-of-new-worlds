import 'dart:async';

import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';

final class TestMapInputSource
    implements MapInputSource, ContinuousMapInputSource {
  final _commands = StreamController<MapInputCommand>.broadcast(sync: true);
  final _continuousInputs = StreamController<MapGamepadInput>.broadcast(
    sync: true,
  );

  @override
  Stream<MapInputCommand> get commands => _commands.stream;

  @override
  Stream<MapGamepadInput> get continuousInputs => _continuousInputs.stream;

  void add(MapInputCommand command) => _commands.add(command);

  void addContinuous(MapGamepadInput input) => _continuousInputs.add(input);

  @override
  Future<void> close() async {
    await _commands.close();
    await _continuousInputs.close();
  }
}
