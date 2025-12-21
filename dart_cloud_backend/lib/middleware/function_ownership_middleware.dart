import 'dart:convert';

import 'package:dart_cloud_backend/handlers/logs_utils/log_utils.dart';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:database/database.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Middleware functionOwnershipMiddleware(String keyFunction) {
  return (Handler handler) {
    return (Request request) async {
      try {
        final userId = request.context['userId'] as int;
        final userUUID = request.context['userUUID'] as String;
        final functionUuid = request.params[keyFunction] as String;

        final functionEntity = await DatabaseManagers.functions.findOne(
          where: {
            FunctionEntityExtension.uuidNameField: functionUuid,
            FunctionEntityExtension.userIdNameField: userId,
          },
        );

        if (functionEntity == null) {
          return Response.forbidden(
            json.encode({'error': 'Opps! something went wrong'}),
          );
        }
        return handler(
          request.change(
            context: {
              'userUUID': userUUID,
              'userId': userId,
              'functionId': functionEntity.id,
              'functionUuid': functionUuid,
            },
          ),
        );
      } catch (e, trace) {
        LogsUtils.log(LogLevels.error.name, 'functionOwnershipMiddleware', {
          'error': e.toString(),
          'trace': trace.toString(),
        });
        return Response.forbidden(json.encode({'error': 'Opps! something went wrong'}));
      }
    };
  };
}
