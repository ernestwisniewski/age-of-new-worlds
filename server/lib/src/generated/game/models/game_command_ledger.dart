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
import 'package:aonw_server/src/generated/protocol.dart' as _i3;

abstract class GameCommandLedger
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameCommandLedger._({
    this.id,
    required this.matchId,
    this.match,
    required this.playerId,
    required this.clientCommandId,
    required this.expectedRevision,
    required this.initialEventOffset,
    required this.finalEventOffset,
    this.requestJson,
    required this.recipientOutcomeJson,
    required this.createdAt,
  });

  factory GameCommandLedger({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String playerId,
    required String clientCommandId,
    required int expectedRevision,
    required int initialEventOffset,
    required int finalEventOffset,
    String? requestJson,
    required String recipientOutcomeJson,
    required DateTime createdAt,
  }) = _GameCommandLedgerImpl;

  factory GameCommandLedger.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameCommandLedger(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      playerId: jsonSerialization['playerId'] as String,
      clientCommandId: jsonSerialization['clientCommandId'] as String,
      expectedRevision: jsonSerialization['expectedRevision'] as int,
      initialEventOffset: jsonSerialization['initialEventOffset'] as int,
      finalEventOffset: jsonSerialization['finalEventOffset'] as int,
      requestJson: jsonSerialization['requestJson'] as String?,
      recipientOutcomeJson: jsonSerialization['recipientOutcomeJson'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = GameCommandLedgerTable();

  static const db = GameCommandLedgerRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  String playerId;

  String clientCommandId;

  int expectedRevision;

  int initialEventOffset;

  int finalEventOffset;

  String? requestJson;

  String recipientOutcomeJson;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameCommandLedger]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameCommandLedger copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? playerId,
    String? clientCommandId,
    int? expectedRevision,
    int? initialEventOffset,
    int? finalEventOffset,
    String? requestJson,
    String? recipientOutcomeJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameCommandLedger',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'playerId': playerId,
      'clientCommandId': clientCommandId,
      'expectedRevision': expectedRevision,
      'initialEventOffset': initialEventOffset,
      'finalEventOffset': finalEventOffset,
      if (requestJson != null) 'requestJson': requestJson,
      'recipientOutcomeJson': recipientOutcomeJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameCommandLedger',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJsonForProtocol(),
      'playerId': playerId,
      'clientCommandId': clientCommandId,
      'expectedRevision': expectedRevision,
      'initialEventOffset': initialEventOffset,
      'finalEventOffset': finalEventOffset,
      'recipientOutcomeJson': recipientOutcomeJson,
      'createdAt': createdAt.toJson(),
    };
  }

  static GameCommandLedgerInclude include({_i2.GameMatchInclude? match}) {
    return GameCommandLedgerInclude._(match: match);
  }

  static GameCommandLedgerIncludeList includeList({
    _i1.WhereExpressionBuilder<GameCommandLedgerTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameCommandLedgerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameCommandLedgerTable>? orderByList,
    GameCommandLedgerInclude? include,
  }) {
    return GameCommandLedgerIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameCommandLedger.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameCommandLedger.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameCommandLedgerImpl extends GameCommandLedger {
  _GameCommandLedgerImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String playerId,
    required String clientCommandId,
    required int expectedRevision,
    required int initialEventOffset,
    required int finalEventOffset,
    String? requestJson,
    required String recipientOutcomeJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         playerId: playerId,
         clientCommandId: clientCommandId,
         expectedRevision: expectedRevision,
         initialEventOffset: initialEventOffset,
         finalEventOffset: finalEventOffset,
         requestJson: requestJson,
         recipientOutcomeJson: recipientOutcomeJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [GameCommandLedger]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameCommandLedger copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? playerId,
    String? clientCommandId,
    int? expectedRevision,
    int? initialEventOffset,
    int? finalEventOffset,
    Object? requestJson = _Undefined,
    String? recipientOutcomeJson,
    DateTime? createdAt,
  }) {
    return GameCommandLedger(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      playerId: playerId ?? this.playerId,
      clientCommandId: clientCommandId ?? this.clientCommandId,
      expectedRevision: expectedRevision ?? this.expectedRevision,
      initialEventOffset: initialEventOffset ?? this.initialEventOffset,
      finalEventOffset: finalEventOffset ?? this.finalEventOffset,
      requestJson: requestJson is String? ? requestJson : this.requestJson,
      recipientOutcomeJson: recipientOutcomeJson ?? this.recipientOutcomeJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GameCommandLedgerUpdateTable
    extends _i1.UpdateTable<GameCommandLedgerTable> {
  GameCommandLedgerUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) => _i1.ColumnValue(
    table.matchId,
    value,
  );

  _i1.ColumnValue<String, String> playerId(String value) => _i1.ColumnValue(
    table.playerId,
    value,
  );

  _i1.ColumnValue<String, String> clientCommandId(String value) =>
      _i1.ColumnValue(
        table.clientCommandId,
        value,
      );

  _i1.ColumnValue<int, int> expectedRevision(int value) => _i1.ColumnValue(
    table.expectedRevision,
    value,
  );

  _i1.ColumnValue<int, int> initialEventOffset(int value) => _i1.ColumnValue(
    table.initialEventOffset,
    value,
  );

  _i1.ColumnValue<int, int> finalEventOffset(int value) => _i1.ColumnValue(
    table.finalEventOffset,
    value,
  );

  _i1.ColumnValue<String, String> requestJson(String? value) => _i1.ColumnValue(
    table.requestJson,
    value,
  );

  _i1.ColumnValue<String, String> recipientOutcomeJson(String value) =>
      _i1.ColumnValue(
        table.recipientOutcomeJson,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class GameCommandLedgerTable extends _i1.Table<int?> {
  GameCommandLedgerTable({super.tableRelation})
    : super(tableName: 'aonw_game_command_ledger') {
    updateTable = GameCommandLedgerUpdateTable(this);
    matchId = _i1.ColumnInt(
      'matchId',
      this,
    );
    playerId = _i1.ColumnString(
      'playerId',
      this,
    );
    clientCommandId = _i1.ColumnString(
      'clientCommandId',
      this,
    );
    expectedRevision = _i1.ColumnInt(
      'expectedRevision',
      this,
    );
    initialEventOffset = _i1.ColumnInt(
      'initialEventOffset',
      this,
    );
    finalEventOffset = _i1.ColumnInt(
      'finalEventOffset',
      this,
    );
    requestJson = _i1.ColumnString(
      'requestJson',
      this,
    );
    recipientOutcomeJson = _i1.ColumnString(
      'recipientOutcomeJson',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final GameCommandLedgerUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnString playerId;

  late final _i1.ColumnString clientCommandId;

  late final _i1.ColumnInt expectedRevision;

  late final _i1.ColumnInt initialEventOffset;

  late final _i1.ColumnInt finalEventOffset;

  late final _i1.ColumnString requestJson;

  late final _i1.ColumnString recipientOutcomeJson;

  late final _i1.ColumnDateTime createdAt;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GameCommandLedger.t.matchId,
      foreignField: _i2.GameMatch.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GameMatchTable(tableRelation: foreignTableRelation),
    );
    return _match!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    matchId,
    playerId,
    clientCommandId,
    expectedRevision,
    initialEventOffset,
    finalEventOffset,
    requestJson,
    recipientOutcomeJson,
    createdAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'match') {
      return match;
    }
    return null;
  }
}

class GameCommandLedgerInclude extends _i1.IncludeObject {
  GameCommandLedgerInclude._({_i2.GameMatchInclude? match}) {
    _match = match;
  }

  _i2.GameMatchInclude? _match;

  @override
  Map<String, _i1.Include?> get includes => {'match': _match};

  @override
  _i1.Table<int?> get table => GameCommandLedger.t;
}

class GameCommandLedgerIncludeList extends _i1.IncludeList {
  GameCommandLedgerIncludeList._({
    _i1.WhereExpressionBuilder<GameCommandLedgerTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameCommandLedger.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameCommandLedger.t;
}

class GameCommandLedgerRepository {
  const GameCommandLedgerRepository._();

  final attachRow = const GameCommandLedgerAttachRowRepository._();

  /// Returns a list of [GameCommandLedger]s matching the given query parameters.
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
  Future<List<GameCommandLedger>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameCommandLedgerTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameCommandLedgerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameCommandLedgerTable>? orderByList,
    _i1.Transaction? transaction,
    GameCommandLedgerInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameCommandLedger>(
      where: where?.call(GameCommandLedger.t),
      orderBy: orderBy?.call(GameCommandLedger.t),
      orderByList: orderByList?.call(GameCommandLedger.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameCommandLedger] matching the given query parameters.
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
  Future<GameCommandLedger?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameCommandLedgerTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameCommandLedgerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameCommandLedgerTable>? orderByList,
    _i1.Transaction? transaction,
    GameCommandLedgerInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameCommandLedger>(
      where: where?.call(GameCommandLedger.t),
      orderBy: orderBy?.call(GameCommandLedger.t),
      orderByList: orderByList?.call(GameCommandLedger.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameCommandLedger] by its [id] or null if no such row exists.
  Future<GameCommandLedger?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameCommandLedgerInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameCommandLedger>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameCommandLedger]s in the list and returns the inserted rows.
  ///
  /// The returned [GameCommandLedger]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameCommandLedger>> insert(
    _i1.DatabaseSession session,
    List<GameCommandLedger> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameCommandLedger>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameCommandLedger] and returns the inserted row.
  ///
  /// The returned [GameCommandLedger] will have its `id` field set.
  Future<GameCommandLedger> insertRow(
    _i1.DatabaseSession session,
    GameCommandLedger row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameCommandLedger>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameCommandLedger]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameCommandLedger>> update(
    _i1.DatabaseSession session,
    List<GameCommandLedger> rows, {
    _i1.ColumnSelections<GameCommandLedgerTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameCommandLedger>(
      rows,
      columns: columns?.call(GameCommandLedger.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameCommandLedger]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameCommandLedger> updateRow(
    _i1.DatabaseSession session,
    GameCommandLedger row, {
    _i1.ColumnSelections<GameCommandLedgerTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameCommandLedger>(
      row,
      columns: columns?.call(GameCommandLedger.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameCommandLedger] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameCommandLedger?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameCommandLedgerUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameCommandLedger>(
      id,
      columnValues: columnValues(GameCommandLedger.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameCommandLedger]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameCommandLedger>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameCommandLedgerUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<GameCommandLedgerTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameCommandLedgerTable>? orderBy,
    _i1.OrderByListBuilder<GameCommandLedgerTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameCommandLedger>(
      columnValues: columnValues(GameCommandLedger.t.updateTable),
      where: where(GameCommandLedger.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameCommandLedger.t),
      orderByList: orderByList?.call(GameCommandLedger.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameCommandLedger]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameCommandLedger>> delete(
    _i1.DatabaseSession session,
    List<GameCommandLedger> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameCommandLedger>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameCommandLedger].
  Future<GameCommandLedger> deleteRow(
    _i1.DatabaseSession session,
    GameCommandLedger row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameCommandLedger>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameCommandLedger>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameCommandLedgerTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameCommandLedger>(
      where: where(GameCommandLedger.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameCommandLedgerTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameCommandLedger>(
      where: where?.call(GameCommandLedger.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameCommandLedger] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameCommandLedgerTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameCommandLedger>(
      where: where(GameCommandLedger.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameCommandLedgerAttachRowRepository {
  const GameCommandLedgerAttachRowRepository._();

  /// Creates a relation between the given [GameCommandLedger] and [GameMatch]
  /// by setting the [GameCommandLedger]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GameCommandLedger gameCommandLedger,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gameCommandLedger.id == null) {
      throw ArgumentError.notNull('gameCommandLedger.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gameCommandLedger = gameCommandLedger.copyWith(matchId: match.id);
    await session.db.updateRow<GameCommandLedger>(
      $gameCommandLedger,
      columns: [GameCommandLedger.t.matchId],
      transaction: transaction,
    );
  }
}
