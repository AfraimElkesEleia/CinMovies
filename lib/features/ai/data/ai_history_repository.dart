import 'package:cinmovies_app/core/supabase/supabase_database_service.dart';

class AiHistoryRepository {
  const AiHistoryRepository(this._database);

  final SupabaseDatabaseService _database;

  String get _userId {
    final id = _database.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<String> createSession({required String title, String? preview}) async {
    final row = await _database
        .from('ai_chat_sessions')
        .insert({'user_id': _userId, 'title': title, 'preview': preview})
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> addMessage({
    required String sessionId,
    required String role,
    required String content,
  }) {
    return _database.from('ai_chat_messages').insert({
      'session_id': sessionId,
      'user_id': _userId,
      'role': role,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> sessions() async {
    final rows = await _database
        .from('ai_chat_sessions')
        .select('*, ai_chat_messages(*)')
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);
    return rows.map<Map<String, dynamic>>(Map<String, dynamic>.from).toList();
  }
}
