class WaterIntakeEntry {
  final int? id;
  final String? remoteId;
  final String userId;
  final int amountMl;
  final DateTime timestamp;
  final String source; // 'reminder_alarm', 'manual', 'quick_chip', etc.

  const WaterIntakeEntry({
    this.id,
    this.remoteId,
    required this.userId,
    required this.amountMl,
    required this.timestamp,
    this.source = 'manual',
  });

  factory WaterIntakeEntry.fromJson(Map<String, dynamic> json) {
    return WaterIntakeEntry(
      id: json['id'] is int ? json['id'] as int : null,
      remoteId: json['remoteId'] as String? ?? (json['id'] is String ? json['id'] as String : null),
      userId: (json['userId'] ?? json['user_id'] ?? '') as String,
      amountMl: (json['amountMl'] ?? json['amount_ml'] ?? 0) as int,
      timestamp: DateTime.parse((json['timestamp'] ?? json['recordedAt'] ?? json['recorded_at']) as String),
      source: (json['source'] ?? 'manual') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remoteId': remoteId,
      'userId': userId,
      'amountMl': amountMl,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  WaterIntakeEntry copyWith({
    int? id,
    String? remoteId,
    String? userId,
    int? amountMl,
    DateTime? timestamp,
    String? source,
  }) {
    return WaterIntakeEntry(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      userId: userId ?? this.userId,
      amountMl: amountMl ?? this.amountMl,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }
}
