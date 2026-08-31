import 'package:aonw_server/src/generated/protocol.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'AccountProfileEndpoint',
    (sessionBuilder, endpoints) {
      test(
        'provisions one account under concurrent social callbacks',
        () async {
          _ensureAuthServices();
          final databaseSession = sessionBuilder.build();
          final authUser = await auth_core.AuthServices.instance.authUsers
              .create(databaseSession);
          await auth_core.AuthServices.instance.userProfiles.createUserProfile(
            databaseSession,
            authUser.id,
            auth_core.UserProfileData(
              userName: 'Concurrent Social',
              fullName: 'Concurrent Social',
            ),
          );
          final authenticated = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              authUser.id.uuid,
              const {},
            ),
          );

          final displayNames = await Future.wait([
            endpoints.accountProfile.ensureAccount(authenticated),
            endpoints.accountProfile.ensureAccount(authenticated),
          ]);
          final accounts = await AonwAccount.db.find(
            databaseSession,
            where: (table) => table.authUserId.equals(authUser.id),
          );

          expect(displayNames.toSet(), {'Concurrent Social'});
          expect(accounts, hasLength(1));
        },
      );
    },
    // This group intentionally overlaps two database transactions. The smoke
    // runner recreates the test database before every integration run.
    rollbackDatabase: RollbackDatabase.disabled,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

void _ensureAuthServices() {
  try {
    auth_core.AuthServices.instance;
  } on StateError {
    auth_core.AuthServices.set(
      tokenManagerBuilders: [auth_core.JwtConfigFromPasswords()],
    );
  }
}
