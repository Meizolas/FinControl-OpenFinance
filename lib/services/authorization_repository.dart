import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/authorization_v2.dart';

class AuthorizationRepository {
  AuthorizationRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;
  Future<List<Authorization>> listMine() async {
    await _client.rpc('refresh_my_authorization_expirations');
    final rows = await _client
        .from('authorizations')
        .select(
          'id,purpose,data_categories,accepted_at,valid_until,status,'
          'terms_version,revoked_at,institutions(name)',
        )
        .order('accepted_at', ascending: false);
    return (rows as List)
        .map((row) => Authorization.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<AuthorizationEvent>> listEvents(String authorizationId) async {
    final rows = await _client
        .from('authorization_events')
        .select('event_type,occurred_at,details')
        .eq('authorization_id', authorizationId)
        .order('occurred_at', ascending: false);
    return (rows as List)
        .map((row) => AuthorizationEvent.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> revoke(String authorizationId) => _client.rpc(
    'revoke_authorization',
    params: {'p_authorization_id': authorizationId},
  );

  Future<FinancialSnapshot> synchronize(String authorizationId) async {
    final result = await _client.rpc(
      'get_simulated_financial_data',
      params: {'p_authorization_id': authorizationId},
    );
    return FinancialSnapshot.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<List<Institution>> listInstitutions() async {
    final rows = await _client
        .from('institutions')
        .select('id,name')
        .order('name');
    return (rows as List)
        .map((row) => Institution.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String institutionId,
    required String purpose,
    required List<String> categories,
    required DateTime validUntil,
  }) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) throw const AuthException('Sessão expirada.');
    await _client.from('authorizations').insert({
      'owner_id': ownerId,
      'institution_id': institutionId,
      'purpose': purpose.trim(),
      'data_categories': categories,
      'valid_until': validUntil.toUtc().toIso8601String(),
      'terms_version': '1.0',
    });
  }
}

String readableAuthorizationError(Object error) {
  if (error is PostgrestException) {
    if (error.code == 'P0001') {
      return 'A autorização não está ativa, já expirou ou não pertence a esta conta.';
    }
    if (error.code == '42501') {
      return 'O backend bloqueou esta operação por falta de permissão.';
    }
    return 'Supabase (${error.code ?? 'sem código'}): ${error.message}';
  }
  if (error is AuthException) {
    return 'Sua sessão expirou. Saia e entre novamente.';
  }
  return 'Falha inesperada ao acessar o backend.';
}
