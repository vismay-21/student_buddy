class Subject {
  final int? id;
  final String name;
  final String teacher;
  final String room;
  final int color;

  Subject({
    this.id,
    required this.name,
    required this.teacher,
    required this.room,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'room': room,
      'color': color,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      teacher: map['teacher'],
      room: map['room'],
      color: map['color'],
    );
  }
}
