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

abstract class GameEvent
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameEvent._({
    this.id,
    required this.matchId,
    this.match,
    required this.offset,
    this.eventJson,
    required this.createdAt,
  });

  factory GameEvent({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int offset,
    String? eventJson,
    required DateTime createdAt,
  }) = _GameEventImpl;

  factory GameEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameEvent(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      offset: jsonSerialization['offset'] as int,
      eventJson: jsonSerialization['eventJson'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = GameEventTable();

  static const db = GameEventRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  int offset;

  String? eventJson;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameEvent copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    int? offset,
    String? eventJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameEvent',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'offset': offset,
      if (eventJson != null) 'eventJson': eventJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameEvent',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJsonForProtocol(),
      'offset': offset,
      'createdAt': createdAt.toJson(),
    };
  }

  static GameEventInclude include({_i2.GameMatchInclude? match}) {
    return GameEventInclude._(match: match);
  }

  static GameEventIncludeList includeList({
    _i1.WhereExpressionBuilder<GameEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameEventTable>? orderByList,
    GameEventInclude? include,
  }) {
    return GameEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameEvent.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameEventImpl extends GameEvent {
  _GameEventImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int offset,
    String? eventJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         offset: offset,
         eventJson: eventJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [GameEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameEvent copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    int? offset,
    Object? eventJson = _Undefined,
    DateTime? createdAt,
  }) {
    return GameEvent(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      offset: offset ?? this.offset,
      eventJson: eventJson is String? ? eventJson : this.eventJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GameEventUpdateTable extends _i1.UpdateTable<GameEventTable> {
  GameEventUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) => _i1.ColumnValue(
    table.matchId,
    value,
  );

  _i1.ColumnValue<int, int> offset(int value) => _i1.ColumnValue(
    table.offset,
    value,
  );

  _i1.ColumnValue<String, String> eventJson(String? value) => _i1.ColumnValue(
    table.eventJson,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class GameEventTable extends _i1.Table<int?> {
  GameEventTable({super.tableRelation}) : super(tableName: 'aonw_game_event') {
    updateTable = GameEventUpdateTable(this);
    matchId = _i1.ColumnInt(
      'matchId',
      this,
    );
    offset = _i1.ColumnInt(
      'offset',
      this,
    );
    eventJson = _i1.ColumnString(
      'eventJson',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final GameEventUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnInt offset;

  late final _i1.ColumnString eventJson;

  late final _i1.ColumnDateTime createdAt;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GameEvent.t.matchId,
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
    offset,
    eventJson,
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

class GameEventInclude extends _i1.IncludeObject {
  GameEventInclude._({_i2.GameMatchInclude? match}) {
    _match = match;
  }

  _i2.GameMatchInclude? _match;

  @override
  Map<String, _i1.Include?> get includes => {'match': _match};

  @override
  _i1.Table<int?> get table => GameEvent.t;
}

class GameEventIncludeList extends _i1.IncludeList {
  GameEventIncludeList._({
    _i1.WhereExpressionBuilder<GameEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameEvent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameEvent.t;
}

class GameEventRepository {
  const GameEventRepository._();

  final attachRow = const GameEventAttachRowRepository._();

  /// Returns a list of [GameEvent]s matching the given query parameters.
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
  Future<List<GameEvent>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameEventTable>? orderByList,
    _i1.Transaction? transaction,
    GameEventInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameEvent>(
      where: where?.call(GameEvent.t),
      orderBy: orderBy?.call(GameEvent.t),
      orderByList: orderByList?.call(GameEvent.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameEvent] matching the given query parameters.
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
  Future<GameEvent?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameEventTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameEventTable>? orderByList,
    _i1.Transaction? transaction,
    GameEventInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameEvent>(
      where: where?.call(GameEvent.t),
      orderBy: orderBy?.call(GameEvent.t),
      orderByList: orderByList?.call(GameEvent.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameEvent] by its [id] or null if no such row exists.
  Future<GameEvent?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameEventInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameEvent>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [GameEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameEvent>> insert(
    _i1.DatabaseSession session,
    List<GameEvent> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameEvent] and returns the inserted row.
  ///
  /// The returned [GameEvent] will have its `id` field set.
  Future<GameEvent> insertRow(
    _i1.DatabaseSession session,
    GameEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameEvent>> update(
    _i1.DatabaseSession session,
    List<GameEvent> rows, {
    _i1.ColumnSelections<GameEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameEvent>(
      rows,
      columns: columns?.call(GameEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameEvent> updateRow(
    _i1.DatabaseSession session,
    GameEvent row, {
    _i1.ColumnSelections<GameEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameEvent>(
      row,
      columns: columns?.call(GameEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameEvent?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameEventUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameEvent>(
      id,
      columnValues: columnValues(GameEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameEvent>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameEventUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<GameEventTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameEventTable>? orderBy,
    _i1.OrderByListBuilder<GameEventTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameEvent>(
      columnValues: columnValues(GameEvent.t.updateTable),
      where: where(GameEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameEvent.t),
      orderByList: orderByList?.call(GameEvent.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameEvent]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameEvent>> delete(
    _i1.DatabaseSession session,
    List<GameEvent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameEvent>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameEvent].
  Future<GameEvent> deleteRow(
    _i1.DatabaseSession session,
    GameEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameEvent>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameEventTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameEvent>(
      where: where(GameEvent.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameEventTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameEvent>(
      where: where?.call(GameEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameEventTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameEvent>(
      where: where(GameEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameEventAttachRowRepository {
  const GameEventAttachRowRepository._();

  /// Creates a relation between the given [GameEvent] and [GameMatch]
  /// by setting the [GameEvent]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GameEvent gameEvent,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gameEvent.id == null) {
      throw ArgumentError.notNull('gameEvent.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gameEvent = gameEvent.copyWith(matchId: match.id);
    await session.db.updateRow<GameEvent>(
      $gameEvent,
      columns: [GameEvent.t.matchId],
      transaction: transaction,
    );
  }
}
