import '../read_model/replay_frame_view.dart';

enum ReplayFailureViewCode {
  unavailable,
  missing,
  unreadable,
  incompatible,
  seekFailed,
}

enum ReplaySpeedView {
  half(0.5),
  normal(1),
  twoTimes(2),
  fourTimes(4);

  const ReplaySpeedView(this.multiplier);

  final double multiplier;

  Duration get frameDuration =>
      Duration(milliseconds: (800 / multiplier).round());
}

sealed class ReplayState {
  const ReplayState();
}

final class ReplayIdle extends ReplayState {
  const ReplayIdle();
}

final class ReplayLoading extends ReplayState {
  const ReplayLoading();
}

final class ReplayFailure extends ReplayState {
  const ReplayFailure(this.code);

  final ReplayFailureViewCode code;
}

final class ReplayReady extends ReplayState {
  const ReplayReady({
    required this.frame,
    required this.speed,
    required this.isPlaying,
    required this.isSeeking,
  });

  final ReplayFrameView frame;
  final ReplaySpeedView speed;
  final bool isPlaying;
  final bool isSeeking;

  ReplayReady copyWith({
    ReplayFrameView? frame,
    ReplaySpeedView? speed,
    bool? isPlaying,
    bool? isSeeking,
  }) => ReplayReady(
    frame: frame ?? this.frame,
    speed: speed ?? this.speed,
    isPlaying: isPlaying ?? this.isPlaying,
    isSeeking: isSeeking ?? this.isSeeking,
  );
}
