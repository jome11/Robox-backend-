import 'package:dart_frog/dart_frog.dart';
import '../../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final payload = context.read<Map<String, dynamic>>();
  final workerId = payload['id'] as String;

  final db = getDb();

  final rows = db.select(
    '''
    SELECT tasks.* FROM tasks
    JOIN task_assignments ON task_assignments.task_id = tasks.id
    WHERE task_assignments.worker_id = ?
    ORDER BY tasks.created_at DESC
    ''',
    [workerId],
  );

  final tasks = rows.map((row) => {
    'id': row['id'],
    'title': row['title'],
    'description': row['description'],
    'deadline': row['deadline'],
    'priority': row['priority'],
    'status': row['status'],
    'progress': row['progress'],
    'isGroupTask': row['is_group_task'] == 1,
  }).toList();

  return Response.json(statusCode: 200, body: {'tasks': tasks});
}
