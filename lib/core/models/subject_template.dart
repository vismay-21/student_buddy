/// Stores subject details that can be reused as a template
/// when adding the same subject on a different day.
class SubjectTemplate {
  final String name;
  final String room;
  final String teacher;
  final int colorValue;

  const SubjectTemplate({
    required this.name,
    required this.room,
    required this.teacher,
    required this.colorValue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectTemplate && name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;
}
