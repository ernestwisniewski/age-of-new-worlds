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

abstract class GameRecipientSnapshot
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameRecipientSnapshot._({
    this.id,
    required this.matchId,
    this.match,
    required this.playerId,
    required this.eventOffset,
    required this.snapshotJson,
    required this.updatedAt,
  });

  factory GameRecipientSnapshot({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String playerId,
    required int eventOffset,
    required String snapshotJson,
    required DateTime updatedAt,
  }) = _GameRecipientSnapshotImpl;

  factory GameRecipientSnapshot.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameRecipientSnapshot(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      playerId: jsonSerialization['playerId'] as String,
      eventOffset: jsonSerialization['eventOffset'] as int,
      snapshotJson: jsonSerialization['snapshotJson'] as String,
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = GameRecipientSnapshotTable();

  static const db = GameRecipientSnapshotRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  String playerId;

  int eventOffset;

  String snapshotJson;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameRecipientSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameRecipientSnapshot copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? playerId,
    int? eventOffset,
    String? snapshotJson,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameRecipientSnapshot',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'playerId': playerId,
      'eventOffset': eventOffset,
      'snapshotJson': snapshotJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameRecipientSnapshot',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJsonForProtocol(),
      'playerId': playerId,
      'eventOffset': eventOffset,
      'snapshotJson': snapshotJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static GameRecipientSnapshotInclude include({_i2.GameMatchInclude? match}) {
    return GameRecipientSnapshotInclude._(match: match);
  }

  static GameRecipientSnapshotIncludeList includeList({
    _i1.WhereExpressionBuilder<GameRecipientSnapshotTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameRecipientSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameRecipientSnapshotTable>? orderByList,
    GameRecipientSnapshotInclude? include,
  }) {
    return GameRecipientSnapshotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameRecipientSnapshot.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameRecipientSnapshot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameRecipientSnapshotImpl extends GameRecipientSnapshot {
  _GameRecipientSnapshotImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String playerId,
    required int eventOffset,
    required String snapshotJson,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         playerId: playerId,
         eventOffset: eventOffset,
         snapshotJson: snapshotJson,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [GameRecipientSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameRecipientSnapshot copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? playerId,
    int? eventOffset,
    String? snapshotJson,
    DateTime? updatedAt,
  }) {
    return GameRecipientSnapshot(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      playerId: playerId ?? this.playerId,
      eventOffset: eventOffset ?? this.eventOffset,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GameRecipientSnapshotUpdateTable
    extends _i1.UpdateTable<GameRecipientSnapshotTable> {
  GameRecipientSnapshotUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) => _i1.ColumnValue(
    table.matchId,
    value,
  );

  _i1.ColumnValue<String, String> playerId(String value) => _i1.ColumnValue(
    table.playerId,
    value,
  );

  _i1.ColumnValue<int, int> eventOffset(int value) => _i1.ColumnValue(
    table.eventOffset,
    value,
  );

  _i1.ColumnValue<String, String> snapshotJson(String value) => _i1.ColumnValue(
    table.snapshotJson,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class GameRecipientSnapshotTable extends _i1.Table<int?> {
  GameRecipientSnapshotTable({super.tableRelation})
    : super(tableName: 'aonw_game_recipient_snapshot') {
    updateTable = GameRecipientSnapshotUpdateTable(this);
    matchId = _i1.ColumnInt(
      'matchId',
      this,
    );
    playerId = _i1.ColumnString(
      'playerId',
      this,
    );
    eventOffset = _i1.ColumnInt(
      'eventOffset',
      this,
    );
    snapshotJson = _i1.ColumnString(
      'snapshotJson',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final GameRecipientSnapshotUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnString playerId;

  late final _i1.ColumnInt eventOffset;

  late final _i1.ColumnString snapshotJson;

  late final _i1.ColumnDateTime updatedAt;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GameRecipientSnapshot.t.matchId,
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
    eventOffset,
    snapshotJson,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'match') {
      return match;
    }
    return null;
  }
}

class GameRecipientSnapshotInclude extends _i1.IncludeObject {
  GameRecipientSnapshotInclude._({_i2.GameMatchInclude? match}) {
    _match = match;
  }

  _i2.GameMatchInclude? _match;

  @override
  Map<String, _i1.Include?> get includes => {'match': _match};

  @override
  _i1.Table<int?> get table => GameRecipientSnapshot.t;
}

class GameRecipientSnapshotIncludeList extends _i1.IncludeList {
  GameRecipientSnapshotIncludeList._({
    _i1.WhereExpressionBuilder<GameRecipientSnapshotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameRecipientSnapshot.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameRecipientSnapshot.t;
}

class GameRecipientSnapshotRepository {
  const GameRecipientSnapshotRepository._();

  final attachRow = const GameRecipientSnapshotAttachRowRepository._();

  /// Returns a list of [GameRecipientSnapshot]s matching the given query parameters.
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
  Future<List<GameRecipientSnapshot>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameRecipientSnapshotTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameRecipientSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameRecipientSnapshotTable>? orderByList,
    _i1.Transaction? transaction,
    GameRecipientSnapshotInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameRecipientSnapshot>(
      where: where?.call(GameRecipientSnapshot.t),
      orderBy: orderBy?.call(GameRecipientSnapshot.t),
      orderByList: orderByList?.call(GameRecipientSnapshot.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameRecipientSnapshot] matching the given query parameters.
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
  Future<GameRecipientSnapshot?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameRecipientSnapshotTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameRecipientSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameRecipientSnapshotTable>? orderByList,
    _i1.Transaction? transaction,
    GameRecipientSnapshotInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameRecipientSnapshot>(
      where: where?.call(GameRecipientSnapshot.t),
      orderBy: orderBy?.call(GameRecipientSnapshot.t),
      orderByList: orderByList?.call(GameRecipientSnapshot.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameRecipientSnapshot] by its [id] or null if no such row exists.
  Future<GameRecipientSnapshot?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameRecipientSnapshotInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameRecipientSnapshot>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameRecipientSnapshot]s in the list and returns the inserted rows.
  ///
  /// The returned [GameRecipientSnapshot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameRecipientSnapshot>> insert(
    _i1.DatabaseSession session,
    List<GameRecipientSnapshot> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameRecipientSnapshot>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameRecipientSnapshot] and returns the inserted row.
  ///
  /// The returned [GameRecipientSnapshot] will have its `id` field set.
  Future<GameRecipientSnapshot> insertRow(
    _i1.DatabaseSession session,
    GameRecipientSnapshot row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameRecipientSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameRecipientSnapshot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameRecipientSnapshot>> update(
    _i1.DatabaseSession session,
    List<GameRecipientSnapshot> rows, {
    _i1.ColumnSelections<GameRecipientSnapshotTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameRecipientSnapshot>(
      rows,
      columns: columns?.call(GameRecipientSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameRecipientSnapshot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameRecipientSnapshot> updateRow(
    _i1.DatabaseSession session,
    GameRecipientSnapshot row, {
    _i1.ColumnSelections<GameRecipientSnapshotTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameRecipientSnapshot>(
      row,
      columns: columns?.call(GameRecipientSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameRecipientSnapshot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameRecipientSnapshot?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameRecipientSnapshotUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameRecipientSnapshot>(
      id,
      columnValues: columnValues(GameRecipientSnapshot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameRecipientSnapshot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameRecipientSnapshot>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameRecipientSnapshotUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<GameRecipientSnapshotTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameRecipientSnapshotTable>? orderBy,
    _i1.OrderByListBuilder<GameRecipientSnapshotTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameRecipientSnapshot>(
      columnValues: columnValues(GameRecipientSnapshot.t.updateTable),
      where: where(GameRecipientSnapshot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameRecipientSnapshot.t),
      orderByList: orderByList?.call(GameRecipientSnapshot.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameRecipientSnapshot]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameRecipientSnapshot>> delete(
    _i1.DatabaseSession session,
    List<GameRecipientSnapshot> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameRecipientSnapshot>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameRecipientSnapshot].
  Future<GameRecipientSnapshot> deleteRow(
    _i1.DatabaseSession session,
    GameRecipientSnapshot row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameRecipientSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameRecipientSnapshot>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameRecipientSnapshotTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameRecipientSnapshot>(
      where: where(GameRecipientSnapshot.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameRecipientSnapshotTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameRecipientSnapshot>(
      where: where?.call(GameRecipientSnapshot.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameRecipientSnapshot] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameRecipientSnapshotTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameRecipientSnapshot>(
      where: where(GameRecipientSnapshot.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameRecipientSnapshotAttachRowRepository {
  const GameRecipientSnapshotAttachRowRepository._();

  /// Creates a relation between the given [GameRecipientSnapshot] and [GameMatch]
  /// by setting the [GameRecipientSnapshot]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GameRecipientSnapshot gameRecipientSnapshot,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gameRecipientSnapshot.id == null) {
      throw ArgumentError.notNull('gameRecipientSnapshot.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gameRecipientSnapshot = gameRecipientSnapshot.copyWith(
      matchId: match.id,
    );
    await session.db.updateRow<GameRecipientSnapshot>(
      $gameRecipientSnapshot,
      columns: [GameRecipientSnapshot.t.matchId],
      transaction: transaction,
    );
  }
}
