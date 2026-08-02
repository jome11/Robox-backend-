import 'package:dart_frog/dart_frog.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();

  final workers = db.select("SELECT id, name FROM users WHERE role = 'worker'");

  final entries = <Map<String, dynamic>>[];

  for (final worker in workers) {
    final workerId = worker['id'] as String;
    final workerName = worker['name'] as String;

    final totalAssigned = db.select(
      'SELECT COUNT(*) as count FROM task_assignments WHERE worker_id = ?',
      [workerId],
    ).first['count'] as int;

    final completed = db.select(
      '''
      SELECT COUNT(*) as count FROM task_assignments
      JOIN tasks ON tasks.id = task_assignments.task_id
      WHERE task_assignments.worker_id = ? AND tasks.status = 'completed'
      ''',
      [workerId],
    ).first['count'] as int;

    final efficiency = totalAssigned == 0 ? 0.0 : (completed / totalAssigned) * 100;

    entries.add({
      'userId': workerId,
      'userName': workerName,
      'tasksCompleted': completed,
      'efficiency': efficiency,
    });
  }

  // Rank by tasks completed, descending.
  entries.sort((a, b) => (b['tasksCompleted'] as int).compareTo(a['tasksCompleted'] as int));
  for (var i = 0; i < entries.length; i++) {
    entries[i]['rank'] = i + 1;
  }

  return Response.json(statusCode: 200, body: {'leaderboard': entries});
}