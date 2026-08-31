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

abstract class SteamAuthRequest
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  SteamAuthRequest._({
    this.id,
    required this.requestId,
    required this.status,
    this.authUserId,
    this.steamId,
    this.error,
    DateTime? createdAt,
    required this.expiresAt,
    this.completedAt,
    this.consumedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SteamAuthRequest({
    _i1.UuidValue? id,
    required String requestId,
    required String status,
    _i1.UuidValue? authUserId,
    String? steamId,
    String? error,
    DateTime? createdAt,
    required DateTime expiresAt,
    DateTime? completedAt,
    DateTime? consumedAt,
  }) = _SteamAuthRequestImpl;

  factory SteamAuthRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return SteamAuthRequest(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requestId: jsonSerialization['requestId'] as String,
      status: jsonSerialization['status'] as String,
      authUserId: jsonSerialization['authUserId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['authUserId'],
            ),
      steamId: jsonSerialization['steamId'] as String?,
      error: jsonSerialization['error'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      consumedAt: jsonSerialization['consumedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['consumedAt']),
    );
  }

  static final t = SteamAuthRequestTable();

  static const db = SteamAuthRequestRepository._();

  @override
  _i1.UuidValue? id;

  String requestId;

  String status;

  _i1.UuidValue? authUserId;

  String? steamId;

  String? error;

  DateTime createdAt;

  DateTime expiresAt;

  DateTime? completedAt;

  DateTime? consumedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [SteamAuthRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SteamAuthRequest copyWith({
    _i1.UuidValue? id,
    String? requestId,
    String? status,
    _i1.UuidValue? authUserId,
    String? steamId,
    String? error,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    DateTime? consumedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SteamAuthRequest',
      if (id != null) 'id': id?.toJson(),
      'requestId': requestId,
      'status': status,
      if (authUserId != null) 'authUserId': authUserId?.toJson(),
      if (steamId != null) 'steamId': steamId,
      if (error != null) 'error': error,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      if (consumedAt != null) 'consumedAt': consumedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SteamAuthRequestInclude include() {
    return SteamAuthRequestInclude._();
  }

  static SteamAuthRequestIncludeList includeList({
    _i1.WhereExpressionBuilder<SteamAuthRequestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SteamAuthRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SteamAuthRequestTable>? orderByList,
    SteamAuthRequestInclude? include,
  }) {
    return SteamAuthRequestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SteamAuthRequest.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SteamAuthRequest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SteamAuthRequestImpl extends SteamAuthRequest {
  _SteamAuthRequestImpl({
    _i1.UuidValue? id,
    required String requestId,
    required String status,
    _i1.UuidValue? authUserId,
    String? steamId,
    String? error,
    DateTime? createdAt,
    required DateTime expiresAt,
    DateTime? completedAt,
    DateTime? consumedAt,
  }) : super._(
         id: id,
         requestId: requestId,
         status: status,
         authUserId: authUserId,
         steamId: steamId,
         error: error,
         createdAt: createdAt,
         expiresAt: expiresAt,
         completedAt: completedAt,
         consumedAt: consumedAt,
       );

  /// Returns a shallow copy of this [SteamAuthRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SteamAuthRequest copyWith({
    Object? id = _Undefined,
    String? requestId,
    String? status,
    Object? authUserId = _Undefined,
    Object? steamId = _Undefined,
    Object? error = _Undefined,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? completedAt = _Undefined,
    Object? consumedAt = _Undefined,
  }) {
    return SteamAuthRequest(
      id: id is _i1.UuidValue? ? id : this.id,
      requestId: requestId ?? this.requestId,
      status: status ?? this.status,
      authUserId: authUserId is _i1.UuidValue? ? authUserId : this.authUserId,
      steamId: steamId is String? ? steamId : this.steamId,
      error: error is String? ? error : this.error,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      consumedAt: consumedAt is DateTime? ? consumedAt : this.consumedAt,
    );
  }
}

class SteamAuthRequestUpdateTable
    extends _i1.UpdateTable<SteamAuthRequestTable> {
  SteamAuthRequestUpdateTable(super.table);

  _i1.ColumnValue<String, String> requestId(String value) => _i1.ColumnValue(
    table.requestId,
    value,
  );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<String, String> steamId(String? value) => _i1.ColumnValue(
    table.steamId,
    value,
  );

  _i1.ColumnValue<String, String> error(String? value) => _i1.ColumnValue(
    table.error,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.completedAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> consumedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.consumedAt,
        value,
      );
}

class SteamAuthRequestTable extends _i1.Table<_i1.UuidValue?> {
  SteamAuthRequestTable({super.tableRelation})
    : super(tableName: 'aonw_steam_auth_request') {
    updateTable = SteamAuthRequestUpdateTable(this);
    requestId = _i1.ColumnString(
      'requestId',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    steamId = _i1.ColumnString(
      'steamId',
      this,
    );
    error = _i1.ColumnString(
      'error',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
    completedAt = _i1.ColumnDateTime(
      'completedAt',
      this,
    );
    consumedAt = _i1.ColumnDateTime(
      'consumedAt',
      this,
    );
  }

  late final SteamAuthRequestUpdateTable updateTable;

  late final _i1.ColumnString requestId;

  late final _i1.ColumnString status;

  late final _i1.ColumnUuid authUserId;

  late final _i1.ColumnString steamId;

  late final _i1.ColumnString error;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime expiresAt;

  late final _i1.ColumnDateTime completedAt;

  late final _i1.ColumnDateTime consumedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    requestId,
    status,
    authUserId,
    steamId,
    error,
    createdAt,
    expiresAt,
    completedAt,
    consumedAt,
  ];
}

class SteamAuthRequestInclude extends _i1.IncludeObject {
  SteamAuthRequestInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SteamAuthRequest.t;
}

class SteamAuthRequestIncludeList extends _i1.IncludeList {
  SteamAuthRequestIncludeList._({
    _i1.WhereExpressionBuilder<SteamAuthRequestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SteamAuthRequest.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => SteamAuthRequest.t;
}

class SteamAuthRequestRepository {
  const SteamAuthRequestRepository._();

  /// Returns a list of [SteamAuthRequest]s matching the given query parameters.
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
  Future<List<SteamAuthRequest>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SteamAuthRequestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SteamAuthRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SteamAuthRequestTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SteamAuthRequest>(
      where: where?.call(SteamAuthRequest.t),
      orderBy: orderBy?.call(SteamAuthRequest.t),
      orderByList: orderByList?.call(SteamAuthRequest.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SteamAuthRequest] matching the given query parameters.
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
  Future<SteamAuthRequest?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SteamAuthRequestTable>? where,
    int? offset,
    _i1.OrderByBuilder<SteamAuthRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SteamAuthRequestTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SteamAuthRequest>(
      where: where?.call(SteamAuthRequest.t),
      orderBy: orderBy?.call(SteamAuthRequest.t),
      orderByList: orderByList?.call(SteamAuthRequest.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SteamAuthRequest] by its [id] or null if no such row exists.
  Future<SteamAuthRequest?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SteamAuthRequest>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SteamAuthRequest]s in the list and returns the inserted rows.
  ///
  /// The returned [SteamAuthRequest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SteamAuthRequest>> insert(
    _i1.DatabaseSession session,
    List<SteamAuthRequest> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SteamAuthRequest>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SteamAuthRequest] and returns the inserted row.
  ///
  /// The returned [SteamAuthRequest] will have its `id` field set.
  Future<SteamAuthRequest> insertRow(
    _i1.DatabaseSession session,
    SteamAuthRequest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SteamAuthRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SteamAuthRequest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SteamAuthRequest>> update(
    _i1.DatabaseSession session,
    List<SteamAuthRequest> rows, {
    _i1.ColumnSelections<SteamAuthRequestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SteamAuthRequest>(
      rows,
      columns: columns?.call(SteamAuthRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SteamAuthRequest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SteamAuthRequest> updateRow(
    _i1.DatabaseSession session,
    SteamAuthRequest row, {
    _i1.ColumnSelections<SteamAuthRequestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SteamAuthRequest>(
      row,
      columns: columns?.call(SteamAuthRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SteamAuthRequest] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SteamAuthRequest?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<SteamAuthRequestUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SteamAuthRequest>(
      id,
      columnValues: columnValues(SteamAuthRequest.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SteamAuthRequest]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SteamAuthRequest>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SteamAuthRequestUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<SteamAuthRequestTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SteamAuthRequestTable>? orderBy,
    _i1.OrderByListBuilder<SteamAuthRequestTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SteamAuthRequest>(
      columnValues: columnValues(SteamAuthRequest.t.updateTable),
      where: where(SteamAuthRequest.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SteamAuthRequest.t),
      orderByList: orderByList?.call(SteamAuthRequest.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SteamAuthRequest]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SteamAuthRequest>> delete(
    _i1.DatabaseSession session,
    List<SteamAuthRequest> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SteamAuthRequest>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SteamAuthRequest].
  Future<SteamAuthRequest> deleteRow(
    _i1.DatabaseSession session,
    SteamAuthRequest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SteamAuthRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SteamAuthRequest>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SteamAuthRequestTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SteamAuthRequest>(
      where: where(SteamAuthRequest.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SteamAuthRequestTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SteamAuthRequest>(
      where: where?.call(SteamAuthRequest.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SteamAuthRequest] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SteamAuthRequestTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SteamAuthRequest>(
      where: where(SteamAuthRequest.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
