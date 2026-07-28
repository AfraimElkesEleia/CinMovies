import 'package:cinmovies_app/core/config/env_config.dart';
import 'package:cinmovies_app/core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract class DioClientFactory {
  static Dio createTmdb({String? accessToken}) {
    final token = accessToken ?? EnvConfig.tmdbAccessToken;
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _addSafeDebugLogging(dio);
    return dio;
  }

  static Dio createGemini({String? apiKey}) {
    final key = apiKey ?? EnvConfig.geminiApiKey;
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.geminiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 20),
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        headers: {
          'Accept': 'application/json',
          'x-goog-api-key': key,
        },
      ),
    );
    _addSafeDebugLogging(dio);
    return dio;
  }

  static void _addSafeDebugLogging(Dio dio) {
    if (!kDebugMode) return;
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }
}
