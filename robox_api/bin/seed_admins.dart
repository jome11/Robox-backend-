import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import '../lib/db.dart';

void main() {
  final db = getDb();
  const uuid = Uuid();

  final admins = [
    {'name': 'Admin One', 'email': 'admin1@robox.ai', 'password': 'ChangeMe123!'},
    {'name': 'Admin Two', 'email': 'admin2@robox.ai', 'password': 'ChangeMe456!'},
  ];

  for (final admin in admins) {
    final existing = db.select(
      'SELECT id FROM users WHERE email = ?',
      [admin['email']],
    );

    if (existing.isNotEmpty) {
      print('Skipping ${admin['email']} — already exists');
      continue;
    }

    final hash = BCrypt.hashpw(admin['password']!, BCrypt.gensalt());

    db.execute(
      '''
      INSERT INTO users (id, name, email, password_hash, role, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        uuid.v4(),
        admin['name'],
        admin['email'],
        hash,
        'admin',
        DateTime.now().toIso8601String(),
      ],
    );

    print('Created admin: ${admin['email']}');
  }

  print('Done.');
}