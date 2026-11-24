import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;
  Future<void> signIn(String email, String password) async =>
      _client.auth.signInWithPassword(email: email.trim(), password: password);
  Future<void> signOut() => _client.auth.signOut();
}

String readableAuthError(Object error) {
  if (error is AuthException && error.statusCode == '400') {
    return 'E-mail ou senha inválidos.';
  }
  if (error is AuthException && error.statusCode == '429') {
    return 'Muitas tentativas. Aguarde e tente novamente.';
  }
  return 'Não foi possível acessar sua conta. Verifique a conexão e tente novamente.';
}
