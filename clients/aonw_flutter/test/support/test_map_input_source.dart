import 'dart:async';

import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';

final class TestMapInputSource implements MapInputSource {
  final _commands = StreamController<MapInputCommand>.broadcast(sync: true);

  @override
  Stream<MapInputCommand> get commands => _commands.stream;

  void add(MapInputCommand command) => _commands.add(command);

  @override
  Future<void> close() => _commands.close();
}
