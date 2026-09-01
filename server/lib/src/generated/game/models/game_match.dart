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
// ignore_for_file: unnecessary_null_comparison

import 'package:serverpod/serverpod.dart' as _i1;
import '../../game/models/game_participant.dart' as _i2;
import '../../game/models/game_command_ledger.dart' as _i3;
import '../../game/models/game_event.dart' as _i4;
import '../../game/models/game_recipient_snapshot.dart' as _i5;
import 'package:aonw_server/src/generated/protocol.dart' as _i6;

abstract class GameMatch
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameMatch._({
    this.id,
    required this.publicId,
    required this.mapId,
    required this.mapHash,
    required this.rulesetId,
    required this.rulesetHash,
    this.mapDocument,
    this.canonicalStateJson,
    required this.state,
    this.hostPlayerId,
    required this.turn,
    this.startedAt,
    this.turnDeadlineAt,
    this.endedAt,
    this.outcomeCondition,
    this.winnerPlayerId,
    required this.revision,
    required this.eventOffset,
    required this.createdAt,
    required this.updatedAt,
    this.participants,
    this.commands,
    this.events,
    this.recipientSnapshots,
  });

  factory GameMatch({
    int? id,
    required String publicId,
    required String mapId,
    required String mapHash,
    required String rulesetId,
    required String rulesetHash,
    String? mapDocument,
    String? canonicalStateJson,
    required String state,
    String? hostPlayerId,
    required int turn,
    DateTime? startedAt,
    DateTime? turnDeadlineAt,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    required int revision,
    required int eventOffset,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<_i2.GameParticipant>? participants,
    List<_i3.GameCommandLedger>? commands,
    List<_i4.GameEvent>? events,
    List<_i5.GameRecipientSnapshot>? recipientSnapshots,
  }) = _GameMatchImpl;

  factory GameMatch.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameMatch(
      id: jsonSerialization['id'] as int?,
      publicId: jsonSerialization['publicId'] as String,
      mapId: jsonSerialization['mapId'] as String,
      mapHash: jsonSerialization['mapHash'] as String,
      rulesetId: jsonSerialization['rulesetId'] as String,
      rulesetHash: jsonSerialization['rulesetHash'] as String,
      mapDocument: jsonSerialization['mapDocument'] as String?,
      canonicalStateJson: jsonSerialization['canonicalStateJson'] as String?,
      state: jsonSerialization['state'] as String,
      hostPlayerId: jsonSerialization['hostPlayerId'] as String?,
      turn: jsonSerialization['turn'] as int,
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      turnDeadlineAt: jsonSerialization['turnDeadlineAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['turnDeadlineAt'],
            ),
      endedAt: jsonSerialization['endedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endedAt']),
      outcomeCondition: jsonSerialization['outcomeCondition'] as String?,
      winnerPlayerId: jsonSerialization['winnerPlayerId'] as String?,
      revision: jsonSerialization['revision'] as int,
      eventOffset: jsonSerialization['eventOffset'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      participants: jsonSerialization['participants'] == null
          ? null
          : _i6.Protocol().deserialize<List<_i2.GameParticipant>>(
              jsonSerialization['participants'],
            ),
      commands: jsonSerialization['commands'] == null
          ? null
          : _i6.Protocol().deserialize<List<_i3.GameCommandLedger>>(
              jsonSerialization['commands'],
            ),
      events: jsonSerialization['events'] == null
          ? null
          : _i6.Protocol().deserialize<List<_i4.GameEvent>>(
              jsonSerialization['events'],
            ),
      recipientSnapshots: jsonSerialization['recipientSnapshots'] == null
          ? null
          : _i6.Protocol().deserialize<List<_i5.GameRecipientSnapshot>>(
              jsonSerialization['recipientSnapshots'],
            ),
    );
  }

  static final t = GameMatchTable();

  static const db = GameMatchRepository._();

  @override
  int? id;

  String publicId;

  String mapId;

  String mapHash;

  String rulesetId;

  String rulesetHash;

  String? mapDocument;

  String? canonicalStateJson;

  String state;

  String? hostPlayerId;

  int turn;

  DateTime? startedAt;

  DateTime? turnDeadlineAt;

  DateTime? endedAt;

  String? outcomeCondition;

  String? winnerPlayerId;

  int revision;

  int eventOffset;

  DateTime createdAt;

  DateTime updatedAt;

  List<_i2.GameParticipant>? participants;

  List<_i3.GameCommandLedger>? commands;

  List<_i4.GameEvent>? events;

  List<_i5.GameRecipientSnapshot>? recipientSnapshots;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameMatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameMatch copyWith({
    int? id,
    String? publicId,
    String? mapId,
    String? mapHash,
    String? rulesetId,
    String? rulesetHash,
    String? mapDocument,
    String? canonicalStateJson,
    String? state,
    String? hostPlayerId,
    int? turn,
    DateTime? startedAt,
    DateTime? turnDeadlineAt,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    int? revision,
    int? eventOffset,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<_i2.GameParticipant>? participants,
    List<_i3.GameCommandLedger>? commands,
    List<_i4.GameEvent>? events,
    List<_i5.GameRecipientSnapshot>? recipientSnapshots,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameMatch',
      if (id != null) 'id': id,
      'publicId': publicId,
      'mapId': mapId,
      'mapHash': mapHash,
      'rulesetId': rulesetId,
      'rulesetHash': rulesetHash,
      if (mapDocument != null) 'mapDocument': mapDocument,
      if (canonicalStateJson != null) 'canonicalStateJson': canonicalStateJson,
      'state': state,
      if (hostPlayerId != null) 'hostPlayerId': hostPlayerId,
      'turn': turn,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (turnDeadlineAt != null) 'turnDeadlineAt': turnDeadlineAt?.toJson(),
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      if (outcomeCondition != null) 'outcomeCondition': outcomeCondition,
      if (winnerPlayerId != null) 'winnerPlayerId': winnerPlayerId,
      'revision': revision,
      'eventOffset': eventOffset,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (participants != null)
        'participants': participants?.toJson(valueToJson: (v) => v.toJson()),
      if (commands != null)
        'commands': commands?.toJson(valueToJson: (v) => v.toJson()),
      if (events != null)
        'events': events?.toJson(valueToJson: (v) => v.toJson()),
      if (recipientSnapshots != null)
        'recipientSnapshots': recipientSnapshots?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameMatch',
      if (id != null) 'id': id,
      'publicId': publicId,
      'mapId': mapId,
      'mapHash': mapHash,
      'rulesetId': rulesetId,
      'rulesetHash': rulesetHash,
      'state': state,
      if (hostPlayerId != null) 'hostPlayerId': hostPlayerId,
      'turn': turn,
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      if (outcomeCondition != null) 'outcomeCondition': outcomeCondition,
      if (winnerPlayerId != null) 'winnerPlayerId': winnerPlayerId,
      'revision': revision,
      'eventOffset': eventOffset,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static GameMatchInclude include({
    _i2.GameParticipantIncludeList? participants,
    _i3.GameCommandLedgerIncludeList? commands,
    _i4.GameEventIncludeList? events,
    _i5.GameRecipientSnapshotIncludeList? recipientSnapshots,
  }) {
    return GameMatchInclude._(
      participants: participants,
      commands: commands,
      events: events,
      recipientSnapshots: recipientSnapshots,
    );
  }

  static GameMatchIncludeList includeList({
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchTable>? orderByList,
    GameMatchInclude? include,
  }) {
    return GameMatchIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameMatch.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameMatch.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameMatchImpl extends GameMatch {
  _GameMatchImpl({
    int? id,
    required String publicId,
    required String mapId,
    required String mapHash,
    required String rulesetId,
    required String rulesetHash,
    String? mapDocument,
    String? canonicalStateJson,
    required String state,
    String? hostPlayerId,
    required int turn,
    DateTime? startedAt,
    DateTime? turnDeadlineAt,
    DateTime? endedAt,
    String? outcomeCondition,
    String? winnerPlayerId,
    required int revision,
    required int eventOffset,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<_i2.GameParticipant>? participants,
    List<_i3.GameCommandLedger>? commands,
    List<_i4.GameEvent>? events,
    List<_i5.GameRecipientSnapshot>? recipientSnapshots,
  }) : super._(
         id: id,
         publicId: publicId,
         mapId: mapId,
         mapHash: mapHash,
         rulesetId: rulesetId,
         rulesetHash: rulesetHash,
         mapDocument: mapDocument,
         canonicalStateJson: canonicalStateJson,
         state: state,
         hostPlayerId: hostPlayerId,
         turn: turn,
         startedAt: startedAt,
         turnDeadlineAt: turnDeadlineAt,
         endedAt: endedAt,
         outcomeCondition: outcomeCondition,
         winnerPlayerId: winnerPlayerId,
         revision: revision,
         eventOffset: eventOffset,
         createdAt: createdAt,
         updatedAt: updatedAt,
         participants: participants,
         commands: commands,
         events: events,
         recipientSnapshots: recipientSnapshots,
       );

  /// Returns a shallow copy of this [GameMatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameMatch copyWith({
    Object? id = _Undefined,
    String? publicId,
    String? mapId,
    String? mapHash,
    String? rulesetId,
    String? rulesetHash,
    Object? mapDocument = _Undefined,
    Object? canonicalStateJson = _Undefined,
    String? state,
    Object? hostPlayerId = _Undefined,
    int? turn,
    Object? startedAt = _Undefined,
    Object? turnDeadlineAt = _Undefined,
    Object? endedAt = _Undefined,
    Object? outcomeCondition = _Undefined,
    Object? winnerPlayerId = _Undefined,
    int? revision,
    int? eventOffset,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? participants = _Undefined,
    Object? commands = _Undefined,
    Object? events = _Undefined,
    Object? recipientSnapshots = _Undefined,
  }) {
    return GameMatch(
      id: id is int? ? id : this.id,
      publicId: publicId ?? this.publicId,
      mapId: mapId ?? this.mapId,
      mapHash: mapHash ?? this.mapHash,
      rulesetId: rulesetId ?? this.rulesetId,
      rulesetHash: rulesetHash ?? this.rulesetHash,
      mapDocument: mapDocument is String? ? mapDocument : this.mapDocument,
      canonicalStateJson: canonicalStateJson is String?
          ? canonicalStateJson
          : this.canonicalStateJson,
      state: state ?? this.state,
      hostPlayerId: hostPlayerId is String? ? hostPlayerId : this.hostPlayerId,
      turn: turn ?? this.turn,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      turnDeadlineAt: turnDeadlineAt is DateTime?
          ? turnDeadlineAt
          : this.turnDeadlineAt,
      endedAt: endedAt is DateTime? ? endedAt : this.endedAt,
      outcomeCondition: outcomeCondition is String?
          ? outcomeCondition
          : this.outcomeCondition,
      winnerPlayerId: winnerPlayerId is String?
          ? winnerPlayerId
          : this.winnerPlayerId,
      revision: revision ?? this.revision,
      eventOffset: eventOffset ?? this.eventOffset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants is List<_i2.GameParticipant>?
          ? participants
          : this.participants?.map((e0) => e0.copyWith()).toList(),
      commands: commands is List<_i3.GameCommandLedger>?
          ? commands
          : this.commands?.map((e0) => e0.copyWith()).toList(),
      events: events is List<_i4.GameEvent>?
          ? events
          : this.events?.map((e0) => e0.copyWith()).toList(),
      recipientSnapshots: recipientSnapshots is List<_i5.GameRecipientSnapshot>?
          ? recipientSnapshots
          : this.recipientSnapshots?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class GameMatchUpdateTable extends _i1.UpdateTable<GameMatchTable> {
  GameMatchUpdateTable(super.table);

  _i1.ColumnValue<String, String> publicId(String value) => _i1.ColumnValue(
    table.publicId,
    value,
  );

  _i1.ColumnValue<String, String> mapId(String value) => _i1.ColumnValue(
    table.mapId,
    value,
  );

  _i1.ColumnValue<String, String> mapHash(String value) => _i1.ColumnValue(
    table.mapHash,
    value,
  );

  _i1.ColumnValue<String, String> rulesetId(String value) => _i1.ColumnValue(
    table.rulesetId,
    value,
  );

  _i1.ColumnValue<String, String> rulesetHash(String value) => _i1.ColumnValue(
    table.rulesetHash,
    value,
  );

  _i1.ColumnValue<String, String> mapDocument(String? value) => _i1.ColumnValue(
    table.mapDocument,
    value,
  );

  _i1.ColumnValue<String, String> canonicalStateJson(String? value) =>
      _i1.ColumnValue(
        table.canonicalStateJson,
        value,
      );

  _i1.ColumnValue<String, String> state(String value) => _i1.ColumnValue(
    table.state,
    value,
  );

  _i1.ColumnValue<String, String> hostPlayerId(String? value) =>
      _i1.ColumnValue(
        table.hostPlayerId,
        value,
      );

  _i1.ColumnValue<int, int> turn(int value) => _i1.ColumnValue(
    table.turn,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> startedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.startedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> turnDeadlineAt(DateTime? value) =>
      _i1.ColumnValue(
        table.turnDeadlineAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> endedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.endedAt,
        value,
      );

  _i1.ColumnValue<String, String> outcomeCondition(String? value) =>
      _i1.ColumnValue(
        table.outcomeCondition,
        value,
      );

  _i1.ColumnValue<String, String> winnerPlayerId(String? value) =>
      _i1.ColumnValue(
        table.winnerPlayerId,
        value,
      );

  _i1.ColumnValue<int, int> revision(int value) => _i1.ColumnValue(
    table.revision,
    value,
  );

  _i1.ColumnValue<int, int> eventOffset(int value) => _i1.ColumnValue(
    table.eventOffset,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class GameMatchTable extends _i1.Table<int?> {
  GameMatchTable({super.tableRelation}) : super(tableName: 'aonw_game_match') {
    updateTable = GameMatchUpdateTable(this);
    publicId = _i1.ColumnString(
      'publicId',
      this,
    );
    mapId = _i1.ColumnString(
      'mapId',
      this,
    );
    mapHash = _i1.ColumnString(
      'mapHash',
      this,
    );
    rulesetId = _i1.ColumnString(
      'rulesetId',
      this,
    );
    rulesetHash = _i1.ColumnString(
      'rulesetHash',
      this,
    );
    mapDocument = _i1.ColumnString(
      'mapDocument',
      this,
    );
    canonicalStateJson = _i1.ColumnString(
      'canonicalStateJson',
      this,
    );
    state = _i1.ColumnString(
      'state',
      this,
    );
    hostPlayerId = _i1.ColumnString(
      'hostPlayerId',
      this,
    );
    turn = _i1.ColumnInt(
      'turn',
      this,
    );
    startedAt = _i1.ColumnDateTime(
      'startedAt',
      this,
    );
    turnDeadlineAt = _i1.ColumnDateTime(
      'turnDeadlineAt',
      this,
    );
    endedAt = _i1.ColumnDateTime(
      'endedAt',
      this,
    );
    outcomeCondition = _i1.ColumnString(
      'outcomeCondition',
      this,
    );
    winnerPlayerId = _i1.ColumnString(
      'winnerPlayerId',
      this,
    );
    revision = _i1.ColumnInt(
      'revision',
      this,
    );
    eventOffset = _i1.ColumnInt(
      'eventOffset',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final GameMatchUpdateTable updateTable;

  late final _i1.ColumnString publicId;

  late final _i1.ColumnString mapId;

  late final _i1.ColumnString mapHash;

  late final _i1.ColumnString rulesetId;

  late final _i1.ColumnString rulesetHash;

  late final _i1.ColumnString mapDocument;

  late final _i1.ColumnString canonicalStateJson;

  late final _i1.ColumnString state;

  late final _i1.ColumnString hostPlayerId;

  late final _i1.ColumnInt turn;

  late final _i1.ColumnDateTime startedAt;

  late final _i1.ColumnDateTime turnDeadlineAt;

  late final _i1.ColumnDateTime endedAt;

  late final _i1.ColumnString outcomeCondition;

  late final _i1.ColumnString winnerPlayerId;

  late final _i1.ColumnInt revision;

  late final _i1.ColumnInt eventOffset;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  _i2.GameParticipantTable? ___participants;

  _i1.ManyRelation<_i2.GameParticipantTable>? _participants;

  _i3.GameCommandLedgerTable? ___commands;

  _i1.ManyRelation<_i3.GameCommandLedgerTable>? _commands;

  _i4.GameEventTable? ___events;

  _i1.ManyRelation<_i4.GameEventTable>? _events;

  _i5.GameRecipientSnapshotTable? ___recipientSnapshots;

  _i1.ManyRelation<_i5.GameRecipientSnapshotTable>? _recipientSnapshots;

  _i2.GameParticipantTable get __participants {
    if (___participants != null) return ___participants!;
    ___participants = _i1.createRelationTable(
      relationFieldName: '__participants',
      field: GameMatch.t.id,
      foreignField: _i2.GameParticipant.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GameParticipantTable(tableRelation: foreignTableRelation),
    );
    return ___participants!;
  }

  _i3.GameCommandLedgerTable get __commands {
    if (___commands != null) return ___commands!;
    ___commands = _i1.createRelationTable(
      relationFieldName: '__commands',
      field: GameMatch.t.id,
      foreignField: _i3.GameCommandLedger.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.GameCommandLedgerTable(tableRelation: foreignTableRelation),
    );
    return ___commands!;
  }

  _i4.GameEventTable get __events {
    if (___events != null) return ___events!;
    ___events = _i1.createRelationTable(
      relationFieldName: '__events',
      field: GameMatch.t.id,
      foreignField: _i4.GameEvent.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.GameEventTable(tableRelation: foreignTableRelation),
    );
    return ___events!;
  }

  _i5.GameRecipientSnapshotTable get __recipientSnapshots {
    if (___recipientSnapshots != null) return ___recipientSnapshots!;
    ___recipientSnapshots = _i1.createRelationTable(
      relationFieldName: '__recipientSnapshots',
      field: GameMatch.t.id,
      foreignField: _i5.GameRecipientSnapshot.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i5.GameRecipientSnapshotTable(tableRelation: foreignTableRelation),
    );
    return ___recipientSnapshots!;
  }

  _i1.ManyRelation<_i2.GameParticipantTable> get participants {
    if (_participants != null) return _participants!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'participants',
      field: GameMatch.t.id,
      foreignField: _i2.GameParticipant.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GameParticipantTable(tableRelation: foreignTableRelation),
    );
    _participants = _i1.ManyRelation<_i2.GameParticipantTable>(
      tableWithRelations: relationTable,
      table: _i2.GameParticipantTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _participants!;
  }

  _i1.ManyRelation<_i3.GameCommandLedgerTable> get commands {
    if (_commands != null) return _commands!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'commands',
      field: GameMatch.t.id,
      foreignField: _i3.GameCommandLedger.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.GameCommandLedgerTable(tableRelation: foreignTableRelation),
    );
    _commands = _i1.ManyRelation<_i3.GameCommandLedgerTable>(
      tableWithRelations: relationTable,
      table: _i3.GameCommandLedgerTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _commands!;
  }

  _i1.ManyRelation<_i4.GameEventTable> get events {
    if (_events != null) return _events!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'events',
      field: GameMatch.t.id,
      foreignField: _i4.GameEvent.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.GameEventTable(tableRelation: foreignTableRelation),
    );
    _events = _i1.ManyRelation<_i4.GameEventTable>(
      tableWithRelations: relationTable,
      table: _i4.GameEventTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _events!;
  }

  _i1.ManyRelation<_i5.GameRecipientSnapshotTable> get recipientSnapshots {
    if (_recipientSnapshots != null) return _recipientSnapshots!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'recipientSnapshots',
      field: GameMatch.t.id,
      foreignField: _i5.GameRecipientSnapshot.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i5.GameRecipientSnapshotTable(tableRelation: foreignTableRelation),
    );
    _recipientSnapshots = _i1.ManyRelation<_i5.GameRecipientSnapshotTable>(
      tableWithRelations: relationTable,
      table: _i5.GameRecipientSnapshotTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _recipientSnapshots!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    publicId,
    mapId,
    mapHash,
    rulesetId,
    rulesetHash,
    mapDocument,
    canonicalStateJson,
    state,
    hostPlayerId,
    turn,
    startedAt,
    turnDeadlineAt,
    endedAt,
    outcomeCondition,
    winnerPlayerId,
    revision,
    eventOffset,
    createdAt,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'participants') {
      return __participants;
    }
    if (relationField == 'commands') {
      return __commands;
    }
    if (relationField == 'events') {
      return __events;
    }
    if (relationField == 'recipientSnapshots') {
      return __recipientSnapshots;
    }
    return null;
  }
}

class GameMatchInclude extends _i1.IncludeObject {
  GameMatchInclude._({
    _i2.GameParticipantIncludeList? participants,
    _i3.GameCommandLedgerIncludeList? commands,
    _i4.GameEventIncludeList? events,
    _i5.GameRecipientSnapshotIncludeList? recipientSnapshots,
  }) {
    _participants = participants;
    _commands = commands;
    _events = events;
    _recipientSnapshots = recipientSnapshots;
  }

  _i2.GameParticipantIncludeList? _participants;

  _i3.GameCommandLedgerIncludeList? _commands;

  _i4.GameEventIncludeList? _events;

  _i5.GameRecipientSnapshotIncludeList? _recipientSnapshots;

  @override
  Map<String, _i1.Include?> get includes => {
    'participants': _participants,
    'commands': _commands,
    'events': _events,
    'recipientSnapshots': _recipientSnapshots,
  };

  @override
  _i1.Table<int?> get table => GameMatch.t;
}

class GameMatchIncludeList extends _i1.IncludeList {
  GameMatchIncludeList._({
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameMatch.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameMatch.t;
}

class GameMatchRepository {
  const GameMatchRepository._();

  final attach = const GameMatchAttachRepository._();

  final attachRow = const GameMatchAttachRowRepository._();

  final detach = const GameMatchDetachRepository._();

  final detachRow = const GameMatchDetachRowRepository._();

  /// Returns a list of [GameMatch]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<GameMatch>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchTable>? orderByList,
    _i1.Transaction? transaction,
    GameMatchInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameMatch>(
      where: where?.call(GameMatch.t),
      orderBy: orderBy?.call(GameMatch.t),
      orderByList: orderByList?.call(GameMatch.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameMatch] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<GameMatch?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameMatchTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchTable>? orderByList,
    _i1.Transaction? transaction,
    GameMatchInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameMatch>(
      where: where?.call(GameMatch.t),
      orderBy: orderBy?.call(GameMatch.t),
      orderByList: orderByList?.call(GameMatch.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameMatch] by its [id] or null if no such row exists.
  Future<GameMatch?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameMatchInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameMatch>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameMatch]s in the list and returns the inserted rows.
  ///
  /// The returned [GameMatch]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameMatch>> insert(
    _i1.DatabaseSession session,
    List<GameMatch> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameMatch>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameMatch] and returns the inserted row.
  ///
  /// The returned [GameMatch] will have its `id` field set.
  Future<GameMatch> insertRow(
    _i1.DatabaseSession session,
    GameMatch row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameMatch>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameMatch]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameMatch>> update(
    _i1.DatabaseSession session,
    List<GameMatch> rows, {
    _i1.ColumnSelections<GameMatchTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameMatch>(
      rows,
      columns: columns?.call(GameMatch.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameMatch]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameMatch> updateRow(
    _i1.DatabaseSession session,
    GameMatch row, {
    _i1.ColumnSelections<GameMatchTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameMatch>(
      row,
      columns: columns?.call(GameMatch.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameMatch] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameMatch?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameMatchUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameMatch>(
      id,
      columnValues: columnValues(GameMatch.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameMatch]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameMatch>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameMatchUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<GameMatchTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchTable>? orderBy,
    _i1.OrderByListBuilder<GameMatchTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameMatch>(
      columnValues: columnValues(GameMatch.t.updateTable),
      where: where(GameMatch.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameMatch.t),
      orderByList: orderByList?.call(GameMatch.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameMatch]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameMatch>> delete(
    _i1.DatabaseSession session,
    List<GameMatch> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameMatch>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameMatch].
  Future<GameMatch> deleteRow(
    _i1.DatabaseSession session,
    GameMatch row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameMatch>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameMatch>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameMatchTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameMatch>(
      where: where(GameMatch.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameMatch>(
      where: where?.call(GameMatch.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameMatch] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameMatchTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameMatch>(
      where: where(GameMatch.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameMatchAttachRepository {
  const GameMatchAttachRepository._();

  /// Creates a relation between this [GameMatch] and the given [GameParticipant]s
  /// by setting each [GameParticipant]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> participants(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    List<_i2.GameParticipant> gameParticipant, {
    _i1.Transaction? transaction,
  }) async {
    if (gameParticipant.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameParticipant.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameParticipant = gameParticipant
        .map((e) => e.copyWith(matchId: gameMatch.id))
        .toList();
    await session.db.update<_i2.GameParticipant>(
      $gameParticipant,
      columns: [_i2.GameParticipant.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameCommandLedger]s
  /// by setting each [GameCommandLedger]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> commands(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    List<_i3.GameCommandLedger> gameCommandLedger, {
    _i1.Transaction? transaction,
  }) async {
    if (gameCommandLedger.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameCommandLedger.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameCommandLedger = gameCommandLedger
        .map((e) => e.copyWith(matchId: gameMatch.id))
        .toList();
    await session.db.update<_i3.GameCommandLedger>(
      $gameCommandLedger,
      columns: [_i3.GameCommandLedger.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameEvent]s
  /// by setting each [GameEvent]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> events(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    List<_i4.GameEvent> gameEvent, {
    _i1.Transaction? transaction,
  }) async {
    if (gameEvent.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameEvent.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameEvent = gameEvent
        .map((e) => e.copyWith(matchId: gameMatch.id))
        .toList();
    await session.db.update<_i4.GameEvent>(
      $gameEvent,
      columns: [_i4.GameEvent.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameRecipientSnapshot]s
  /// by setting each [GameRecipientSnapshot]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> recipientSnapshots(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    List<_i5.GameRecipientSnapshot> gameRecipientSnapshot, {
    _i1.Transaction? transaction,
  }) async {
    if (gameRecipientSnapshot.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameRecipientSnapshot.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameRecipientSnapshot = gameRecipientSnapshot
        .map((e) => e.copyWith(matchId: gameMatch.id))
        .toList();
    await session.db.update<_i5.GameRecipientSnapshot>(
      $gameRecipientSnapshot,
      columns: [_i5.GameRecipientSnapshot.t.matchId],
      transaction: transaction,
    );
  }
}

class GameMatchAttachRowRepository {
  const GameMatchAttachRowRepository._();

  /// Creates a relation between this [GameMatch] and the given [GameParticipant]
  /// by setting the [GameParticipant]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> participants(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    _i2.GameParticipant gameParticipant, {
    _i1.Transaction? transaction,
  }) async {
    if (gameParticipant.id == null) {
      throw ArgumentError.notNull('gameParticipant.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameParticipant = gameParticipant.copyWith(matchId: gameMatch.id);
    await session.db.updateRow<_i2.GameParticipant>(
      $gameParticipant,
      columns: [_i2.GameParticipant.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameCommandLedger]
  /// by setting the [GameCommandLedger]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> commands(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    _i3.GameCommandLedger gameCommandLedger, {
    _i1.Transaction? transaction,
  }) async {
    if (gameCommandLedger.id == null) {
      throw ArgumentError.notNull('gameCommandLedger.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameCommandLedger = gameCommandLedger.copyWith(matchId: gameMatch.id);
    await session.db.updateRow<_i3.GameCommandLedger>(
      $gameCommandLedger,
      columns: [_i3.GameCommandLedger.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameEvent]
  /// by setting the [GameEvent]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> events(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    _i4.GameEvent gameEvent, {
    _i1.Transaction? transaction,
  }) async {
    if (gameEvent.id == null) {
      throw ArgumentError.notNull('gameEvent.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameEvent = gameEvent.copyWith(matchId: gameMatch.id);
    await session.db.updateRow<_i4.GameEvent>(
      $gameEvent,
      columns: [_i4.GameEvent.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameRecipientSnapshot]
  /// by setting the [GameRecipientSnapshot]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> recipientSnapshots(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    _i5.GameRecipientSnapshot gameRecipientSnapshot, {
    _i1.Transaction? transaction,
  }) async {
    if (gameRecipientSnapshot.id == null) {
      throw ArgumentError.notNull('gameRecipientSnapshot.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameRecipientSnapshot = gameRecipientSnapshot.copyWith(
      matchId: gameMatch.id,
    );
    await session.db.updateRow<_i5.GameRecipientSnapshot>(
      $gameRecipientSnapshot,
      columns: [_i5.GameRecipientSnapshot.t.matchId],
      transaction: transaction,
    );
  }
}

class GameMatchDetachRepository {
  const GameMatchDetachRepository._();

  /// Detaches the relation between this [GameMatch] and the given [GameParticipant]
  /// by setting the [GameParticipant]'s foreign key `matchId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> participants(
    _i1.DatabaseSession session,
    List<_i2.GameParticipant> gameParticipant, {
    _i1.Transaction? transaction,
  }) async {
    if (gameParticipant.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameParticipant.id');
    }

    var $gameParticipant = gameParticipant
        .map((e) => e.copyWith(matchId: null))
        .toList();
    await session.db.update<_i2.GameParticipant>(
      $gameParticipant,
      columns: [_i2.GameParticipant.t.matchId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [GameMatch] and the given [GameRecipientSnapshot]
  /// by setting the [GameRecipientSnapshot]'s foreign key `matchId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> recipientSnapshots(
    _i1.DatabaseSession session,
    List<_i5.GameRecipientSnapshot> gameRecipientSnapshot, {
    _i1.Transaction? transaction,
  }) async {
    if (gameRecipientSnapshot.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameRecipientSnapshot.id');
    }

    var $gameRecipientSnapshot = gameRecipientSnapshot
        .map((e) => e.copyWith(matchId: null))
        .toList();
    await session.db.update<_i5.GameRecipientSnapshot>(
      $gameRecipientSnapshot,
      columns: [_i5.GameRecipientSnapshot.t.matchId],
      transaction: transaction,
    );
  }
}

class GameMatchDetachRowRepository {
  const GameMatchDetachRowRepository._();

  /// Detaches the relation between this [GameMatch] and the given [GameParticipant]
  /// by setting the [GameParticipant]'s foreign key `matchId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> participants(
    _i1.DatabaseSession session,
    _i2.GameParticipant gameParticipant, {
    _i1.Transaction? transaction,
  }) async {
    if (gameParticipant.id == null) {
      throw ArgumentError.notNull('gameParticipant.id');
    }

    var $gameParticipant = gameParticipant.copyWith(matchId: null);
    await session.db.updateRow<_i2.GameParticipant>(
      $gameParticipant,
      columns: [_i2.GameParticipant.t.matchId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [GameMatch] and the given [GameRecipientSnapshot]
  /// by setting the [GameRecipientSnapshot]'s foreign key `matchId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> recipientSnapshots(
    _i1.DatabaseSession session,
    _i5.GameRecipientSnapshot gameRecipientSnapshot, {
    _i1.Transaction? transaction,
  }) async {
    if (gameRecipientSnapshot.id == null) {
      throw ArgumentError.notNull('gameRecipientSnapshot.id');
    }

    var $gameRecipientSnapshot = gameRecipientSnapshot.copyWith(matchId: null);
    await session.db.updateRow<_i5.GameRecipientSnapshot>(
      $gameRecipientSnapshot,
      columns: [_i5.GameRecipientSnapshot.t.matchId],
      transaction: transaction,
    );
  }
}
