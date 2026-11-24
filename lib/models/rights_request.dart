class RightsRequest {
  const RightsRequest({
    required this.id,
    required this.protocol,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory RightsRequest.fromJson(Map<String, dynamic> json) => RightsRequest(
    id: json['id'] as String,
    protocol: json['protocol'] as String,
    type: json['request_type'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  final String id, protocol, type, status;
  final DateTime createdAt;
}

class SupportQueueItem {
  const SupportQueueItem({
    required this.id,
    required this.protocol,
    required this.maskedOwner,
    required this.type,
    required this.details,
    required this.status,
    required this.createdAt,
  });

  factory SupportQueueItem.fromJson(Map<String, dynamic> json) =>
      SupportQueueItem(
        id: json['request_id'] as String,
        protocol: json['protocol'] as String,
        maskedOwner: json['masked_owner'] as String,
        type: json['request_type'] as String,
        details: json['details'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  final String id, protocol, maskedOwner, type, details, status;
  final DateTime createdAt;
}
