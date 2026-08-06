import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class TursoClient {
  TursoClient._(this._pipelineUrl, this._authToken);

  final Uri _pipelineUrl;
  final String _authToken;

  static TursoClient? _instance;

  factory TursoClient.fromEnv() {
    if (_instance != null) return _instance!;

    final rawUrl = Platform.environment['TURSO_DATABASE_URL'];
    final token = Platform.environment['TURSO_AUTH_TOKEN'];

    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError(
        'TURSO_DATABASE_URL is not set. Add it to your .env locally '
        'and to your Render service\'s Environment tab.',
      );
    }
    if (token == null || token.isEmpty) {
      throw StateError(
        'TURSO_AUTH_TOKEN is not set. Add it to your .env locally '
        'and to your Render service\'s Environment tab.',
      );
    }

    var httpUrl = rawUrl.trim();
    if (httpUrl.startsWith('libsql://')) {
      httpUrl = httpUrl.replaceFirst('libsql://', 'https://');
    }
    if (httpUrl.endsWith('/')) {
      httpUrl = httpUrl.substring(0, httpUrl.length - 1);
    }

    _instance = TursoClient._(Uri.parse('$httpUrl/v2/pipeline'), token);
    return _instance!;
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?> args = const [],
  ]) async {
    final result = await _pipeline(sql, args);
    return result;
  }

  Future<void> execute(
    String sql, [
    List<Object?> args = const [],
  ]) async {
    await _pipeline(sql, args);
  }

  Future<List<Map<String, dynamic>>> _pipeline(
    String sql,
    List<Object?> args,
  ) async {
    final response = await http.post(
      _pipelineUrl,
      headers: {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requests': [
          {
            'type': 'execute',
            'stmt': {
              'sql': sql,
              'args': args.map(_encodeArg).toList(),
            },
          },
          {'type': 'close'},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Turso request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>;
    final first = results.first as Map<String, dynamic>;

    if (first['type'] == 'error') {
      final error = first['error'] as Map<String, dynamic>;
      throw Exception('Turso SQL error: ${error['message']}');
    }

    final execResult =
        (first['response'] as Map<String, dynamic>)['result']
            as Map<String, dynamic>;
    final cols = (execResult['cols'] as List<dynamic>)
        .map((c) => (c as Map<String, dynamic>)['name'] as String?)
        .toList();
    final rawRows = execResult['rows'] as List<dynamic>;

    return rawRows.map((rawRow) {
      final row = rawRow as List<dynamic>;
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final name = cols[i] ?? 'col$i';
        map[name] = _decodeValue(row[i] as Map<String, dynamic>);
      }
      return map;
    }).toList();
  }

  Map<String, dynamic> _encodeArg(Object? value) {
    if (value == null) return {'type': 'null'};
    if (value is int) return {'type': 'integer', 'value': value.toString()};
    if (value is double) return {'type': 'float', 'value': value};
    if (value is bool) {
      return {'type': 'integer', 'value': (value ? 1 : 0).toString()};
    }
    if (value is List<int>) {
      return {'type': 'blob', 'base64': base64Encode(value)};
    }
    return {'type': 'text', 'value': value.toString()};
  }

  dynamic _decodeValue(Map<String, dynamic> cell) {
    final type = cell['type'] as String;
    switch (type) {
      case 'null':
        return null;
      case 'integer':
        return int.parse(cell['value'] as String);
      case 'float':
        return (cell['value'] as num).toDouble();
      case 'text':
        return cell['value'] as String;
      case 'blob':
        return base64Decode(cell['base64'] as String);
      default:
        return cell['value'];
    }
  }
}

TursoClient? _client;

TursoClient getDb() {
  _client ??= TursoClient.fromEnv();
  return _client!;
}

Future<void> _tryAlter(String sql) async {
  try {
    await getDb().execute(sql);
  } catch (_) {
    // Column already exists — safe to ignore.
  }
}

Future<void> initDb() async {
  final db = getDb();

  await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS pending_requests (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      requested_at TEXT NOT NULL
    );
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS tasks (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      deadline TEXT NOT NULL,
      priority TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      progress REAL NOT NULL DEFAULT 0.0,
      is_group_task INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    );
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS task_assignments (
      task_id TEXT NOT NULL,
      worker_id TEXT NOT NULL,
      PRIMARY KEY (task_id, worker_id),
      FOREIGN KEY (task_id) REFERENCES tasks (id),
      FOREIGN KEY (worker_id) REFERENCES users (id)
    );
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category TEXT,
      sub_category TEXT,
      custom_category TEXT,
      description TEXT,
      added_by_id TEXT NOT NULL,
      added_by_name TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS stock (
      id TEXT PRIMARY KEY,
      item_name TEXT UNIQUE NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''');

  await _tryAlter(
    'ALTER TABLE users ADD COLUMN must_change_password INTEGER NOT NULL DEFAULT 0;',
  );
  await _tryAlter(
    'ALTER TABLE users ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1;',
  );
  await _tryAlter(
    'ALTER TABLE transactions ADD COLUMN edited INTEGER NOT NULL DEFAULT 0;',
  );
  await _tryAlter(
    'ALTER TABLE users ADD COLUMN fcm_token TEXT;',
  );
}