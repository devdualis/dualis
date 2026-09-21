enum ReminderSoundStyle {
  whatsappChime('whatsapp_chime', 'Aviso tipo mensagem (suave)'),
  phoneAlarm('phone_alarm', 'Alarme sonoro');

  final String id;
  final String label;
  const ReminderSoundStyle(this.id, this.label);

  static ReminderSoundStyle fromId(String id) {
    if (id == 'phone_alarm') return ReminderSoundStyle.phoneAlarm;
    return ReminderSoundStyle.whatsappChime;
  }
}

class HydrationSettings {
  final bool reminderEnabled;
  final bool trackingEnabled;
  final ReminderSoundStyle reminderSoundStyle;
  final int dailyTargetMl;
  final List<int> scheduledHours;

  const HydrationSettings({
    this.reminderEnabled = true,
    this.trackingEnabled = true,
    this.reminderSoundStyle = ReminderSoundStyle.whatsappChime,
    this.dailyTargetMl = 2000,
    this.scheduledHours = const [8, 10, 12, 14, 16, 18, 20],
  });

  factory HydrationSettings.fromJson(Map<String, dynamic> json) {
    return HydrationSettings(
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      trackingEnabled: json['trackingEnabled'] as bool? ?? true,
      reminderSoundStyle: ReminderSoundStyle.fromId(
        json['reminderSoundStyle'] as String? ?? 'whatsapp_chime',
      ),
      dailyTargetMl: json['dailyTargetMl'] as int? ?? 2000,
      scheduledHours: (json['scheduledHours'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [8, 10, 12, 14, 16, 18, 20],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminderEnabled': reminderEnabled,
      'trackingEnabled': trackingEnabled,
      'reminderSoundStyle': reminderSoundStyle.id,
      'dailyTargetMl': dailyTargetMl,
      'scheduledHours': scheduledHours,
    };
  }

  HydrationSettings copyWith({
    bool? reminderEnabled,
    bool? trackingEnabled,
    ReminderSoundStyle? reminderSoundStyle,
    int? dailyTargetMl,
    List<int>? scheduledHours,
  }) {
    return HydrationSettings(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      reminderSoundStyle: reminderSoundStyle ?? this.reminderSoundStyle,
      dailyTargetMl: dailyTargetMl ?? this.dailyTargetMl,
      scheduledHours: scheduledHours ?? this.scheduledHours,
    );
  }
}
