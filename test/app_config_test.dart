import 'package:fincontrol/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rejects missing config',
    () => expect(
      const AppConfig(supabaseUrl: '', supabaseAnonKey: '').isValid,
      isFalse,
    ),
  );
  test(
    'accepts public config',
    () => expect(
      const AppConfig(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'public-key',
      ).isValid,
      isTrue,
    ),
  );
}
