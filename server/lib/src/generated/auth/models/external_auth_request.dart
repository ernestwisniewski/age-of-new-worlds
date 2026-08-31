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
import 'package:aonw_server/src/generated/protocol.dart' as _i2;

abstract class ExternalAuthRequest
    implements _i1.TableRow<_i1.UuidValue?>, _i1.ProtocolSerialization {
  ExternalAuthRequest._({
    this.id,
    required this.requestId,
    required this.state,
    required this.provider,
    required this.status,
    this.codeVerifier,
    this.error,
    this.authStrategy,
    this.token,
    this.tokenExpiresAt,
    this.refreshToken,
    this.authUserId,
    this.scopeNames,
    DateTime? createdAt,
    required this.expiresAt,
    this.completedAt,
    this.consumedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExternalAuthRequest({
    _i1.UuidValue? id,
    required String requestId,
    required String state,
    required String provider,
    required String status,
    String? codeVerifier,
    String? error,
    String? authStrategy,
    String? token,
    DateTime? tokenExpiresAt,
    String? refreshToken,
    _i1.UuidValue? authUserId,
    List<String>? scopeNames,
    DateTime? createdAt,
    required DateTime expiresAt,
    DateTime? completedAt,
    DateTime? consumedAt,
  }) = _ExternalAuthRequestImpl;

  factory ExternalAuthRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return ExternalAuthRequest(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      requestId: jsonSerialization['requestId'] as String,
      state: jsonSerialization['state'] as String,
      provider: jsonSerialization['provider'] as String,
      status: jsonSerialization['status'] as String,
      codeVerifier: jsonSerialization['codeVerifier'] as String?,
      error: jsonSerialization['error'] as String?,
      authStrategy: jsonSerialization['authStrategy'] as String?,
      token: jsonSerialization['token'] as String?,
      tokenExpiresAt: jsonSerialization['tokenExpiresAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['tokenExpiresAt'],
            ),
      refreshToken: jsonSerialization['refreshToken'] as String?,
      authUserId: jsonSerialization['authUserId'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(
              jsonSerialization['authUserId'],
            ),
      scopeNames: jsonSerialization['scopeNames'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['scopeNames'],
            ),
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

  static final t = ExternalAuthRequestTable();

  static const db = ExternalAuthRequestRepository._();

  @override
  _i1.UuidValue? id;

  String requestId;

  String state;

  String provider;

  String status;

  String? codeVerifier;

  String? error;

  String? authStrategy;

  String? token;

  DateTime? tokenExpiresAt;

  String? refreshToken;

  _i1.UuidValue? authUserId;

  List<String>? scopeNames;

  DateTime createdAt;

  DateTime expiresAt;

  DateTime? completedAt;

  DateTime? consumedAt;

  @override
  _i1.Table<_i1.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ExternalAuthRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ExternalAuthRequest copyWith({
    _i1.UuidValue? id,
    String? requestId,
    String? state,
    String? provider,
    String? status,
    String? codeVerifier,
    String? error,
    String? authStrategy,
    String? token,
    DateTime? tokenExpiresAt,
    String? refreshToken,
    _i1.UuidValue? authUserId,
    List<String>? scopeNames,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    DateTime? consumedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ExternalAuthRequest',
      if (id != null) 'id': id?.toJson(),
      'requestId': requestId,
      'state': state,
      'provider': provider,
      'status': status,
      if (codeVerifier != null) 'codeVerifier': codeVerifier,
      if (error != null) 'error': error,
      if (authStrategy != null) 'authStrategy': authStrategy,
      if (token != null) 'token': token,
      if (tokenExpiresAt != null) 'tokenExpiresAt': tokenExpiresAt?.toJson(),
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (authUserId != null) 'authUserId': authUserId?.toJson(),
      if (scopeNames != null) 'scopeNames': scopeNames?.toJson(),
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

  static ExternalAuthRequestInclude include() {
    return ExternalAuthRequestInclude._();
  }

  static ExternalAuthRequestIncludeList includeList({
    _i1.WhereExpressionBuilder<ExternalAuthRequestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ExternalAuthRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExternalAuthRequestTable>? orderByList,
    ExternalAuthRequestInclude? include,
  }) {
    return ExternalAuthRequestIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ExternalAuthRequest.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ExternalAuthRequest.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ExternalAuthRequestImpl extends ExternalAuthRequest {
  _ExternalAuthRequestImpl({
    _i1.UuidValue? id,
    required String requestId,
    required String state,
    required String provider,
    required String status,
    String? codeVerifier,
    String? error,
    String? authStrategy,
    String? token,
    DateTime? tokenExpiresAt,
    String? refreshToken,
    _i1.UuidValue? authUserId,
    List<String>? scopeNames,
    DateTime? createdAt,
    required DateTime expiresAt,
    DateTime? completedAt,
    DateTime? consumedAt,
  }) : super._(
         id: id,
         requestId: requestId,
         state: state,
         provider: provider,
         status: status,
         codeVerifier: codeVerifier,
         error: error,
         authStrategy: authStrategy,
         token: token,
         tokenExpiresAt: tokenExpiresAt,
         refreshToken: refreshToken,
         authUserId: authUserId,
         scopeNames: scopeNames,
         createdAt: createdAt,
         expiresAt: expiresAt,
         completedAt: completedAt,
         consumedAt: consumedAt,
       );

  /// Returns a shallow copy of this [ExternalAuthRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ExternalAuthRequest copyWith({
    Object? id = _Undefined,
    String? requestId,
    String? state,
    String? provider,
    String? status,
    Object? codeVerifier = _Undefined,
    Object? error = _Undefined,
    Object? authStrategy = _Undefined,
    Object? token = _Undefined,
    Object? tokenExpiresAt = _Undefined,
    Object? refreshToken = _Undefined,
    Object? authUserId = _Undefined,
    Object? scopeNames = _Undefined,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? completedAt = _Undefined,
    Object? consumedAt = _Undefined,
  }) {
    return ExternalAuthRequest(
      id: id is _i1.UuidValue? ? id : this.id,
      requestId: requestId ?? this.requestId,
      state: state ?? this.state,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      codeVerifier: codeVerifier is String? ? codeVerifier : this.codeVerifier,
      error: error is String? ? error : this.error,
      authStrategy: authStrategy is String? ? authStrategy : this.authStrategy,
      token: token is String? ? token : this.token,
      tokenExpiresAt: tokenExpiresAt is DateTime?
          ? tokenExpiresAt
          : this.tokenExpiresAt,
      refreshToken: refreshToken is String? ? refreshToken : this.refreshToken,
      authUserId: authUserId is _i1.UuidValue? ? authUserId : this.authUserId,
      scopeNames: scopeNames is List<String>?
          ? scopeNames
          : this.scopeNames?.map((e0) => e0).toList(),
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      consumedAt: consumedAt is DateTime? ? consumedAt : this.consumedAt,
    );
  }
}

class ExternalAuthRequestUpdateTable
    extends _i1.UpdateTable<ExternalAuthRequestTable> {
  ExternalAuthRequestUpdateTable(super.table);

  _i1.ColumnValue<String, String> requestId(String value) => _i1.ColumnValue(
    table.requestId,
    value,
  );

  _i1.ColumnValue<String, String> state(String value) => _i1.ColumnValue(
    table.state,
    value,
  );

  _i1.ColumnValue<String, String> provider(String value) => _i1.ColumnValue(
    table.provider,
    value,
  );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<String, String> codeVerifier(String? value) =>
      _i1.ColumnValue(
        table.codeVerifier,
        value,
      );

  _i1.ColumnValue<String, String> error(String? value) => _i1.ColumnValue(
    table.error,
    value,
  );

  _i1.ColumnValue<String, String> authStrategy(String? value) =>
      _i1.ColumnValue(
        table.authStrategy,
        value,
      );

  _i1.ColumnValue<String, String> token(String? value) => _i1.ColumnValue(
    table.token,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> tokenExpiresAt(DateTime? value) =>
      _i1.ColumnValue(
        table.tokenExpiresAt,
        value,
      );

  _i1.ColumnValue<String, String> refreshToken(String? value) =>
      _i1.ColumnValue(
        table.refreshToken,
        value,
      );

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue? value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> scopeNames(List<String>? value) =>
      _i1.ColumnValue(
        table.scopeNames,
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

class ExternalAuthRequestTable extends _i1.Table<_i1.UuidValue?> {
  ExternalAuthRequestTable({super.tableRelation})
    : super(tableName: 'aonw_external_auth_request') {
    updateTable = ExternalAuthRequestUpdateTable(this);
    requestId = _i1.ColumnString(
      'requestId',
      this,
    );
    state = _i1.ColumnString(
      'state',
      this,
    );
    provider = _i1.ColumnString(
      'provider',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    codeVerifier = _i1.ColumnString(
      'codeVerifier',
      this,
    );
    error = _i1.ColumnString(
      'error',
      this,
    );
    authStrategy = _i1.ColumnString(
      'authStrategy',
      this,
    );
    token = _i1.ColumnString(
      'token',
      this,
    );
    tokenExpiresAt = _i1.ColumnDateTime(
      'tokenExpiresAt',
      this,
    );
    refreshToken = _i1.ColumnString(
      'refreshToken',
      this,
    );
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    scopeNames = _i1.ColumnSerializable<List<String>>(
      'scopeNames',
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

  late final ExternalAuthRequestUpdateTable updateTable;

  late final _i1.ColumnString requestId;

  late final _i1.ColumnString state;

  late final _i1.ColumnString provider;

  late final _i1.ColumnString status;

  late final _i1.ColumnString codeVerifier;

  late final _i1.ColumnString error;

  late final _i1.ColumnString authStrategy;

  late final _i1.ColumnString token;

  late final _i1.ColumnDateTime tokenExpiresAt;

  late final _i1.ColumnString refreshToken;

  late final _i1.ColumnUuid authUserId;

  late final _i1.ColumnSerializable<List<String>> scopeNames;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime expiresAt;

  late final _i1.ColumnDateTime completedAt;

  late final _i1.ColumnDateTime consumedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    requestId,
    state,
    provider,
    status,
    codeVerifier,
    error,
    authStrategy,
    token,
    tokenExpiresAt,
    refreshToken,
    authUserId,
    scopeNames,
    createdAt,
    expiresAt,
    completedAt,
    consumedAt,
  ];
}

class ExternalAuthRequestInclude extends _i1.IncludeObject {
  ExternalAuthRequestInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ExternalAuthRequest.t;
}

class ExternalAuthRequestIncludeList extends _i1.IncludeList {
  ExternalAuthRequestIncludeList._({
    _i1.WhereExpressionBuilder<ExternalAuthRequestTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ExternalAuthRequest.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<_i1.UuidValue?> get table => ExternalAuthRequest.t;
}

class ExternalAuthRequestRepository {
  const ExternalAuthRequestRepository._();

  /// Returns a list of [ExternalAuthRequest]s matching the given query parameters.
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
  Future<List<ExternalAuthRequest>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ExternalAuthRequestTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ExternalAuthRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExternalAuthRequestTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ExternalAuthRequest>(
      where: where?.call(ExternalAuthRequest.t),
      orderBy: orderBy?.call(ExternalAuthRequest.t),
      orderByList: orderByList?.call(ExternalAuthRequest.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ExternalAuthRequest] matching the given query parameters.
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
  Future<ExternalAuthRequest?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ExternalAuthRequestTable>? where,
    int? offset,
    _i1.OrderByBuilder<ExternalAuthRequestTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ExternalAuthRequestTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ExternalAuthRequest>(
      where: where?.call(ExternalAuthRequest.t),
      orderBy: orderBy?.call(ExternalAuthRequest.t),
      orderByList: orderByList?.call(ExternalAuthRequest.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ExternalAuthRequest] by its [id] or null if no such row exists.
  Future<ExternalAuthRequest?> findById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ExternalAuthRequest>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ExternalAuthRequest]s in the list and returns the inserted rows.
  ///
  /// The returned [ExternalAuthRequest]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ExternalAuthRequest>> insert(
    _i1.DatabaseSession session,
    List<ExternalAuthRequest> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ExternalAuthRequest>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ExternalAuthRequest] and returns the inserted row.
  ///
  /// The returned [ExternalAuthRequest] will have its `id` field set.
  Future<ExternalAuthRequest> insertRow(
    _i1.DatabaseSession session,
    ExternalAuthRequest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ExternalAuthRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ExternalAuthRequest]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ExternalAuthRequest>> update(
    _i1.DatabaseSession session,
    List<ExternalAuthRequest> rows, {
    _i1.ColumnSelections<ExternalAuthRequestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ExternalAuthRequest>(
      rows,
      columns: columns?.call(ExternalAuthRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ExternalAuthRequest]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ExternalAuthRequest> updateRow(
    _i1.DatabaseSession session,
    ExternalAuthRequest row, {
    _i1.ColumnSelections<ExternalAuthRequestTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ExternalAuthRequest>(
      row,
      columns: columns?.call(ExternalAuthRequest.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ExternalAuthRequest] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ExternalAuthRequest?> updateById(
    _i1.DatabaseSession session,
    _i1.UuidValue id, {
    required _i1.ColumnValueListBuilder<ExternalAuthRequestUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ExternalAuthRequest>(
      id,
      columnValues: columnValues(ExternalAuthRequest.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ExternalAuthRequest]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ExternalAuthRequest>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ExternalAuthRequestUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<ExternalAuthRequestTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ExternalAuthRequestTable>? orderBy,
    _i1.OrderByListBuilder<ExternalAuthRequestTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ExternalAuthRequest>(
      columnValues: columnValues(ExternalAuthRequest.t.updateTable),
      where: where(ExternalAuthRequest.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ExternalAuthRequest.t),
      orderByList: orderByList?.call(ExternalAuthRequest.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ExternalAuthRequest]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ExternalAuthRequest>> delete(
    _i1.DatabaseSession session,
    List<ExternalAuthRequest> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ExternalAuthRequest>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ExternalAuthRequest].
  Future<ExternalAuthRequest> deleteRow(
    _i1.DatabaseSession session,
    ExternalAuthRequest row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ExternalAuthRequest>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ExternalAuthRequest>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ExternalAuthRequestTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ExternalAuthRequest>(
      where: where(ExternalAuthRequest.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ExternalAuthRequestTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ExternalAuthRequest>(
      where: where?.call(ExternalAuthRequest.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ExternalAuthRequest] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ExternalAuthRequestTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ExternalAuthRequest>(
      where: where(ExternalAuthRequest.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
