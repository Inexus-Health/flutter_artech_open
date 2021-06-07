import 'dart:io';

import 'package:artech_core/core.dart';

class SocketExceptionHandler implements ExceptionHandlerBase {
  @override
  bool canHandle(Object exception) {
    return exception is SocketException;
  }

  @override
  void handle(ExceptionContext context) {
    final e = context.latestError as SocketException;
    context.hasHandled = true;
    context.parsedException = UserFriendlyException(
        code: 'NetworkException', message: 'Network unavailable');
  }
}

class HandshakeExceptionHandler implements ExceptionHandlerBase {
  @override
  bool canHandle(Object exception) {
    return exception is HandshakeException;
  }

  @override
  void handle(ExceptionContext context) {
    final e = context.latestError as SocketException;
    context.hasHandled = true;
    context.parsedException = UserFriendlyException(
        code: 'NetworkException', message: 'Network error');
  }
}
