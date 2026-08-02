import 'package:dart_frog/dart_frog.dart';
import '../../lib/db.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final db = getDb();
  final rows = db.select('SELECT * FROM stock ORDER BY item_name');

  final stock = rows.map((row) => {
        'id': row['id'],
        'itemName': row['item_name'],
        'quantity': row['quantity'],
        'price': row['price'],
      }).toList();

  return Response.json(statusCode: 200, body: {'stock': stock});
}