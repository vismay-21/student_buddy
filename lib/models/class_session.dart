class ClassSession {
  final int? id;
  final int subjectId;
  final int dayIndex;
  final String startTime;
  final String endTime;

  ClassSession({
    this.id,
    required this.subjectId,
    required this.dayIndex,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'day_index': dayIndex,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  factory ClassSession.fromMap(Map<String, dynamic> map) {
    return ClassSession(
      id: map['id'],
      subjectId: map['subject_id'],
      dayIndex: map['day_index'],
      startTime: map['start_time'],
      endTime: map['end_time'],
    );
  }
}
