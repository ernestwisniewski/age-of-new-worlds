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
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i2;
import 'package:aonw_server/src/generated/protocol.dart' as _i3;

abstract class AonwAccount
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  AonwAccount._({
    this.id,
    required this.authUserId,
    this.authUser,
    required this.email,
    required this.displayName,
    required this.displayNameKey,
    required this.passwordHash,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AonwAccount({
    _i1.UuidValue? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    required String email,
    required String displayName,
    required String displayNameKey,
    required String passwordHash,
    DateTime? createdAt,
  }) = _AonwAccountImpl;

  factory AonwAccount.fromJson(Map<String, dynamic> jsonSerialization) {
    return AonwAccount(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      authUser: jsonSerialization['authUser'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AuthUser>(
              jsonSerialization['authUser'],
            ),
      email: jsonSerialization['email'] as String,
      displayName: jsonSerialization['displayName'] as String,
      displayNameKey: jsonSerialization['displayNameKey'] as String,
      passwordHash: jsonSerialization['passwordHash'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = AonwAccountTable();

  static const db = AonwAccountRepository._();

  @override
  _i1.UuidValue? id;

  _i1.UuidValue authUserId;

  _i2.AuthUser? authUser;

  String email;

  String displayName;

  String displayNameKey;

  String passwordHash;

  DateTime createdAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AonwAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AonwAccount copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? authUserId,
    _i2.AuthUser? authUser,
    String? email,
    String? displayName,
    String? displayNameKey,
    String? passwordHash,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AonwAccount',
      if (id != null) 'id': id?.toJson(),
      'authUserId': authUserId.toJson(),
      if (authUser != null) 'authUser': authUser?.toJson(),
      'email': email,
      'displayName': displayName,
      'displayNameKey': displayNameKey,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AonwAccountInclude include({_i2.AuthUserInclude? authUser}) {
    return AonwAccountInclude._(authUser: authUser);
  }

  static AonwAccountIncludeList includeList({
    _i1.WhereExpressionBuilder<AonwAccountTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AonwAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AonwAccountTable>? orderByList,
    AonwAccountInclude? include,
  }) {
    return AonwAccountIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AonwAccount.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AonwAccount.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AonwAccountImpl extends AonwAccount {
  _AonwAccountImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue authUserId,
    _i2.AuthUser? authUser,
    required String email,
    required String displayName,
    required String displayNameKey,
    required String passwordHash,
    DateTime? createdAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         authUser: authUser,
         email: email,
         displayName: displayName,
         displayNameKey: displayNameKey,
         passwordHash: passwordHash,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AonwAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AonwAccount copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    Object? authUser = _Undefined,
    String? email,
    String? displayName,
    String? displayNameKey,
    String? passwordHash,
    DateTime? createdAt,
  }) {
    return AonwAccount(
      id: id is _i1.UuidValue? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      authUser: authUser is _i2.AuthUser?
          ? authUser
          : this.authUser?.copyWith(),
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      displayNameKey: displayNameKey ?? this.displayNameKey,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AonwAccountUpdateTable extends _i1.UpdateTable<AonwAccountTable> {
  AonwAccountUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<String, String> email(String value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<String, String> displayNameKey(String value) =>
      _i1.ColumnValue(
        table.displayNameKey,
        value,
      );

  _i1.ColumnValue<String, String> passwordHash(String value) => _i1.ColumnValue(
    table.passwordHash,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class AonwAccountTable extends _i1.Table<_i1.UuidValue?> {
  AonwAccountTable({super.tableRelation}) : super(tableName: 'aonw_account') {
    updateTable = AonwAccountUpdateTable(this);
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    displayNameKey = _i1.ColumnString(
      'displayNameKey',
      this,
    );
    passwordHash = _i1.ColumnString(
      'passwordHash',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final AonwAccountUpdateTable updateTable;

  late final _i1.ColumnUuid authUserId;

  _i2.AuthUserTable? _authUser;

  late final _i1.ColumnString email;

  late final _i1.ColumnString displayName;

  late final _i1.ColumnString displayNameKey;

  late final _i1.ColumnString passwordHash;

  late final _i1.ColumnDateTime createdAt;

  _i2.AuthUserTable get authUser {
    if (_authUser != null) return _authUser!;
    _authUser = _i1.createRelationTable(
      relationFieldName: 'authUser',
      field: AonwAccount.t.authUserId,
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
    authUserId,
    email,
    displayName,
    displayNameKey,
    passwordHash,
    createdAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'authUser') {
      return authUser;
    }
    return null;
  }
}

class AonwAccountInclude extends _i1.IncludeObject {
  AonwAccountInclude._({_i2.AuthUserInclude? authUser}) {
    _authUser = authUser;
  }

  _i2.AuthUserInclude? _authUser;

  @override
  Map<String, _i1.Include?> get includes => {'authUser': _authUser};

  @override
  _i1.Table<_i1.UuidValue?> get table => AonwAccount.t;
}

class AonwAccountIncludeList extends _i1.IncludeList {
  AonwAccountIncludeList._({
    _i1.WhereExpressionBuilder<AonwAccountTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AonwAccount.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => AonwAccount.t;
}

class AonwAccountRepository {
  const AonwAccountRepository._();

  final attachRow = const AonwAccountAttachRowRepository._();

  /// Returns a list of [AonwAccount]s matching the given query parameters.
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
  Future<List<AonwAccount>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AonwAccountTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AonwAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AonwAccountTable>? orderByList,
    _i1.Transaction? transaction,
    AonwAccountInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AonwAccount>(
      where: where?.call(AonwAccount.t),
      orderBy: orderBy?.call(AonwAccount.t),
      orderByList: orderByList?.call(AonwAccount.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AonwAccount] matching the given query parameters.
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
  Future<AonwAccount?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AonwAccountTable>? where,
    int? offset,
    _i1.OrderByBuilder<AonwAccountTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AonwAccountTable>? orderByList,
    _i1.Transaction? transaction,
    AonwAccountInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AonwAccount>(
      where: where?.call(AonwAccount.t),
      orderBy: orderBy?.call(AonwAccount.t),
      orderByList: orderByList?.call(AonwAccount.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AonwAccount] by its [id] or null if no such row exists.
  Future<AonwAccount?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    AonwAccountInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AonwAccount>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AonwAccount]s in the list and returns the inserted rows.
  ///
  /// The returned [AonwAccount]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<AonwAccount>> insert(
    _i1.DatabaseSession session,
    List<AonwAccount> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<AonwAccount>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [AonwAccount] and returns the inserted row.
  ///
  /// The returned [AonwAccount] will have its `id` field set.
  Future<AonwAccount> insertRow(
    _i1.DatabaseSession session,
    AonwAccount row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AonwAccount>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AonwAccount]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AonwAccount>> update(
    _i1.DatabaseSession session,
    List<AonwAccount> rows, {
    _i1.ColumnSelections<AonwAccountTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AonwAccount>(
      rows,
      columns: columns?.call(AonwAccount.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AonwAccount]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AonwAccount> updateRow(
    _i1.DatabaseSession session,
    AonwAccount row, {
    _i1.ColumnSelections<AonwAccountTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AonwAccount>(
      row,
      columns: columns?.call(AonwAccount.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AonwAccount] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AonwAccount?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<AonwAccountUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AonwAccount>(
      id,
      columnValues: columnValues(AonwAccount.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AonwAccount]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AonwAccount>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AonwAccountUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AonwAccountTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AonwAccountTable>? orderBy,
    _i1.OrderByListBuilder<AonwAccountTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AonwAccount>(
      columnValues: columnValues(AonwAccount.t.updateTable),
      where: where(AonwAccount.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AonwAccount.t),
      orderByList: orderByList?.call(AonwAccount.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AonwAccount]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AonwAccount>> delete(
    _i1.DatabaseSession session,
    List<AonwAccount> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AonwAccount>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AonwAccount].
  Future<AonwAccount> deleteRow(
    _i1.DatabaseSession session,
    AonwAccount row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AonwAccount>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AonwAccount>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AonwAccountTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AonwAccount>(
      where: where(AonwAccount.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AonwAccountTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AonwAccount>(
      where: where?.call(AonwAccount.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AonwAccount] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AonwAccountTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AonwAccount>(
      where: where(AonwAccount.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class AonwAccountAttachRowRepository {
  const AonwAccountAttachRowRepository._();

  /// Creates a relation between the given [AonwAccount] and [AuthUser]
  /// by setting the [AonwAccount]'s foreign key `authUserId` to refer to the [AuthUser].
  Future<void> authUser(
    _i1.DatabaseSession session,
    AonwAccount aonwAccount,
    _i2.AuthUser authUser, {
    _i1.Transaction? transaction,
  }) async {
    if (aonwAccount.id == null) {
      throw ArgumentError.notNull('aonwAccount.id');
    }
    if (authUser.id == null) {
      throw ArgumentError.notNull('authUser.id');
    }

    var $aonwAccount = aonwAccount.copyWith(authUserId: authUser.id);
    await session.db.updateRow<AonwAccount>(
      $aonwAccount,
      columns: [AonwAccount.t.authUserId],
      transaction: transaction,
    );
  }
}
