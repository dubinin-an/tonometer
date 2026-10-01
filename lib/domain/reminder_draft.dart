class ReminderDraft {
  const ReminderDraft({
    required this.hour,
    required this.minute,
    required this.weekdaysMask,
    required this.enabled,
  });

  final int hour;
  final int minute;
  final int weekdaysMask;
  final bool enabled;
}
