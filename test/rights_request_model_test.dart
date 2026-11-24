import 'package:fincontrol/models/rights_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a titular rights request without encrypted details', () {
    final request = RightsRequest.fromJson({
      'id': '6b487d9d-9cc8-441e-b76f-91f95e5a4186',
      'protocol': 'FC-20261124-A1B2C3D4',
      'request_type': 'deletion',
      'status': 'submitted',
      'created_at': '2026-11-24T12:00:00Z',
    });
    expect(request.protocol, startsWith('FC-'));
    expect(request.type, 'deletion');
  });

  test('maps a support item with a masked owner identifier', () {
    final item = SupportQueueItem.fromJson({
      'request_id': '6b487d9d-9cc8-441e-b76f-91f95e5a4186',
      'protocol': 'FC-20261124-A1B2C3D4',
      'masked_owner': 'a1b2c3***',
      'request_type': 'access',
      'details': 'Pedido acadêmico fictício.',
      'status': 'in_review',
      'created_at': '2026-11-24T12:00:00Z',
    });
    expect(item.maskedOwner, endsWith('***'));
    expect(item.status, 'in_review');
  });
}
