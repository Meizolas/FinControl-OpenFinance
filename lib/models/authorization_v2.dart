class Authorization {
  const Authorization({
    required this.id,
    required this.institutionName,
    required this.purpose,
    required this.dataCategories,
    required this.acceptedAt,
    required this.validUntil,
    required this.status,
    required this.termsVersion,
    this.revokedAt,
  });

  factory Authorization.fromJson(Map<String, dynamic> json) => Authorization(
    id: json['id'] as String,
    institutionName:
        (json['institutions'] as Map<String, dynamic>)['name'] as String,
    purpose: json['purpose'] as String,
    dataCategories: List<String>.from(json['data_categories'] as List),
    acceptedAt: DateTime.parse(json['accepted_at'] as String).toLocal(),
    validUntil: DateTime.parse(json['valid_until'] as String).toLocal(),
    status: json['status'] as String,
    termsVersion: json['terms_version'] as String,
    revokedAt: json['revoked_at'] == null
        ? null
        : DateTime.parse(json['revoked_at'] as String).toLocal(),
  );

  final String id, institutionName, purpose, status, termsVersion;
  final List<String> dataCategories;
  final DateTime acceptedAt, validUntil;
  final DateTime? revokedAt;

  bool get isActive => status == 'active' && validUntil.isAfter(DateTime.now());
}

class AuthorizationEvent {
  const AuthorizationEvent({
    required this.type,
    required this.occurredAt,
    required this.details,
  });

  factory AuthorizationEvent.fromJson(Map<String, dynamic> json) =>
      AuthorizationEvent(
        type: json['event_type'] as String,
        occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
        details: Map<String, dynamic>.from(json['details'] as Map),
      );

  final String type;
  final DateTime occurredAt;
  final Map<String, dynamic> details;
}

class FinancialSnapshot {
  const FinancialSnapshot({
    required this.accountAlias,
    required this.balance,
    required this.currency,
    required this.referenceAt,
    required this.categories,
  });

  factory FinancialSnapshot.fromJson(Map<String, dynamic> json) =>
      FinancialSnapshot(
        accountAlias: json['account_alias'] as String,
        balance: (json['balance'] as num).toDouble(),
        currency: json['currency'] as String,
        referenceAt: DateTime.parse(json['reference_at'] as String).toLocal(),
        categories: List<String>.from(json['categories'] as List),
      );

  final String accountAlias, currency;
  final double balance;
  final DateTime referenceAt;
  final List<String> categories;
}

class Institution {
  const Institution({required this.id, required this.name});
  factory Institution.fromJson(Map<String, dynamic> json) =>
      Institution(id: json['id'] as String, name: json['name'] as String);
  final String id, name;
}
