import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rights_request.dart';

class RightsRepository {
  RightsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<List<RightsRequest>> listMine() async {
    final rows = await _client
        .from('rights_requests')
        .select('id,protocol,request_type,status,created_at')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => RightsRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> submit({required String type, required String details}) async {
    final result = await _client.rpc(
      'submit_rights_request',
      params: {'p_request_type': type, 'p_details': details.trim()},
    );
    return result as String;
  }

  Future<bool> isSupport() async =>
      (await _client.rpc('is_support')) as bool? ?? false;

  Future<List<SupportQueueItem>> listSupportQueue() async {
    final rows = await _client.rpc('get_support_queue');
    return (rows as List)
        .map((row) => SupportQueueItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(String requestId, String status) => _client.rpc(
    'update_rights_request_status',
    params: {'p_request_id': requestId, 'p_status': status},
  );
}

String readableRightsError(Object error) {
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return 'O backend bloqueou a operação por falta de permissão.';
    }
    if (error.code == '22023') {
      return 'Confira o tipo do pedido e informe entre 10 e 1000 caracteres.';
    }
    return 'Supabase (${error.code ?? 'sem código'}): ${error.message}';
  }
  if (error is AuthException) {
    return 'Sua sessão expirou. Saia e entre novamente.';
  }
  return 'Falha inesperada ao acessar o backend.';
}
