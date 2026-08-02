import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final payload = context.read<Map<String, dynamic>>();
  final workerId = payload['id'] as String;

  final db = getDb();

  // Make sure this task is actually assigned to this worker —
  // otherwise anyone with a valid token could update any task.
  final assignment = db.select(
    'SELECT * FROM task_assignments WHERE task_id = ? AND worker_id = ?',
    [id, workerId],
  );

  if (assignment.isEmpty) {
    return Response.json(statusCode: 403, body: {'error': 'NOT_ASSIGNED'});
  }

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final progress = (body['progress'] as num?)?.toDouble();
  final status = body['status'] as String?;

  if (progress == null || status == null) {
    return Response.json(statusCode: 400, body: {'error': 'MISSING_FIELDS'});
  }

  db.execute(
    'UPDATE tasks SET progress = ?, status = ? WHERE id = ?',
    [progress, status, id],
  );

  return Response.json(body: {'message': 'Updated'});
}
