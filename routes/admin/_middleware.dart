import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

String get jwtSecret =>
    Platform.environment['JWT_SECRET'] ?? 'temporary-dev-secret-change-this-later';

Handler middleware(Handler handler) {
  return (context) async {
    final authHeader = context.request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'NO_TOKEN'},
      );
    }

    final token = authHeader.substring(7); // strip "Bearer "

    try {
      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;

      if (payload['role'] != 'admin') {
        return Response.json(
          statusCode: 403,
          body: {'error': 'NOT_ADMIN'},
        );
      }

      // Token is valid and belongs to an admin — continue to the route
      return handler(context);
    } on JWTExpiredException {
      return Response.json(statusCode: 401, body: {'error': 'TOKEN_EXPIRED'});
    } catch (_) {
      return Response.json(statusCode: 401, body: {'error': 'INVALID_TOKEN'});
    }
  };
}
