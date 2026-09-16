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
import '../../game/models/game_match.dart' as _i2;
import '../../game/models/game_participant.dart' as _i3;
import 'package:aonw_server/src/generated/protocol.dart' as _i4;

abstract class GameLobbyConnection
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameLobbyConnection._({
    this.id,
    required this.matchId,
    this.match,
    required this.participantId,
    this.participant,
    required this.userIdentifier,
    required this.joinedAt,
    required this.expiresAt,
  });

  factory GameLobbyConnection({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int participantId,
    _i3.GameParticipant? participant,
    required String userIdentifier,
    required DateTime joinedAt,
    required DateTime expiresAt,
  }) = _GameLobbyConnectionImpl;

  factory GameLobbyConnection.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameLobbyConnection(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      participantId: jsonSerialization['participantId'] as int,
      participant: jsonSerialization['participant'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.GameParticipant>(
              jsonSerialization['participant'],
            ),
      userIdentifier: jsonSerialization['userIdentifier'] as String,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  static final t = GameLobbyConnectionTable();

  static const db = GameLobbyConnectionRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  int participantId;

  _i3.GameParticipant? participant;

  String userIdentifier;

  DateTime joinedAt;

  DateTime expiresAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameLobbyConnection]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameLobbyConnection copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    int? participantId,
    _i3.GameParticipant? participant,
    String? userIdentifier,
    DateTime? joinedAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameLobbyConnection',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'participantId': participantId,
      if (participant != null) 'participant': participant?.toJson(),
      'userIdentifier': userIdentifier,
      'joinedAt': joinedAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static GameLobbyConnectionInclude include({
    _i2.GameMatchInclude? match,
    _i3.GameParticipantInclude? participant,
  }) {
    return GameLobbyConnectionInclude._(
      match: match,
      participant: participant,
    );
  }

  static GameLobbyConnectionIncludeList includeList({
    _i1.WhereExpressionBuilder<GameLobbyConnectionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameLobbyConnectionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameLobbyConnectionTable>? orderByList,
    GameLobbyConnectionInclude? include,
  }) {
    return GameLobbyConnectionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameLobbyConnection.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameLobbyConnection.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameLobbyConnectionImpl extends GameLobbyConnection {
  _GameLobbyConnectionImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int participantId,
    _i3.GameParticipant? participant,
    required String userIdentifier,
    required DateTime joinedAt,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         participantId: participantId,
         participant: participant,
         userIdentifier: userIdentifier,
         joinedAt: joinedAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [GameLobbyConnection]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameLobbyConnection copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    int? participantId,
    Object? participant = _Undefined,
    String? userIdentifier,
    DateTime? joinedAt,
    DateTime? expiresAt,
  }) {
    return GameLobbyConnection(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      participantId: participantId ?? this.participantId,
      participant: participant is _i3.GameParticipant?
          ? participant
          : this.participant?.copyWith(),
      userIdentifier: userIdentifier ?? this.userIdentifier,
      joinedAt: joinedAt ?? this.joinedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class GameLobbyConnectionUpdateTable
    extends _i1.UpdateTable<GameLobbyConnectionTable> {
  GameLobbyConnectionUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) => _i1.ColumnValue(
    table.matchId,
    value,
  );

  _i1.ColumnValue<int, int> participantId(int value) => _i1.ColumnValue(
    table.participantId,
    value,
  );

  _i1.ColumnValue<String, String> userIdentifier(String value) =>
      _i1.ColumnValue(
        table.userIdentifier,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> joinedAt(DateTime value) =>
      _i1.ColumnValue(
        table.joinedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );
}

class GameLobbyConnectionTable extends _i1.Table<int?> {
  GameLobbyConnectionTable({super.tableRelation})
    : super(tableName: 'aonw_game_lobby_connection') {
    updateTable = GameLobbyConnectionUpdateTable(this);
    matchId = _i1.ColumnInt(
      'matchId',
      this,
    );
    participantId = _i1.ColumnInt(
      'participantId',
      this,
    );
    userIdentifier = _i1.ColumnString(
      'userIdentifier',
      this,
    );
    joinedAt = _i1.ColumnDateTime(
      'joinedAt',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
  }

  late final GameLobbyConnectionUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnInt participantId;

  _i3.GameParticipantTable? _participant;

  late final _i1.ColumnString userIdentifier;

  late final _i1.ColumnDateTime joinedAt;

  late final _i1.ColumnDateTime expiresAt;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GameLobbyConnection.t.matchId,
      foreignField: _i2.GameMatch.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GameMatchTable(tableRelation: foreignTableRelation),
    );
    return _match!;
  }

  _i3.GameParticipantTable get participant {
    if (_participant != null) return _participant!;
    _participant = _i1.createRelationTable(
      relationFieldName: 'participant',
      field: GameLobbyConnection.t.participantId,
      foreignField: _i3.GameParticipant.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.GameParticipantTable(tableRelation: foreignTableRelation),
    );
    return _participant!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    matchId,
    participantId,
    userIdentifier,
    joinedAt,
    expiresAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'match') {
      return match;
    }
    if (relationField == 'participant') {
      return participant;
    }
    return null;
  }
}

class GameLobbyConnectionInclude extends _i1.IncludeObject {
  GameLobbyConnectionInclude._({
    _i2.GameMatchInclude? match,
    _i3.GameParticipantInclude? participant,
  }) {
    _match = match;
    _participant = participant;
  }

  _i2.GameMatchInclude? _match;

  _i3.GameParticipantInclude? _participant;

  @override
  Map<String, _i1.Include?> get includes => {
    'match': _match,
    'participant': _participant,
  };

  @override
  _i1.Table<int?> get table => GameLobbyConnection.t;
}

class GameLobbyConnectionIncludeList extends _i1.IncludeList {
  GameLobbyConnectionIncludeList._({
    _i1.WhereExpressionBuilder<GameLobbyConnectionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameLobbyConnection.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameLobbyConnection.t;
}

class GameLobbyConnectionRepository {
  const GameLobbyConnectionRepository._();

  final attachRow = const GameLobbyConnectionAttachRowRepository._();

  /// Returns a list of [GameLobbyConnection]s matching the given query parameters.
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
  Future<List<GameLobbyConnection>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameLobbyConnectionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameLobbyConnectionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameLobbyConnectionTable>? orderByList,
    _i1.Transaction? transaction,
    GameLobbyConnectionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameLobbyConnection>(
      where: where?.call(GameLobbyConnection.t),
      orderBy: orderBy?.call(GameLobbyConnection.t),
      orderByList: orderByList?.call(GameLobbyConnection.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameLobbyConnection] matching the given query parameters.
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
  Future<GameLobbyConnection?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameLobbyConnectionTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameLobbyConnectionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameLobbyConnectionTable>? orderByList,
    _i1.Transaction? transaction,
    GameLobbyConnectionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameLobbyConnection>(
      where: where?.call(GameLobbyConnection.t),
      orderBy: orderBy?.call(GameLobbyConnection.t),
      orderByList: orderByList?.call(GameLobbyConnection.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameLobbyConnection] by its [id] or null if no such row exists.
  Future<GameLobbyConnection?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameLobbyConnectionInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameLobbyConnection>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameLobbyConnection]s in the list and returns the inserted rows.
  ///
  /// The returned [GameLobbyConnection]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameLobbyConnection>> insert(
    _i1.DatabaseSession session,
    List<GameLobbyConnection> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameLobbyConnection>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameLobbyConnection] and returns the inserted row.
  ///
  /// The returned [GameLobbyConnection] will have its `id` field set.
  Future<GameLobbyConnection> insertRow(
    _i1.DatabaseSession session,
    GameLobbyConnection row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameLobbyConnection>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameLobbyConnection]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameLobbyConnection>> update(
    _i1.DatabaseSession session,
    List<GameLobbyConnection> rows, {
    _i1.ColumnSelections<GameLobbyConnectionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameLobbyConnection>(
      rows,
      columns: columns?.call(GameLobbyConnection.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameLobbyConnection]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameLobbyConnection> updateRow(
    _i1.DatabaseSession session,
    GameLobbyConnection row, {
    _i1.ColumnSelections<GameLobbyConnectionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameLobbyConnection>(
      row,
      columns: columns?.call(GameLobbyConnection.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameLobbyConnection] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameLobbyConnection?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameLobbyConnectionUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameLobbyConnection>(
      id,
      columnValues: columnValues(GameLobbyConnection.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameLobbyConnection]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameLobbyConnection>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameLobbyConnectionUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<GameLobbyConnectionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameLobbyConnectionTable>? orderBy,
    _i1.OrderByListBuilder<GameLobbyConnectionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameLobbyConnection>(
      columnValues: columnValues(GameLobbyConnection.t.updateTable),
      where: where(GameLobbyConnection.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameLobbyConnection.t),
      orderByList: orderByList?.call(GameLobbyConnection.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameLobbyConnection]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameLobbyConnection>> delete(
    _i1.DatabaseSession session,
    List<GameLobbyConnection> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameLobbyConnection>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameLobbyConnection].
  Future<GameLobbyConnection> deleteRow(
    _i1.DatabaseSession session,
    GameLobbyConnection row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameLobbyConnection>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameLobbyConnection>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameLobbyConnectionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameLobbyConnection>(
      where: where(GameLobbyConnection.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameLobbyConnectionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameLobbyConnection>(
      where: where?.call(GameLobbyConnection.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameLobbyConnection] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameLobbyConnectionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameLobbyConnection>(
      where: where(GameLobbyConnection.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameLobbyConnectionAttachRowRepository {
  const GameLobbyConnectionAttachRowRepository._();

  /// Creates a relation between the given [GameLobbyConnection] and [GameMatch]
  /// by setting the [GameLobbyConnection]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GameLobbyConnection gameLobbyConnection,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gameLobbyConnection.id == null) {
      throw ArgumentError.notNull('gameLobbyConnection.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gameLobbyConnection = gameLobbyConnection.copyWith(matchId: match.id);
    await session.db.updateRow<GameLobbyConnection>(
      $gameLobbyConnection,
      columns: [GameLobbyConnection.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [GameLobbyConnection] and [GameParticipant]
  /// by setting the [GameLobbyConnection]'s foreign key `participantId` to refer to the [GameParticipant].
  Future<void> participant(
    _i1.DatabaseSession session,
    GameLobbyConnection gameLobbyConnection,
    _i3.GameParticipant participant, {
    _i1.Transaction? transaction,
  }) async {
    if (gameLobbyConnection.id == null) {
      throw ArgumentError.notNull('gameLobbyConnection.id');
    }
    if (participant.id == null) {
      throw ArgumentError.notNull('participant.id');
    }

    var $gameLobbyConnection = gameLobbyConnection.copyWith(
      participantId: participant.id,
    );
    await session.db.updateRow<GameLobbyConnection>(
      $gameLobbyConnection,
      columns: [GameLobbyConnection.t.participantId],
      transaction: transaction,
    );
  }
}
