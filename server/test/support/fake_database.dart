import 'dart:collection';

import 'package:serverpod/serverpod.dart';

final class FakeDatabaseCall {
  const FakeDatabaseCall({
    required this.operation,
    this.rowType,
    this.rows = const [],
    this.query,
    this.parameters,
    this.transaction,
    this.lockMode,
    this.lockBehavior,
  });

  final String operation;
  final Type? rowType;
  final List<TableRow<dynamic>> rows;
  final String? query;
  final Object? parameters;
  final Transaction? transaction;
  final LockMode? lockMode;
  final LockBehavior? lockBehavior;
}

final class FakeDatabase implements Database {
  final Map<Type, ListQueue<List<TableRow<dynamic>>>> _findResults = {};
  final Map<Type, ListQueue<TableRow<dynamic>?>> _findFirstResults = {};
  final Map<Type, ListQueue<TableRow<dynamic>>> _insertRowResults = {};
  final Map<Type, ListQueue<TableRow<dynamic>>> _updateRowResults = {};
  final Map<Type, ListQueue<List<TableRow<dynamic>>>> _updateWhereResults = {};
  final ListQueue<Object> _insertRowErrors = ListQueue();
  final ListQueue<Object> _transactionErrors = ListQueue();
  final ListQueue<DatabaseResult> _unsafeQueryResults = ListQueue();
  final ListQueue<int> _unsafeExecuteResults = ListQueue();

  final List<FakeDatabaseCall> calls = [];

  void queueFind<T extends TableRow<dynamic>>(List<T> rows) {
    _findResults
        .putIfAbsent(T, ListQueue.new)
        .add(List<TableRow<dynamic>>.of(rows));
  }

  void queueFindFirst<T extends TableRow<dynamic>>(T? row) {
    _findFirstResults.putIfAbsent(T, ListQueue.new).add(row);
  }

  void queueInsertRow<T extends TableRow<dynamic>>(T row) {
    _insertRowResults.putIfAbsent(T, ListQueue.new).add(row);
  }

  void queueInsertRowError(Object error) => _insertRowErrors.add(error);

  void queueTransactionError(Object error) => _transactionErrors.add(error);

  void queueUpdateRow<T extends TableRow<dynamic>>(T row) {
    _updateRowResults.putIfAbsent(T, ListQueue.new).add(row);
  }

  void queueUpdateWhere<T extends TableRow<dynamic>>(List<T> rows) {
    _updateWhereResults
        .putIfAbsent(T, ListQueue.new)
        .add(List<TableRow<dynamic>>.of(rows));
  }

  void queueUnsafeQuery(List<List<dynamic>> rows) {
    _unsafeQueryResults.add(FakeDatabaseResult(rows));
  }

  void queueUnsafeExecute(int affectedRows) {
    _unsafeExecuteResults.add(affectedRows);
  }

  Iterable<FakeDatabaseCall> callsFor(String operation) =>
      calls.where((call) => call.operation == operation);

  @override
  Future<List<T>> find<T extends TableRow<dynamic>>({
    Expression<dynamic>? where,
    int? limit,
    int? offset,
    Column<dynamic>? orderBy,
    List<Order>? orderByList,
    bool orderDescending = false,
    Transaction? transaction,
    Include? include,
    LockMode? lockMode,
    LockBehavior? lockBehavior,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'find',
        rowType: T,
        transaction: transaction,
        lockMode: lockMode,
        lockBehavior: lockBehavior,
      ),
    );
    final queue = _findResults[T];
    return queue == null || queue.isEmpty
        ? <T>[]
        : queue.removeFirst().cast<T>();
  }

  @override
  Future<T?> findFirstRow<T extends TableRow<dynamic>>({
    Expression<dynamic>? where,
    int? offset,
    Column<dynamic>? orderBy,
    List<Order>? orderByList,
    bool orderDescending = false,
    Transaction? transaction,
    Include? include,
    LockMode? lockMode,
    LockBehavior? lockBehavior,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'findFirstRow',
        rowType: T,
        transaction: transaction,
        lockMode: lockMode,
        lockBehavior: lockBehavior,
      ),
    );
    final queue = _findFirstResults[T];
    return queue == null || queue.isEmpty ? null : queue.removeFirst() as T?;
  }

  @override
  Future<T> insertRow<T extends TableRow<dynamic>>(
    T row, {
    Transaction? transaction,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'insertRow',
        rowType: T,
        rows: [row],
        transaction: transaction,
      ),
    );
    if (_insertRowErrors.isNotEmpty) throw _insertRowErrors.removeFirst();
    final queue = _insertRowResults[T];
    return queue == null || queue.isEmpty ? row : queue.removeFirst() as T;
  }

  @override
  Future<List<T>> insert<T extends TableRow<dynamic>>(
    List<T> rows, {
    Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'insert',
        rowType: T,
        rows: rows,
        transaction: transaction,
      ),
    );
    return rows;
  }

  @override
  Future<T> updateRow<T extends TableRow<dynamic>>(
    T row, {
    List<Column<dynamic>>? columns,
    Transaction? transaction,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'updateRow',
        rowType: T,
        rows: [row],
        transaction: transaction,
      ),
    );
    final queue = _updateRowResults[T];
    return queue == null || queue.isEmpty ? row : queue.removeFirst() as T;
  }

  @override
  Future<List<T>> updateWhere<T extends TableRow<dynamic>>({
    required List<ColumnValue<dynamic, dynamic>> columnValues,
    required Expression<dynamic> where,
    int? limit,
    int? offset,
    Column<dynamic>? orderBy,
    List<Order>? orderByList,
    bool orderDescending = false,
    Transaction? transaction,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'updateWhere',
        rowType: T,
        transaction: transaction,
      ),
    );
    final queue = _updateWhereResults[T];
    return queue == null || queue.isEmpty
        ? <T>[]
        : queue.removeFirst().cast<T>();
  }

  @override
  Future<List<T>> deleteWhere<T extends TableRow<dynamic>>({
    required Expression<dynamic> where,
    Transaction? transaction,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'deleteWhere',
        rowType: T,
        transaction: transaction,
      ),
    );
    return <T>[];
  }

  @override
  Future<DatabaseResult> unsafeQuery(
    String query, {
    int? timeoutInSeconds,
    Transaction? transaction,
    QueryParameters? parameters,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'unsafeQuery',
        query: query,
        parameters: parameters?.parameters,
        transaction: transaction,
      ),
    );
    return _unsafeQueryResults.isEmpty
        ? FakeDatabaseResult(const [])
        : _unsafeQueryResults.removeFirst();
  }

  @override
  Future<int> unsafeExecute(
    String query, {
    int? timeoutInSeconds,
    Transaction? transaction,
    QueryParameters? parameters,
  }) async {
    calls.add(
      FakeDatabaseCall(
        operation: 'unsafeExecute',
        query: query,
        parameters: parameters?.parameters,
        transaction: transaction,
      ),
    );
    return _unsafeExecuteResults.isEmpty
        ? 1
        : _unsafeExecuteResults.removeFirst();
  }

  @override
  Future<R> transaction<R>(
    TransactionFunction<R> transactionFunction, {
    TransactionSettings? settings,
  }) {
    calls.add(const FakeDatabaseCall(operation: 'transaction'));
    if (_transactionErrors.isNotEmpty) {
      throw _transactionErrors.removeFirst();
    }
    return transactionFunction(const FakeTransaction());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected database call: $invocation');
}

final class FakeSession implements Session {
  const FakeSession(this.database);

  final FakeDatabase database;

  @override
  Database get db => database;

  @override
  void log(
    String message, {
    LogLevel? level,
    dynamic exception,
    StackTrace? stackTrace,
  }) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected session call: $invocation');
}

final class FakeDatabaseResult extends DatabaseResult {
  FakeDatabaseResult(List<List<dynamic>> rows)
    : super([for (final row in rows) _FakeDatabaseResultRow(row)]);

  @override
  int get affectedRowCount => length;

  @override
  DatabaseResultSchema get schema => const _FakeDatabaseResultSchema();
}

final class _FakeDatabaseResultRow extends DatabaseResultRow {
  _FakeDatabaseResultRow(super.values);

  @override
  Map<String, dynamic> toColumnMap() => const {};
}

final class _FakeDatabaseResultSchema implements DatabaseResultSchema {
  const _FakeDatabaseResultSchema();

  @override
  Iterable<DatabaseResultSchemaColumn> get columns => const [];
}

final class FakeTransaction implements Transaction {
  const FakeTransaction();

  @override
  Future<Savepoint> createSavepoint() async => const _FakeSavepoint();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected transaction call: $invocation');
}

final class _FakeSavepoint implements Savepoint {
  const _FakeSavepoint();

  @override
  String get id => 'fake-savepoint';

  @override
  Future<void> release() async {}

  @override
  Future<void> rollback() async {}
}

final class FakeDatabaseQueryException extends DatabaseQueryException {
  FakeDatabaseQueryException({this.code, this.constraintName});

  @override
  final String? code;

  @override
  final String? constraintName;

  @override
  String get message => 'Injected database query failure';

  @override
  String? get columnName => null;

  @override
  String? get detail => null;

  @override
  String? get hint => null;

  @override
  int? get position => null;

  @override
  String? get tableName => null;
}
