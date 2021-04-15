import 'dart:async';

import 'package:artech_core/core.dart';
import 'package:artemis/client.dart' show ArtemisClient;
import 'package:artemis/schema/graphql_query.dart';
import 'package:artemis/schema/graphql_response.dart';
import 'package:graphql_flutter/graphql_flutter.dart' hide JsonSerializable;
import 'package:json_annotation/json_annotation.dart';

abstract class GraphQLRemoteRepositoryBase with ServiceGetter, HasSelfLogger {
  ArtemisClient artemisClientNamed({String name}) =>
      services.get<ArtemisClient>(instanceName: name);
  GraphQLClient clientNamed({String name}) =>
      services.get<GraphQLClient>(instanceName: name);

  //strong typed client
  Future<GraphQLResponse<T>> execute<T, U extends JsonSerializable>(
      GraphQLQuery<T, U> query,
      {String name}) async {
    try {
      final response = await artemisClientNamed(name: name).execute(query);
      checkGraphQLResponseExceptionAndThrow(response);
      return response;
    } catch (error, stackTrace) {
      logger.severe(error, error, stackTrace);
      rethrow;
    }
  }

  Future<QueryResult> mutate(MutationOptions options, {String name}) async {
    try {
      final QueryResult result = await clientNamed(name: name).mutate(options);
      checkQueryResultExceptionAndThrow(result);
      return result;
    } catch (error, stackTrace) {
      logger.severe(error, error, stackTrace);
      rethrow;
    }
  }

  ObservableQuery watchQuery(WatchQueryOptions options, {String name}) {
    final ObservableQuery result = clientNamed(name: name).watchQuery(options);
    return result;
  }

  Future<QueryResult> query(QueryOptions options, {String name}) async {
    try {
      final QueryResult result = await clientNamed(name: name).query(options);
      checkQueryResultExceptionAndThrow(result);
      return result;
    } catch (error, stackTrace) {
      logger.severe(error, error, stackTrace);
      rethrow;
    }
  }

  void checkQueryResultExceptionAndThrow(QueryResult result) {
    if (result.hasException) {
      logger.severe(result.exception.toString());
      throw result.exception;
    }
  }

  void checkGraphQLResponseExceptionAndThrow<T>(GraphQLResponse<T> response) {
    if (response.hasErrors) {
      logger.severe(response.errors.map((e) => e.toString()).join(''));
      throw coalesceErrors(graphqlErrors: response.errors);
    }
  }
}

typedef QueryResultToTypedData<T> = T Function(
    Map<String, dynamic> json, QueryResult queryResult);

T toSingleData<T>(
    QueryResult queryResult, QueryResultToTypedData<T> fromJson, String key) {
  if (queryResult.data != null) {
    return fromJson(
        (key != null ? queryResult.data[key] : queryResult.data)
            as Map<String, dynamic>,
        queryResult);
  }
  return null;
}

Stream<T> toSingleDataStream<T>(Stream<QueryResult> queryResult,
    QueryResultToTypedData<T> fromJson, String key) {
  return queryResult.map((result) => toSingleData(result, fromJson, key));
}

List<T> toListData<T>(
    QueryResult queryResult, QueryResultToTypedData<T> fromJson, String key) {
  if (queryResult?.data != null && queryResult.data[key] != null) {
    return List<T>.from((queryResult.data[key] as Iterable<dynamic>).map<T>(
        (dynamic e) => fromJson(e as Map<String, dynamic>, queryResult)));
  }
  return <T>[];
}

Stream<List<T>> toListDataStream<T>(Stream<QueryResult> queryResult,
    QueryResultToTypedData<T> fromJson, String key) {
  return queryResult.map((result) => toListData(result, fromJson, key));
}
