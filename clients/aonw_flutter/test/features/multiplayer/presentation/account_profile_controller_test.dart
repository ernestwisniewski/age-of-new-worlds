import 'dart:async';

import 'package:aonw_flutter/features/multiplayer/application/account_profile_port.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_session_port.dart';
import 'package:aonw_flutter/features/multiplayer/presentation/account_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile preserves draft source after a rejected rename', () async {
    final port = _Profile();
    final controller = AccountProfileController(port);
    addTearDown(controller.dispose);
    await controller.load();
    port.failure = const MultiplayerSessionException(
      code: 'display_name_taken',
      message: 'Taken',
    );
    await controller.save('Taken');
    expect(controller.profile?.displayName, 'Original');
    expect(controller.failureCode, 'display_name_taken');
    expect(controller.saved, isFalse);
    expect(controller.busy, isFalse);
  });

  test(
    'invalidating the account discards late saves and duplicate submits',
    () async {
      final port = _Profile();
      final controller = AccountProfileController(port);
      addTearDown(controller.dispose);
      await controller.load();
      port.pending = Completer<AccountProfileView>();
      final saving = controller.save('Updated');
      await controller.save('Duplicate');
      expect(port.updates, 1);
      controller.invalidate();
      port.pending!.complete(
        const AccountProfileView(userId: 'account', displayName: 'Updated'),
      );
      await saving;
      expect(controller.profile, isNull);
      expect(controller.saved, isFalse);
      expect(controller.busy, isFalse);
    },
  );
}

final class _Profile implements AccountProfilePort {
  Object? failure;
  Completer<AccountProfileView>? pending;
  var updates = 0;
  @override
  Future<AccountProfileView> readProfile() async =>
      const AccountProfileView(userId: 'account', displayName: 'Original');
  @override
  Future<AccountProfileView> updateDisplayName(String displayName) async {
    updates++;
    if (failure != null) throw failure!;
    return pending?.future ??
        AccountProfileView(userId: 'account', displayName: displayName);
  }
}
