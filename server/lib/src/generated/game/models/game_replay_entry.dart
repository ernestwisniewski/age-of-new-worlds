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

abstract class GameReplayEntry
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameReplayEntry._({
    this.id,
    required this.matchId,
    this.match,
    required this.revision,
    this.actorPlayerId,
    required this.commandKind,
    required this.commandJson,
    required this.stateDigest,
    required this.initialEventOffset,
    required this.finalEventOffset,
  });

  factory GameReplayEntry({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int revision,
    String? actorPlayerId,
    required String commandKind,
    required String commandJson,
    required String stateDigest,
    required int initialEventOffset,
    required int finalEventOffset,
  }) = _GameReplayEntryImpl;

  factory GameReplayEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameReplayEntry(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      revision: jsonSerialization['revision'] as int,
      actorPlayerId: jsonSerialization['actorPlayerId'] as String?,
      commandKind: jsonSerialization['commandKind'] as String,
      commandJson: jsonSerialization['commandJson'] as String,
      stateDigest: jsonSerialization['stateDigest'] as String,
      initialEventOffset: jsonSerialization['initialEventOffset'] as int,
      finalEventOffset: jsonSerialization['finalEventOffset'] as int,
    );
  }

  static final t = GameReplayEntryTable();

  static const db = GameReplayEntryRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  int revision;

  String? actorPlayerId;

  String commandKind;

  String commandJson;

  String stateDigest;

  int initialEventOffset;

  int finalEventOffset;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameReplayEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameReplayEntry copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    int? revision,
    String? actorPlayerId,
    String? commandKind,
    String? commandJson,
    String? stateDigest,
    int? initialEventOffset,
    int? finalEventOffset,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameReplayEntry',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'revision': revision,
      if (actorPlayerId != null) 'actorPlayerId': actorPlayerId,
      'commandKind': commandKind,
      'commandJson': commandJson,
      'stateDigest': stateDigest,
      'initialEventOffset': initialEventOffset,
      'finalEventOffset': finalEventOffset,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static GameReplayEntryInclude include({_i2.GameMatchInclude? match}) {
    return GameReplayEntryInclude._(match: match);
  }

  static GameReplayEntryIncludeList includeList({
    _i1.WhereExpressionBuilder<GameReplayEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameReplayEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameReplayEntryTable>? orderByList,
    GameReplayEntryInclude? include,
  }) {
    return GameReplayEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameReplayEntry.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameReplayEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameReplayEntryImpl extends GameReplayEntry {
  _GameReplayEntryImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int revision,
    String? actorPlayerId,
    required String commandKind,
    required String commandJson,
    required String stateDigest,
    required int initialEventOffset,
    required int finalEventOffset,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         revision: revision,
         actorPlayerId: actorPlayerId,
         commandKind: commandKind,
         commandJson: commandJson,
         stateDigest: stateDigest,
         initialEventOffset: initialEventOffset,
         finalEventOffset: finalEventOffset,
       );

  /// Returns a shallow copy of this [GameReplayEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameReplayEntry copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    int? revision,
    Object? actorPlayerId = _Undefined,
    String? commandKind,
    String? commandJson,
    String? stateDigest,
    int? initialEventOffset,
    int? finalEventOffset,
  }) {
    return GameReplayEntry(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      revision: revision ?? this.revision,
      actorPlayerId: actorPlayerId is String?
          ? actorPlayerId
          : this.actorPlayerId,
      commandKind: commandKind ?? this.commandKind,
      commandJson: commandJson ?? this.commandJson,
      stateDigest: stateDigest ?? this.stateDigest,
      initialEventOffset: initialEventOffset ?? this.initialEventOffset,
      finalEventOffset: finalEventOffset ?? this.finalEventOffset,
    );
  }
}

class GameReplayEntryUpdateTable extends _i1.UpdateTable<GameReplayEntryTable> {
  GameReplayEntryUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) => _i1.ColumnValue(
    table.matchId,
    value,
  );

  _i1.ColumnValue<int, int> revision(int value) => _i1.ColumnValue(
    table.revision,
    value,
  );

  _i1.ColumnValue<String, String> actorPlayerId(String? value) =>
      _i1.ColumnValue(
        table.actorPlayerId,
        value,
      );

  _i1.ColumnValue<String, String> commandKind(String value) => _i1.ColumnValue(
    table.commandKind,
    value,
  );

  _i1.ColumnValue<String, String> commandJson(String value) => _i1.ColumnValue(
    table.commandJson,
    value,
  );

  _i1.ColumnValue<String, String> stateDigest(String value) => _i1.ColumnValue(
    table.stateDigest,
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
}

class GameReplayEntryTable extends _i1.Table<int?> {
  GameReplayEntryTable({super.tableRelation})
    : super(tableName: 'aonw_game_replay_entry') {
    updateTable = GameReplayEntryUpdateTable(this);
    matchId = _i1.ColumnInt(
      'matchId',
      this,
    );
    revision = _i1.ColumnInt(
      'revision',
      this,
    );
    actorPlayerId = _i1.ColumnString(
      'actorPlayerId',
      this,
    );
    commandKind = _i1.ColumnString(
      'commandKind',
      this,
    );
    commandJson = _i1.ColumnString(
      'commandJson',
      this,
    );
    stateDigest = _i1.ColumnString(
      'stateDigest',
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
  }

  late final GameReplayEntryUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnInt revision;

  late final _i1.ColumnString actorPlayerId;

  late final _i1.ColumnString commandKind;

  late final _i1.ColumnString commandJson;

  late final _i1.ColumnString stateDigest;

  late final _i1.ColumnInt initialEventOffset;

  late final _i1.ColumnInt finalEventOffset;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GameReplayEntry.t.matchId,
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
    revision,
    actorPlayerId,
    commandKind,
    commandJson,
    stateDigest,
    initialEventOffset,
    finalEventOffset,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'match') {
      return match;
    }
    return null;
  }
}

class GameReplayEntryInclude extends _i1.IncludeObject {
  GameReplayEntryInclude._({_i2.GameMatchInclude? match}) {
    _match = match;
  }

  _i2.GameMatchInclude? _match;

  @override
  Map<String, _i1.Include?> get includes => {'match': _match};

  @override
  _i1.Table<int?> get table => GameReplayEntry.t;
}

class GameReplayEntryIncludeList extends _i1.IncludeList {
  GameReplayEntryIncludeList._({
    _i1.WhereExpressionBuilder<GameReplayEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameReplayEntry.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameReplayEntry.t;
}

class GameReplayEntryRepository {
  const GameReplayEntryRepository._();

  final attachRow = const GameReplayEntryAttachRowRepository._();

  /// Returns a list of [GameReplayEntry]s matching the given query parameters.
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
  Future<List<GameReplayEntry>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameReplayEntryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameReplayEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameReplayEntryTable>? orderByList,
    _i1.Transaction? transaction,
    GameReplayEntryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameReplayEntry>(
      where: where?.call(GameReplayEntry.t),
      orderBy: orderBy?.call(GameReplayEntry.t),
      orderByList: orderByList?.call(GameReplayEntry.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameReplayEntry] matching the given query parameters.
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
  Future<GameReplayEntry?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameReplayEntryTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameReplayEntryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameReplayEntryTable>? orderByList,
    _i1.Transaction? transaction,
    GameReplayEntryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameReplayEntry>(
      where: where?.call(GameReplayEntry.t),
      orderBy: orderBy?.call(GameReplayEntry.t),
      orderByList: orderByList?.call(GameReplayEntry.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameReplayEntry] by its [id] or null if no such row exists.
  Future<GameReplayEntry?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameReplayEntryInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameReplayEntry>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameReplayEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [GameReplayEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameReplayEntry>> insert(
    _i1.DatabaseSession session,
    List<GameReplayEntry> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameReplayEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameReplayEntry] and returns the inserted row.
  ///
  /// The returned [GameReplayEntry] will have its `id` field set.
  Future<GameReplayEntry> insertRow(
    _i1.DatabaseSession session,
    GameReplayEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameReplayEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameReplayEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameReplayEntry>> update(
    _i1.DatabaseSession session,
    List<GameReplayEntry> rows, {
    _i1.ColumnSelections<GameReplayEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameReplayEntry>(
      rows,
      columns: columns?.call(GameReplayEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameReplayEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameReplayEntry> updateRow(
    _i1.DatabaseSession session,
    GameReplayEntry row, {
    _i1.ColumnSelections<GameReplayEntryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameReplayEntry>(
      row,
      columns: columns?.call(GameReplayEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameReplayEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameReplayEntry?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameReplayEntryUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameReplayEntry>(
      id,
      columnValues: columnValues(GameReplayEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameReplayEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameReplayEntry>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameReplayEntryUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<GameReplayEntryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameReplayEntryTable>? orderBy,
    _i1.OrderByListBuilder<GameReplayEntryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameReplayEntry>(
      columnValues: columnValues(GameReplayEntry.t.updateTable),
      where: where(GameReplayEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameReplayEntry.t),
      orderByList: orderByList?.call(GameReplayEntry.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameReplayEntry]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameReplayEntry>> delete(
    _i1.DatabaseSession session,
    List<GameReplayEntry> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameReplayEntry>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameReplayEntry].
  Future<GameReplayEntry> deleteRow(
    _i1.DatabaseSession session,
    GameReplayEntry row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameReplayEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameReplayEntry>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameReplayEntryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameReplayEntry>(
      where: where(GameReplayEntry.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameReplayEntryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameReplayEntry>(
      where: where?.call(GameReplayEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameReplayEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameReplayEntryTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameReplayEntry>(
      where: where(GameReplayEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameReplayEntryAttachRowRepository {
  const GameReplayEntryAttachRowRepository._();

  /// Creates a relation between the given [GameReplayEntry] and [GameMatch]
  /// by setting the [GameReplayEntry]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GameReplayEntry gameReplayEntry,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gameReplayEntry.id == null) {
      throw ArgumentError.notNull('gameReplayEntry.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gameReplayEntry = gameReplayEntry.copyWith(matchId: match.id);
    await session.db.updateRow<GameReplayEntry>(
      $gameReplayEntry,
      columns: [GameReplayEntry.t.matchId],
      transaction: transaction,
    );
  }
}
