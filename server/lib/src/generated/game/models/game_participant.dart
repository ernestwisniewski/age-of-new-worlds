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
import '../../game/models/game_lobby_connection.dart' as _i3;
import 'package:aonw_server/src/generated/protocol.dart' as _i4;

abstract class GameParticipant
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameParticipant._({
    this.id,
    required this.matchId,
    this.match,
    required this.userIdentifier,
    required this.playerId,
    required this.joinedAt,
    this.readyAt,
    this.leftAt,
    this.resignedAt,
    this.kickedAt,
    this.kickReason,
    this.lobbyConnections,
  });

  factory GameParticipant({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String userIdentifier,
    required String playerId,
    required DateTime joinedAt,
    DateTime? readyAt,
    DateTime? leftAt,
    DateTime? resignedAt,
    DateTime? kickedAt,
    String? kickReason,
    List<_i3.GameLobbyConnection>? lobbyConnections,
  }) = _GameParticipantImpl;

  factory GameParticipant.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameParticipant(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      userIdentifier: jsonSerialization['userIdentifier'] as String,
      playerId: jsonSerialization['playerId'] as String,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
      readyAt: jsonSerialization['readyAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['readyAt']),
      leftAt: jsonSerialization['leftAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['leftAt']),
      resignedAt: jsonSerialization['resignedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resignedAt']),
      kickedAt: jsonSerialization['kickedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['kickedAt']),
      kickReason: jsonSerialization['kickReason'] as String?,
      lobbyConnections: jsonSerialization['lobbyConnections'] == null
          ? null
          : _i4.Protocol().deserialize<List<_i3.GameLobbyConnection>>(
              jsonSerialization['lobbyConnections'],
            ),
    );
  }

  static final t = GameParticipantTable();

  static const db = GameParticipantRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  String userIdentifier;

  String playerId;

  DateTime joinedAt;

  DateTime? readyAt;

  DateTime? leftAt;

  DateTime? resignedAt;

  DateTime? kickedAt;

  String? kickReason;

  List<_i3.GameLobbyConnection>? lobbyConnections;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameParticipant copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? userIdentifier,
    String? playerId,
    DateTime? joinedAt,
    DateTime? readyAt,
    DateTime? leftAt,
    DateTime? resignedAt,
    DateTime? kickedAt,
    String? kickReason,
    List<_i3.GameLobbyConnection>? lobbyConnections,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameParticipant',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'userIdentifier': userIdentifier,
      'playerId': playerId,
      'joinedAt': joinedAt.toJson(),
      if (readyAt != null) 'readyAt': readyAt?.toJson(),
      if (leftAt != null) 'leftAt': leftAt?.toJson(),
      if (resignedAt != null) 'resignedAt': resignedAt?.toJson(),
      if (kickedAt != null) 'kickedAt': kickedAt?.toJson(),
      if (kickReason != null) 'kickReason': kickReason,
      if (lobbyConnections != null)
        'lobbyConnections': lobbyConnections?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameParticipant',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJsonForProtocol(),
      'userIdentifier': userIdentifier,
      'playerId': playerId,
      'joinedAt': joinedAt.toJson(),
      if (readyAt != null) 'readyAt': readyAt?.toJson(),
      if (leftAt != null) 'leftAt': leftAt?.toJson(),
      if (resignedAt != null) 'resignedAt': resignedAt?.toJson(),
      if (kickedAt != null) 'kickedAt': kickedAt?.toJson(),
      if (kickReason != null) 'kickReason': kickReason,
    };
  }

  static GameParticipantInclude include({
    _i2.GameMatchInclude? match,
    _i3.GameLobbyConnectionIncludeList? lobbyConnections,
  }) {
    return GameParticipantInclude._(
      match: match,
      lobbyConnections: lobbyConnections,
    );
  }

  static GameParticipantIncludeList includeList({
    _i1.WhereExpressionBuilder<GameParticipantTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameParticipantTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameParticipantTable>? orderByList,
    GameParticipantInclude? include,
  }) {
    return GameParticipantIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameParticipant.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameParticipant.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameParticipantImpl extends GameParticipant {
  _GameParticipantImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String userIdentifier,
    required String playerId,
    required DateTime joinedAt,
    DateTime? readyAt,
    DateTime? leftAt,
    DateTime? resignedAt,
    DateTime? kickedAt,
    String? kickReason,
    List<_i3.GameLobbyConnection>? lobbyConnections,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         userIdentifier: userIdentifier,
         playerId: playerId,
         joinedAt: joinedAt,
         readyAt: readyAt,
         leftAt: leftAt,
         resignedAt: resignedAt,
         kickedAt: kickedAt,
         kickReason: kickReason,
         lobbyConnections: lobbyConnections,
       );

  /// Returns a shallow copy of this [GameParticipant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameParticipant copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? userIdentifier,
    String? playerId,
    DateTime? joinedAt,
    Object? readyAt = _Undefined,
    Object? leftAt = _Undefined,
    Object? resignedAt = _Undefined,
    Object? kickedAt = _Undefined,
    Object? kickReason = _Undefined,
    Object? lobbyConnections = _Undefined,
  }) {
    return GameParticipant(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      userIdentifier: userIdentifier ?? this.userIdentifier,
      playerId: playerId ?? this.playerId,
      joinedAt: joinedAt ?? this.joinedAt,
      readyAt: readyAt is DateTime? ? readyAt : this.readyAt,
      leftAt: leftAt is DateTime? ? leftAt : this.leftAt,
      resignedAt: resignedAt is DateTime? ? resignedAt : this.resignedAt,
      kickedAt: kickedAt is DateTime? ? kickedAt : this.kickedAt,
      kickReason: kickReason is String? ? kickReason : this.kickReason,
      lobbyConnections: lobbyConnections is List<_i3.GameLobbyConnection>?
          ? lobbyConnections
          : this.lobbyConnections?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class GameParticipantUpdateTable extends _i1.UpdateTable<GameParticipantTable> {
  GameParticipantUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) => _i1.ColumnValue(
    table.matchId,
    value,
  );

  _i1.ColumnValue<String, String> userIdentifier(String value) =>
      _i1.ColumnValue(
        table.userIdentifier,
        value,
      );

  _i1.ColumnValue<String, String> playerId(String value) => _i1.ColumnValue(
    table.playerId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> joinedAt(DateTime value) =>
      _i1.ColumnValue(
        table.joinedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> readyAt(DateTime? value) =>
      _i1.ColumnValue(
        table.readyAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> leftAt(DateTime? value) =>
      _i1.ColumnValue(
        table.leftAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> resignedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.resignedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> kickedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.kickedAt,
        value,
      );

  _i1.ColumnValue<String, String> kickReason(String? value) => _i1.ColumnValue(
    table.kickReason,
    value,
  );
}

class GameParticipantTable extends _i1.Table<int?> {
  GameParticipantTable({super.tableRelation})
    : super(tableName: 'aonw_game_participant') {
    updateTable = GameParticipantUpdateTable(this);
    matchId = _i1.ColumnInt(
      'matchId',
      this,
    );
    userIdentifier = _i1.ColumnString(
      'userIdentifier',
      this,
    );
    playerId = _i1.ColumnString(
      'playerId',
      this,
    );
    joinedAt = _i1.ColumnDateTime(
      'joinedAt',
      this,
    );
    readyAt = _i1.ColumnDateTime(
      'readyAt',
      this,
    );
    leftAt = _i1.ColumnDateTime(
      'leftAt',
      this,
    );
    resignedAt = _i1.ColumnDateTime(
      'resignedAt',
      this,
    );
    kickedAt = _i1.ColumnDateTime(
      'kickedAt',
      this,
    );
    kickReason = _i1.ColumnString(
      'kickReason',
      this,
    );
  }

  late final GameParticipantUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnString userIdentifier;

  late final _i1.ColumnString playerId;

  late final _i1.ColumnDateTime joinedAt;

  late final _i1.ColumnDateTime readyAt;

  late final _i1.ColumnDateTime leftAt;

  late final _i1.ColumnDateTime resignedAt;

  late final _i1.ColumnDateTime kickedAt;

  late final _i1.ColumnString kickReason;

  _i3.GameLobbyConnectionTable? ___lobbyConnections;

  _i1.ManyRelation<_i3.GameLobbyConnectionTable>? _lobbyConnections;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GameParticipant.t.matchId,
      foreignField: _i2.GameMatch.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GameMatchTable(tableRelation: foreignTableRelation),
    );
    return _match!;
  }

  _i3.GameLobbyConnectionTable get __lobbyConnections {
    if (___lobbyConnections != null) return ___lobbyConnections!;
    ___lobbyConnections = _i1.createRelationTable(
      relationFieldName: '__lobbyConnections',
      field: GameParticipant.t.id,
      foreignField: _i3.GameLobbyConnection.t.participantId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.GameLobbyConnectionTable(tableRelation: foreignTableRelation),
    );
    return ___lobbyConnections!;
  }

  _i1.ManyRelation<_i3.GameLobbyConnectionTable> get lobbyConnections {
    if (_lobbyConnections != null) return _lobbyConnections!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'lobbyConnections',
      field: GameParticipant.t.id,
      foreignField: _i3.GameLobbyConnection.t.participantId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.GameLobbyConnectionTable(tableRelation: foreignTableRelation),
    );
    _lobbyConnections = _i1.ManyRelation<_i3.GameLobbyConnectionTable>(
      tableWithRelations: relationTable,
      table: _i3.GameLobbyConnectionTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _lobbyConnections!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    matchId,
    userIdentifier,
    playerId,
    joinedAt,
    readyAt,
    leftAt,
    resignedAt,
    kickedAt,
    kickReason,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'match') {
      return match;
    }
    if (relationField == 'lobbyConnections') {
      return __lobbyConnections;
    }
    return null;
  }
}

class GameParticipantInclude extends _i1.IncludeObject {
  GameParticipantInclude._({
    _i2.GameMatchInclude? match,
    _i3.GameLobbyConnectionIncludeList? lobbyConnections,
  }) {
    _match = match;
    _lobbyConnections = lobbyConnections;
  }

  _i2.GameMatchInclude? _match;

  _i3.GameLobbyConnectionIncludeList? _lobbyConnections;

  @override
  Map<String, _i1.Include?> get includes => {
    'match': _match,
    'lobbyConnections': _lobbyConnections,
  };

  @override
  _i1.Table<int?> get table => GameParticipant.t;
}

class GameParticipantIncludeList extends _i1.IncludeList {
  GameParticipantIncludeList._({
    _i1.WhereExpressionBuilder<GameParticipantTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameParticipant.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameParticipant.t;
}

class GameParticipantRepository {
  const GameParticipantRepository._();

  final attach = const GameParticipantAttachRepository._();

  final attachRow = const GameParticipantAttachRowRepository._();

  /// Returns a list of [GameParticipant]s matching the given query parameters.
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
  Future<List<GameParticipant>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameParticipantTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameParticipantTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameParticipantTable>? orderByList,
    _i1.Transaction? transaction,
    GameParticipantInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameParticipant>(
      where: where?.call(GameParticipant.t),
      orderBy: orderBy?.call(GameParticipant.t),
      orderByList: orderByList?.call(GameParticipant.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameParticipant] matching the given query parameters.
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
  Future<GameParticipant?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameParticipantTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameParticipantTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameParticipantTable>? orderByList,
    _i1.Transaction? transaction,
    GameParticipantInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameParticipant>(
      where: where?.call(GameParticipant.t),
      orderBy: orderBy?.call(GameParticipant.t),
      orderByList: orderByList?.call(GameParticipant.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameParticipant] by its [id] or null if no such row exists.
  Future<GameParticipant?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameParticipantInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameParticipant>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameParticipant]s in the list and returns the inserted rows.
  ///
  /// The returned [GameParticipant]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameParticipant>> insert(
    _i1.DatabaseSession session,
    List<GameParticipant> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameParticipant>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameParticipant] and returns the inserted row.
  ///
  /// The returned [GameParticipant] will have its `id` field set.
  Future<GameParticipant> insertRow(
    _i1.DatabaseSession session,
    GameParticipant row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameParticipant>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameParticipant]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameParticipant>> update(
    _i1.DatabaseSession session,
    List<GameParticipant> rows, {
    _i1.ColumnSelections<GameParticipantTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameParticipant>(
      rows,
      columns: columns?.call(GameParticipant.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameParticipant]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameParticipant> updateRow(
    _i1.DatabaseSession session,
    GameParticipant row, {
    _i1.ColumnSelections<GameParticipantTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameParticipant>(
      row,
      columns: columns?.call(GameParticipant.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameParticipant] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameParticipant?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameParticipantUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameParticipant>(
      id,
      columnValues: columnValues(GameParticipant.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameParticipant]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameParticipant>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameParticipantUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<GameParticipantTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameParticipantTable>? orderBy,
    _i1.OrderByListBuilder<GameParticipantTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameParticipant>(
      columnValues: columnValues(GameParticipant.t.updateTable),
      where: where(GameParticipant.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameParticipant.t),
      orderByList: orderByList?.call(GameParticipant.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameParticipant]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameParticipant>> delete(
    _i1.DatabaseSession session,
    List<GameParticipant> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameParticipant>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameParticipant].
  Future<GameParticipant> deleteRow(
    _i1.DatabaseSession session,
    GameParticipant row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameParticipant>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameParticipant>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameParticipantTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameParticipant>(
      where: where(GameParticipant.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameParticipantTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameParticipant>(
      where: where?.call(GameParticipant.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameParticipant] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameParticipantTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameParticipant>(
      where: where(GameParticipant.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameParticipantAttachRepository {
  const GameParticipantAttachRepository._();

  /// Creates a relation between this [GameParticipant] and the given [GameLobbyConnection]s
  /// by setting each [GameLobbyConnection]'s foreign key `participantId` to refer to this [GameParticipant].
  Future<void> lobbyConnections(
    _i1.DatabaseSession session,
    GameParticipant gameParticipant,
    List<_i3.GameLobbyConnection> gameLobbyConnection, {
    _i1.Transaction? transaction,
  }) async {
    if (gameLobbyConnection.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameLobbyConnection.id');
    }
    if (gameParticipant.id == null) {
      throw ArgumentError.notNull('gameParticipant.id');
    }

    var $gameLobbyConnection = gameLobbyConnection
        .map((e) => e.copyWith(participantId: gameParticipant.id))
        .toList();
    await session.db.update<_i3.GameLobbyConnection>(
      $gameLobbyConnection,
      columns: [_i3.GameLobbyConnection.t.participantId],
      transaction: transaction,
    );
  }
}

class GameParticipantAttachRowRepository {
  const GameParticipantAttachRowRepository._();

  /// Creates a relation between the given [GameParticipant] and [GameMatch]
  /// by setting the [GameParticipant]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GameParticipant gameParticipant,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gameParticipant.id == null) {
      throw ArgumentError.notNull('gameParticipant.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gameParticipant = gameParticipant.copyWith(matchId: match.id);
    await session.db.updateRow<GameParticipant>(
      $gameParticipant,
      columns: [GameParticipant.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameParticipant] and the given [GameLobbyConnection]
  /// by setting the [GameLobbyConnection]'s foreign key `participantId` to refer to this [GameParticipant].
  Future<void> lobbyConnections(
    _i1.DatabaseSession session,
    GameParticipant gameParticipant,
    _i3.GameLobbyConnection gameLobbyConnection, {
    _i1.Transaction? transaction,
  }) async {
    if (gameLobbyConnection.id == null) {
      throw ArgumentError.notNull('gameLobbyConnection.id');
    }
    if (gameParticipant.id == null) {
      throw ArgumentError.notNull('gameParticipant.id');
    }

    var $gameLobbyConnection = gameLobbyConnection.copyWith(
      participantId: gameParticipant.id,
    );
    await session.db.updateRow<_i3.GameLobbyConnection>(
      $gameLobbyConnection,
      columns: [_i3.GameLobbyConnection.t.participantId],
      transaction: transaction,
    );
  }
}
