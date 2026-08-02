import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:robox_api/db.dart';
import 'package:uuid/uuid.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = getDb();

  if (context.request.method == HttpMethod.post) {
    final body =
        jsonDecode(await context.request.body()) as Map<String, dynamic>;

    final title = (body['title'] as String?)?.trim() ?? '';
    final description = (body['description'] as String?)?.trim() ?? '';
    final deadline = body['deadline'] as String? ?? '';
    final priority = body['priority'] as String? ?? 'medium';
    final isGroupTask = body['isGroupTask'] as bool? ?? false;
    final workerIds =
        (body['workerIds'] as List<dynamic>?)?.cast<String>() ?? [];

    if (title.isEmpty || deadline.isEmpty || workerIds.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'MISSING_FIELDS'},
      );
    }

    const uuid = Uuid();
    final taskId = uuid.v4();

    await db.execute(
      '''
      INSERT INTO tasks (id, title, description, deadline, priority, status, progress, is_group_task, created_at)
      VALUES (?, ?, ?, ?, ?, 'pending', 0.0, ?, ?)
      ''',
      [
        taskId,
        title,
        description,
        deadline,
        priority,
        if (isGroupTask) 1 else 0,
        DateTime.now().toIso8601String(),
      ],
    );

    for (final workerId in workerIds) {
      await db.execute(
        'INSERT INTO task_assignments (task_id, worker_id) VALUES (?, ?)',
        [taskId, workerId],
      );
    }

    return Response.json(
      body: {'message': 'Task created', 'taskId': taskId},
    );
  }

  if (context.request.method == HttpMethod.get) {
    final rows = await db.query('SELECT * FROM tasks ORDER BY created_at DESC');

    final tasks = <Map<String, dynamic>>[];
    for (final row in rows) {
      final assignedWorkers = await db.query(
        '''
        SELECT users.id, users.name FROM task_assignments
        JOIN users ON users.id = task_assignments.worker_id
        WHERE task_assignments.task_id = ?
        ''',
        [row['id']],
      );

      tasks.add({
        'id': row['id'],
        'title': row['title'],
        'description': row['description'],
        'deadline': row['deadline'],
        'priority': row['priority'],
        'status': row['status'],
        'progress': row['progress'],
        'isGroupTask': row['is_group_task'] == 1,
        'assignedWorkers': assignedWorkers
            .map(
              (w) => {
                'id': w['id'],
                'name': w['name'],
              },
            )
            .toList(),
      });
    }

    return Response.json(body: {'tasks': tasks});
  }

  return Response(statusCode: 405, body: 'Method not allowed');
}
