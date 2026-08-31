/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i2;
import 'package:aonw_server/src/generated/protocol.dart' as _i3;

abstract class SteamAccount
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  SteamAccount._({
    this.id,
    required this.steamId,
    required this.authUserId,
    this.authUser,
    DateTime? createdAt,
    required this.lastSeenAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SteamAccount({
    _i1.UuidValue? id,
    required String steamId,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    DateTime? createdAt,
    required DateTime lastSeenAt,
  }) = _SteamAccountImpl;

  factory SteamAccount.fromJson(Map<String, dynamic> jsonSerialization) {
    return SteamAccount(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      steamId: jsonSerialization['steamId'] as String,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AuthUser>(
              jsonSerialization['authUser'],
            ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      lastSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
    );
  }

  static final t = SteamAccountTable();

  static const db = SteamAccountRepository._();

  @override
  _i1.UuidValue? id;

  String steamId;

  _i1.UuidValue authUserId;

  _i2.AuthUser? authUser;

  DateTime createdAt;

  DateTime lastSeenAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [SteamAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SteamAccount copyWith({
    _i1.UuidValue? id,
    String? steamId,
    _i1.UuidValue? authUserId,
    _i2.AuthUser? authUser,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SteamAccount',
      if (id != null) 'id': id?.toJson(),
      'steamId': steamId,
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'createdAt': createdAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SteamAccountInclude include({_i2.AuthUserInclude? authUser}) {
    return SteamAccountInclude._(authUser: authUser);
  }

  static SteamAccountIncludeList includeList({
    _i1.WhereExpressionBuilder<SteamAccountTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SteamAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SteamAccountTable>? orderByList,
    SteamAccountInclude? include,
  }) {
    return SteamAccountIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SteamAccount.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SteamAccount.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SteamAccountImpl extends SteamAccount {
  _SteamAccountImpl({
    _i1.UuidValue? id,
    required String steamId,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    DateTime? createdAt,
    required DateTime lastSeenAt,
  }) : super._(
         id: id,
         steamId: steamId,
         authUserId: authUserId,
         authUser: authUser,
         createdAt: createdAt,
         lastSeenAt: lastSeenAt,
       );

  /// Returns a shallow copy of this [SteamAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SteamAccount copyWith({
    Object? id = _Undefined,
    String? steamId,
    _i1.UuidValue? authUserId,
    Object? authUser = _Undefined,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) {
    return SteamAccount(
      id: id is _i1.UuidValue? ? id : this.id,
      steamId: steamId ?? this.steamId,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _i2.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

class SteamAccountUpdateTable extends _i1.UpdateTable<SteamAccountTable> {
  SteamAccountUpdateTable(super.table);

  _i1.ColumnValue<String, String> steamId(String value) => _i1.ColumnValue(
    table.steamId,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastSeenAt(DateTime value) =>
      _i1.ColumnValue(
        table.lastSeenAt,
        value,
      );
}

class SteamAccountTable extends _i1.Table<_i1.UuidValue?> {
  SteamAccountTable({super.tableRelation})
    : super(tableName: 'aonw_steam_account') {
    updateTable = SteamAccountUpdateTable(this);
    steamId = _i1.ColumnString(
      'steamId',
      this,
    );
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    lastSeenAt = _i1.ColumnDateTime(
      'lastSeenAt',
      this,
    );
  }

  late final SteamAccountUpdateTable updateTable;

  late final _i1.ColumnString steamId;

  late final _i1.ColumnUuid authUserId;

  _i2.AuthUserTable? _authUser;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime lastSeenAt;

  _i2.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _i1.createRelationTable(
      relationFieldName: 'authUser',
      field: SteamAccount.t.authUserId,
      foreignField: _i2.AuthUser.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.AuthUserTable(tableRelation: foreignTableRelation),
    );
    return _authUser!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    steamId,
    authUserId,
    createdAt,
    lastSeenAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class SteamAccountInclude extends _i1.IncludeObject {
  SteamAccountInclude._({_i2.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _i2.AuthUserInclude? _authUser;

  @override
  Map<String, _i1.Include?> get includes => {'authUser': _authUser};

  @override
  _i1.Table<_i1.UuidValue?> get table => SteamAccount.t;
}

class SteamAccountIncludeList extends _i1.IncludeList {
  SteamAccountIncludeList._({
    _i1.WhereExpressionBuilder<SteamAccountTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SteamAccount.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SteamAccount.t;
}

class SteamAccountRepository {
  const SteamAccountRepository._();

  final attachRow = const SteamAccountAttachRowRepository._();

  /// Returns a list of [SteamAccount]s matching the given query parameters.
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
  Future<List<SteamAccount>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SteamAccountTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SteamAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SteamAccountTable>? orderByList,
    _i1.Transaction? transaction,
    SteamAccountInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SteamAccount>(
      where: where?.call(SteamAccount.t),
      orderBy: orderBy?.call(SteamAccount.t),
      orderByList: orderByList?.call(SteamAccount.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SteamAccount] matching the given query parameters.
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
  Future<SteamAccount?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SteamAccountTable>? where,
    int? offset,
    _i1.OrderByBuilder<SteamAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SteamAccountTable>? orderByList,
    _i1.Transaction? transaction,
    SteamAccountInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SteamAccount>(
      where: where?.call(SteamAccount.t),
      orderBy: orderBy?.call(SteamAccount.t),
      orderByList: orderByList?.call(SteamAccount.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SteamAccount] by its [id] or null if no such row exists.
  Future<SteamAccount?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    SteamAccountInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SteamAccount>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SteamAccount]s in the list and returns the inserted rows.
  ///
  /// The returned [SteamAccount]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SteamAccount>> insert(
    _i1.DatabaseSession session,
    List<SteamAccount> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SteamAccount>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SteamAccount] and returns the inserted row.
  ///
  /// The returned [SteamAccount] will have its `id` field set.
  Future<SteamAccount> insertRow(
    _i1.DatabaseSession session,
    SteamAccount row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SteamAccount>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SteamAccount]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SteamAccount>> update(
    _i1.DatabaseSession session,
    List<SteamAccount> rows, {
    _i1.ColumnSelections<SteamAccountTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SteamAccount>(
      rows,
      columns: columns?.call(SteamAccount.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SteamAccount]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SteamAccount> updateRow(
    _i1.DatabaseSession session,
    SteamAccount row, {
    _i1.ColumnSelections<SteamAccountTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SteamAccount>(
      row,
      columns: columns?.call(SteamAccount.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SteamAccount] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SteamAccount?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<SteamAccountUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SteamAccount>(
      id,
      columnValues: columnValues(SteamAccount.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SteamAccount]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SteamAccount>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SteamAccountUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SteamAccountTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SteamAccountTable>? orderBy,
    _i1.OrderByListBuilder<SteamAccountTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SteamAccount>(
      columnValues: columnValues(SteamAccount.t.updateTable),
      where: where(SteamAccount.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SteamAccount.t),
      orderByList: orderByList?.call(SteamAccount.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SteamAccount]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SteamAccount>> delete(
    _i1.DatabaseSession session,
    List<SteamAccount> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SteamAccount>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SteamAccount].
  Future<SteamAccount> deleteRow(
    _i1.DatabaseSession session,
    SteamAccount row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SteamAccount>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SteamAccount>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SteamAccountTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SteamAccount>(
      where: where(SteamAccount.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SteamAccountTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SteamAccount>(
      where: where?.call(SteamAccount.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SteamAccount] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SteamAccountTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SteamAccount>(
      where: where(SteamAccount.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SteamAccountAttachRowRepository {
  const SteamAccountAttachRowRepository._();

  /// Creates a relation between the given [SteamAccount] and [AuthUser]
  /// by setting the [SteamAccount]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _i1.DatabaseSession session,
    SteamAccount steamAccount,
    _i2.AuthUser authUser, {
    _i1.Transaction? transaction,
  }) async {
    if (steamAccount.id == null) {
      throw ArgumentError.notNull('steamAccount.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $steamAccount = steamAccount.copyWith(authUserId: authUser.id);
    await session.db.updateRow<SteamAccount>(
      $steamAccount,
      columns: [SteamAccount.t.authUserId],
      transaction: transaction,
    );
  }
}
