import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.delete) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final payload = context.read<Map<String, dynamic>>();
  final workerId = payload['id'] as String;

  final db = getDb();

  final assignment = db.select(
    'SELECT * FROM task_assignments WHERE task_id = ? AND worker_id = ?',
    [id, workerId],
  );
  if (assignment.isEmpty) {
    return Response.json(statusCode: 403, body: {'error': 'NOT_ASSIGNED'});
  }

  final task = db.select('SELECT status FROM tasks WHERE id = ?', [id]);
  if (task.isEmpty) {
    return Response.json(statusCode: 404, body: {'error': 'NOT_FOUND'});
  }
  if (task.first['status'] != 'completed') {
    return Response.json(
      statusCode: 400,
      body: {'error': 'TASK_NOT_COMPLETED'},
    );
  }

  db
    ..execute('DELETE FROM task_assignments WHERE task_id = ?', [id])
    ..execute('DELETE FROM tasks WHERE id = ?', [id]);

  return Response.json(body: {'message': 'Task removed'});
}
