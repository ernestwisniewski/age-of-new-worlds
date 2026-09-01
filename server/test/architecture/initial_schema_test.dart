import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('repository contains a complete ordered database migration chain', () {
    final registry = File('migrations/migration_registry.txt');
    final versions = registry
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    expect(versions, isNotEmpty);
    expect(versions.toSet(), hasLength(versions.length));
    expect(versions.first, endsWith('-initial-schema'));
    final migrationDirectory = Directory('migrations/${versions.first}');
    final definition = File(
      '${migrationDirectory.path}/definition.sql',
    ).readAsStringSync();

    expect(definition, contains('"aonw_steam_auth_request_expires_at_idx"'));
    expect(
      definition,
      contains('"serverpod_auth_core_jwt_refresh_token_last_updated_at"'),
    );
    expect(
      definition,
      contains('"serverpod_auth_idp_rate_limited_request_attempt_composite"'),
    );
    for (final table in [
      'aonw_account',
      'aonw_external_auth_request',
      'aonw_game_command_ledger',
      'aonw_game_event',
      'aonw_game_match',
      'aonw_game_participant',
      'aonw_game_recipient_snapshot',
      'aonw_steam_account',
      'aonw_steam_auth_request',
    ]) {
      expect(definition, contains('CREATE TABLE "$table"'));
    }
    for (final version in versions.skip(1)) {
      final directory = Directory('migrations/$version');
      expect(directory.existsSync(), isTrue, reason: version);
      for (final file in [
        'definition.json',
        'definition.sql',
        'definition_project.json',
        'migration.json',
        'migration.sql',
      ]) {
        expect(File('${directory.path}/$file').existsSync(), isTrue);
      }
    }
  });
}
