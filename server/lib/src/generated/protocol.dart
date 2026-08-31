/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i3;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i4;
import 'auth/models/account.dart' as _i5;
import 'auth/models/account_auth_exception.dart' as _i6;
import 'auth/models/external_auth_poll_result.dart' as _i7;
import 'auth/models/external_auth_request.dart' as _i8;
import 'auth/models/external_auth_start.dart' as _i9;
import 'auth/models/steam_account.dart' as _i10;
import 'auth/models/steam_auth_poll_result.dart' as _i11;
import 'auth/models/steam_auth_request.dart' as _i12;
import 'auth/models/steam_auth_start.dart' as _i13;
import 'game/models/game_command_ledger.dart' as _i14;
import 'game/models/game_command_outcome.dart' as _i15;
import 'game/models/game_create_match_request.dart' as _i16;
import 'game/models/game_event.dart' as _i17;
import 'game/models/game_exception.dart' as _i18;
import 'game/models/game_join_match_request.dart' as _i19;
import 'game/models/game_match.dart' as _i20;
import 'game/models/game_match_view.dart' as _i21;
import 'game/models/game_participant.dart' as _i22;
import 'game/models/game_recipient_snapshot.dart' as _i23;
import 'game/models/game_resync.dart' as _i24;
import 'game/models/game_submit_turn_request.dart' as _i25;
import 'package:aonw_server/src/generated/game/models/game_match_view.dart'
    as _i26;
export 'auth/models/account.dart';
export 'auth/models/account_auth_exception.dart';
export 'auth/models/external_auth_poll_result.dart';
export 'auth/models/external_auth_request.dart';
export 'auth/models/external_auth_start.dart';
export 'auth/models/steam_account.dart';
export 'auth/models/steam_auth_poll_result.dart';
export 'auth/models/steam_auth_request.dart';
export 'auth/models/steam_auth_start.dart';
export 'game/models/game_command_ledger.dart';
export 'game/models/game_command_outcome.dart';
export 'game/models/game_create_match_request.dart';
export 'game/models/game_event.dart';
export 'game/models/game_exception.dart';
export 'game/models/game_join_match_request.dart';
export 'game/models/game_match.dart';
export 'game/models/game_match_view.dart';
export 'game/models/game_participant.dart';
export 'game/models/game_recipient_snapshot.dart';
export 'game/models/game_resync.dart';
export 'game/models/game_submit_turn_request.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'aonw_account',
      dartName: 'AonwAccount',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'displayNameKey',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'passwordHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_account_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_account_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_account_email_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_account_display_name_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'displayNameKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_account_auth_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_external_auth_request',
      dartName: 'ExternalAuthRequest',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'state',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'provider',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'codeVerifier',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'error',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'authStrategy',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'token',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'tokenExpiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'refreshToken',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'scopeNames',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'completedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'consumedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_request_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_state_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'state',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_external_auth_request_expires_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_game_command_ledger',
      dartName: 'GameCommandLedger',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault:
              'nextval(\'aonw_game_command_ledger_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'matchId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'playerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'clientCommandId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'expectedRevision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'initialEventOffset',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'finalEventOffset',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'requestJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'recipientOutcomeJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_game_command_ledger_fk_0',
          columns: ['matchId'],
          referenceTable: 'aonw_game_match',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_game_command_ledger_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_command_idempotency_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'playerId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientCommandId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_command_offset_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'finalEventOffset',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_game_event',
      dartName: 'GameEvent',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'aonw_game_event_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'matchId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'offset',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'eventJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_game_event_fk_0',
          columns: ['matchId'],
          referenceTable: 'aonw_game_match',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_game_event_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_event_match_offset_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'offset',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_game_match',
      dartName: 'GameMatch',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'aonw_game_match_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'publicId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'mapId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'mapHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'rulesetId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'rulesetHash',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'mapDocument',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'canonicalStateJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'state',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'turn',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'startedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'endedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'outcomeCondition',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'winnerPlayerId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'revision',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'eventOffset',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_game_match_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_match_public_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'publicId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_match_updated_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'publicId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_match_started_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'startedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_match_ended_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'endedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_game_participant',
      dartName: 'GameParticipant',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'aonw_game_participant_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'matchId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userIdentifier',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'playerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'joinedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_game_participant_fk_0',
          columns: ['matchId'],
          referenceTable: 'aonw_game_match',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_game_participant_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_participant_match_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userIdentifier',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_participant_match_player_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'playerId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_game_recipient_snapshot',
      dartName: 'GameRecipientSnapshot',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault:
              'nextval(\'aonw_game_recipient_snapshot_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'matchId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'playerId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'eventOffset',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'snapshotJson',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_game_recipient_snapshot_fk_0',
          columns: ['matchId'],
          referenceTable: 'aonw_game_match',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_game_recipient_snapshot_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_game_recipient_snapshot_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'matchId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'playerId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_steam_account',
      dartName: 'SteamAccount',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'steamId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastSeenAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'aonw_steam_account_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_steam_account_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_account_steam_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'steamId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_account_auth_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'aonw_steam_auth_request',
      dartName: 'SteamAuthRequest',
      schema: 'public',
      module: 'aonw',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'requestId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'steamId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'error',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'expiresAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'completedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'consumedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'aonw_steam_auth_request_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_auth_request_request_id_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'requestId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_auth_request_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'aonw_steam_auth_request_expires_at_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'expiresAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.AonwAccount) {
      return _i5.AonwAccount.fromJson(data) as T;
    }
    if (t == _i6.AccountAuthException) {
      return _i6.AccountAuthException.fromJson(data) as T;
    }
    if (t == _i7.ExternalAuthPollResult) {
      return _i7.ExternalAuthPollResult.fromJson(data) as T;
    }
    if (t == _i8.ExternalAuthRequest) {
      return _i8.ExternalAuthRequest.fromJson(data) as T;
    }
    if (t == _i9.ExternalAuthStart) {
      return _i9.ExternalAuthStart.fromJson(data) as T;
    }
    if (t == _i10.SteamAccount) {
      return _i10.SteamAccount.fromJson(data) as T;
    }
    if (t == _i11.SteamAuthPollResult) {
      return _i11.SteamAuthPollResult.fromJson(data) as T;
    }
    if (t == _i12.SteamAuthRequest) {
      return _i12.SteamAuthRequest.fromJson(data) as T;
    }
    if (t == _i13.SteamAuthStart) {
      return _i13.SteamAuthStart.fromJson(data) as T;
    }
    if (t == _i14.GameCommandLedger) {
      return _i14.GameCommandLedger.fromJson(data) as T;
    }
    if (t == _i15.GameCommandOutcome) {
      return _i15.GameCommandOutcome.fromJson(data) as T;
    }
    if (t == _i16.GameCreateMatchRequest) {
      return _i16.GameCreateMatchRequest.fromJson(data) as T;
    }
    if (t == _i17.GameEvent) {
      return _i17.GameEvent.fromJson(data) as T;
    }
    if (t == _i18.GameException) {
      return _i18.GameException.fromJson(data) as T;
    }
    if (t == _i19.GameJoinMatchRequest) {
      return _i19.GameJoinMatchRequest.fromJson(data) as T;
    }
    if (t == _i20.GameMatch) {
      return _i20.GameMatch.fromJson(data) as T;
    }
    if (t == _i21.GameMatchView) {
      return _i21.GameMatchView.fromJson(data) as T;
    }
    if (t == _i22.GameParticipant) {
      return _i22.GameParticipant.fromJson(data) as T;
    }
    if (t == _i23.GameRecipientSnapshot) {
      return _i23.GameRecipientSnapshot.fromJson(data) as T;
    }
    if (t == _i24.GameResync) {
      return _i24.GameResync.fromJson(data) as T;
    }
    if (t == _i25.GameSubmitTurnRequest) {
      return _i25.GameSubmitTurnRequest.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.AonwAccount?>()) {
      return (data != null ? _i5.AonwAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AccountAuthException?>()) {
      return (data != null ? _i6.AccountAuthException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.ExternalAuthPollResult?>()) {
      return (data != null ? _i7.ExternalAuthPollResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.ExternalAuthRequest?>()) {
      return (data != null ? _i8.ExternalAuthRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.ExternalAuthStart?>()) {
      return (data != null ? _i9.ExternalAuthStart.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.SteamAccount?>()) {
      return (data != null ? _i10.SteamAccount.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.SteamAuthPollResult?>()) {
      return (data != null ? _i11.SteamAuthPollResult.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.SteamAuthRequest?>()) {
      return (data != null ? _i12.SteamAuthRequest.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.SteamAuthStart?>()) {
      return (data != null ? _i13.SteamAuthStart.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.GameCommandLedger?>()) {
      return (data != null ? _i14.GameCommandLedger.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.GameCommandOutcome?>()) {
      return (data != null ? _i15.GameCommandOutcome.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.GameCreateMatchRequest?>()) {
      return (data != null ? _i16.GameCreateMatchRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.GameEvent?>()) {
      return (data != null ? _i17.GameEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.GameException?>()) {
      return (data != null ? _i18.GameException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.GameJoinMatchRequest?>()) {
      return (data != null ? _i19.GameJoinMatchRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.GameMatch?>()) {
      return (data != null ? _i20.GameMatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.GameMatchView?>()) {
      return (data != null ? _i21.GameMatchView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.GameParticipant?>()) {
      return (data != null ? _i22.GameParticipant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.GameRecipientSnapshot?>()) {
      return (data != null ? _i23.GameRecipientSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i24.GameResync?>()) {
      return (data != null ? _i24.GameResync.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.GameSubmitTurnRequest?>()) {
      return (data != null ? _i25.GameSubmitTurnRequest.fromJson(data) : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i22.GameParticipant>) {
      return (data as List)
              .map((e) => deserialize<_i22.GameParticipant>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i22.GameParticipant>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i22.GameParticipant>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i14.GameCommandLedger>) {
      return (data as List)
              .map((e) => deserialize<_i14.GameCommandLedger>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i14.GameCommandLedger>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i14.GameCommandLedger>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i17.GameEvent>) {
      return (data as List).map((e) => deserialize<_i17.GameEvent>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i17.GameEvent>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i17.GameEvent>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i23.GameRecipientSnapshot>) {
      return (data as List)
              .map((e) => deserialize<_i23.GameRecipientSnapshot>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i23.GameRecipientSnapshot>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i23.GameRecipientSnapshot>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i26.GameMatchView>) {
      return (data as List)
              .map((e) => deserialize<_i26.GameMatchView>(e))
              .toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.AonwAccount => 'AonwAccount',
      _i6.AccountAuthException => 'AccountAuthException',
      _i7.ExternalAuthPollResult => 'ExternalAuthPollResult',
      _i8.ExternalAuthRequest => 'ExternalAuthRequest',
      _i9.ExternalAuthStart => 'ExternalAuthStart',
      _i10.SteamAccount => 'SteamAccount',
      _i11.SteamAuthPollResult => 'SteamAuthPollResult',
      _i12.SteamAuthRequest => 'SteamAuthRequest',
      _i13.SteamAuthStart => 'SteamAuthStart',
      _i14.GameCommandLedger => 'GameCommandLedger',
      _i15.GameCommandOutcome => 'GameCommandOutcome',
      _i16.GameCreateMatchRequest => 'GameCreateMatchRequest',
      _i17.GameEvent => 'GameEvent',
      _i18.GameException => 'GameException',
      _i19.GameJoinMatchRequest => 'GameJoinMatchRequest',
      _i20.GameMatch => 'GameMatch',
      _i21.GameMatchView => 'GameMatchView',
      _i22.GameParticipant => 'GameParticipant',
      _i23.GameRecipientSnapshot => 'GameRecipientSnapshot',
      _i24.GameResync => 'GameResync',
      _i25.GameSubmitTurnRequest => 'GameSubmitTurnRequest',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('aonw.', '');
    }

    switch (data) {
      case _i5.AonwAccount():
        return 'AonwAccount';
      case _i6.AccountAuthException():
        return 'AccountAuthException';
      case _i7.ExternalAuthPollResult():
        return 'ExternalAuthPollResult';
      case _i8.ExternalAuthRequest():
        return 'ExternalAuthRequest';
      case _i9.ExternalAuthStart():
        return 'ExternalAuthStart';
      case _i10.SteamAccount():
        return 'SteamAccount';
      case _i11.SteamAuthPollResult():
        return 'SteamAuthPollResult';
      case _i12.SteamAuthRequest():
        return 'SteamAuthRequest';
      case _i13.SteamAuthStart():
        return 'SteamAuthStart';
      case _i14.GameCommandLedger():
        return 'GameCommandLedger';
      case _i15.GameCommandOutcome():
        return 'GameCommandOutcome';
      case _i16.GameCreateMatchRequest():
        return 'GameCreateMatchRequest';
      case _i17.GameEvent():
        return 'GameEvent';
      case _i18.GameException():
        return 'GameException';
      case _i19.GameJoinMatchRequest():
        return 'GameJoinMatchRequest';
      case _i20.GameMatch():
        return 'GameMatch';
      case _i21.GameMatchView():
        return 'GameMatchView';
      case _i22.GameParticipant():
        return 'GameParticipant';
      case _i23.GameRecipientSnapshot():
        return 'GameRecipientSnapshot';
      case _i24.GameResync():
        return 'GameResync';
      case _i25.GameSubmitTurnRequest():
        return 'GameSubmitTurnRequest';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AonwAccount') {
      return deserialize<_i5.AonwAccount>(data['data']);
    }
    if (dataClassName == 'AccountAuthException') {
      return deserialize<_i6.AccountAuthException>(data['data']);
    }
    if (dataClassName == 'ExternalAuthPollResult') {
      return deserialize<_i7.ExternalAuthPollResult>(data['data']);
    }
    if (dataClassName == 'ExternalAuthRequest') {
      return deserialize<_i8.ExternalAuthRequest>(data['data']);
    }
    if (dataClassName == 'ExternalAuthStart') {
      return deserialize<_i9.ExternalAuthStart>(data['data']);
    }
    if (dataClassName == 'SteamAccount') {
      return deserialize<_i10.SteamAccount>(data['data']);
    }
    if (dataClassName == 'SteamAuthPollResult') {
      return deserialize<_i11.SteamAuthPollResult>(data['data']);
    }
    if (dataClassName == 'SteamAuthRequest') {
      return deserialize<_i12.SteamAuthRequest>(data['data']);
    }
    if (dataClassName == 'SteamAuthStart') {
      return deserialize<_i13.SteamAuthStart>(data['data']);
    }
    if (dataClassName == 'GameCommandLedger') {
      return deserialize<_i14.GameCommandLedger>(data['data']);
    }
    if (dataClassName == 'GameCommandOutcome') {
      return deserialize<_i15.GameCommandOutcome>(data['data']);
    }
    if (dataClassName == 'GameCreateMatchRequest') {
      return deserialize<_i16.GameCreateMatchRequest>(data['data']);
    }
    if (dataClassName == 'GameEvent') {
      return deserialize<_i17.GameEvent>(data['data']);
    }
    if (dataClassName == 'GameException') {
      return deserialize<_i18.GameException>(data['data']);
    }
    if (dataClassName == 'GameJoinMatchRequest') {
      return deserialize<_i19.GameJoinMatchRequest>(data['data']);
    }
    if (dataClassName == 'GameMatch') {
      return deserialize<_i20.GameMatch>(data['data']);
    }
    if (dataClassName == 'GameMatchView') {
      return deserialize<_i21.GameMatchView>(data['data']);
    }
    if (dataClassName == 'GameParticipant') {
      return deserialize<_i22.GameParticipant>(data['data']);
    }
    if (dataClassName == 'GameRecipientSnapshot') {
      return deserialize<_i23.GameRecipientSnapshot>(data['data']);
    }
    if (dataClassName == 'GameResync') {
      return deserialize<_i24.GameResync>(data['data']);
    }
    if (dataClassName == 'GameSubmitTurnRequest') {
      return deserialize<_i25.GameSubmitTurnRequest>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i5.AonwAccount:
        return _i5.AonwAccount.t;
      case _i8.ExternalAuthRequest:
        return _i8.ExternalAuthRequest.t;
      case _i10.SteamAccount:
        return _i10.SteamAccount.t;
      case _i12.SteamAuthRequest:
        return _i12.SteamAuthRequest.t;
      case _i14.GameCommandLedger:
        return _i14.GameCommandLedger.t;
      case _i17.GameEvent:
        return _i17.GameEvent.t;
      case _i20.GameMatch:
        return _i20.GameMatch.t;
      case _i22.GameParticipant:
        return _i22.GameParticipant.t;
      case _i23.GameRecipientSnapshot:
        return _i23.GameRecipientSnapshot.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'aonw';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
