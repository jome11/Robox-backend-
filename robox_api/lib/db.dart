import 'package:sqlite3/sqlite3.dart';

Database? _db;

Database getDb() {
  if (_db != null) return _db!;

  _db = sqlite3.open('robox.db');

  _db!.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
  ''');

  _db!.execute('''
    CREATE TABLE IF NOT EXISTS pending_requests (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      requested_at TEXT NOT NULL
    );
  ''');

  _db!.execute('''
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

  _db!.execute('''
    CREATE TABLE IF NOT EXISTS task_assignments (
      task_id TEXT NOT NULL,
      worker_id TEXT NOT NULL,
      PRIMARY KEY (task_id, worker_id),
      FOREIGN KEY (task_id) REFERENCES tasks (id),
      FOREIGN KEY (worker_id) REFERENCES users (id)
    );
  ''');

  _db!.execute('''
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

  _db!.execute('''
    CREATE TABLE IF NOT EXISTS stock (
      id TEXT PRIMARY KEY,
      item_name TEXT UNIQUE NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''');
  // Add new columns for password reset + account deactivation.
  // Wrapped in try/catch since SQLite errors if the column already exists.
  try {
    _db!.execute(
      'ALTER TABLE users ADD COLUMN must_change_password INTEGER NOT NULL DEFAULT 0;',
    );
  } catch (_) {
    // Column already exists — safe to ignore.
  }
  try {
    _db!.execute(
      'ALTER TABLE users ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1;',
    );
  } catch (_) {
    // Column already exists — safe to ignore.
  }

  return _db!;
}