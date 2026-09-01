import 'package:flutter/widgets.dart';

final class AonwMenuAdjustIntent extends Intent {
  const AonwMenuAdjustIntent(this.delta);

  final int delta;
}

final class AonwMenuAdjustable extends StatelessWidget {
  const AonwMenuAdjustable({
    required this.onAdjust,
    required this.child,
    super.key,
  });

  final ValueChanged<int> onAdjust;
  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      AonwMenuAdjustIntent: CallbackAction<AonwMenuAdjustIntent>(
        onInvoke: (intent) {
          onAdjust(intent.delta);
          return true;
        },
      ),
    },
    child: child,
  );
}
