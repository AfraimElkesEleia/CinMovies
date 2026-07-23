import 'package:cinmovies_app/core/error/core_exception_error_mapper.dart';
import 'package:cinmovies_app/core/error/dio_error_mapper.dart';
import 'package:cinmovies_app/core/error/error_mapper.dart';
import 'package:cinmovies_app/core/error/failures.dart';
import 'package:cinmovies_app/core/error/supabase_auth_error_mapper.dart';
import 'package:cinmovies_app/core/error/supabase_postgrest_error_mapper.dart';
import 'package:cinmovies_app/core/error/supabase_storage_error_mapper.dart';

const ErrorMapperRegistry defaultErrorMapper = ErrorMapperRegistry([
  CoreExceptionErrorMapper(),
  SupabaseAuthErrorMapper(),
  SupabasePostgrestErrorMapper(),
  SupabaseStorageErrorMapper(),
  DioErrorMapper(),
]);

Failure mapExceptionToFailure(Object exception) {
  return defaultErrorMapper.map(exception);
}

