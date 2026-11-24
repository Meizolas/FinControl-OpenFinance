import 'package:fincontrol/models/authorization_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a persisted authorization with lifecycle fields', () {
    final authorization = Authorization.fromJson({
      'id': 'dd1a3d8c-2f74-44e6-95e3-9a708f952577',
      'institutions': {'name': 'Banco Alfa'},
      'purpose': 'Organização financeira pessoal',
      'data_categories': ['Saldo'],
      'accepted_at': '2026-11-24T12:00:00Z',
      'valid_until': '2027-02-22T12:00:00Z',
      'status': 'active',
      'terms_version': '1.0',
      'revoked_at': null,
    });

    expect(authorization.institutionName, 'Banco Alfa');
    expect(authorization.status, 'active');
    expect(authorization.revokedAt, isNull);
  });

  test('maps simulated financial data returned by the backend', () {
    final snapshot = FinancialSnapshot.fromJson({
      'account_alias': 'Conta fictícia • 0001',
      'balance': 2450.75,
      'currency': 'BRL',
      'reference_at': '2026-11-24T12:00:00Z',
      'categories': ['Saldo', 'Transações'],
    });

    expect(snapshot.balance, 2450.75);
    expect(snapshot.categories, contains('Transações'));
  });

  test('maps authorization history events', () {
    final event = AuthorizationEvent.fromJson({
      'event_type': 'revoked',
      'occurred_at': '2026-11-24T12:00:00Z',
      'details': <String, dynamic>{},
    });

    expect(event.type, 'revoked');
    expect(event.details, isEmpty);
  });
}
