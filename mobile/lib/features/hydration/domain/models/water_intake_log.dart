class WaterIntakeEntry {
  final int? id;
  final String userId;
  final int amountMl;
  final DateTime timestamp;
  final String source; // 'reminder_alarm', 'manual', 'quick_action'

  const WaterIntakeEntry({
    this.id,
    required this.userId,
    required this.amountMl,
    required this.timestamp,
    this.source = 'manual',
  });

  factory WaterIntakeEntry.fromJson(Map<String, dynamic> json) {
    return WaterIntakeEntry(
      id: json['id'] as int?,
      userId: json['userId'] as String,
      amountMl: json['amountMl'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amountMl': amountMl,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  WaterIntakeEntry copyWith({
    int? id,
    String? userId,
    int? amountMl,
    DateTime? timestamp,
    String? source,
  }) {
    return WaterIntakeEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amountMl: amountMl ?? this.amountMl,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }
}
