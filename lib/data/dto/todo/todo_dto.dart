class TodoDto {
  final String todoId;
  final String title;
  final String category; // 'academic', 'personal', 'work', 'health', 'other'
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'pending', 'completed'
  final String createdBy; // 'user', 'bot', 'review_queue'
  final DateTime? dueDatetime;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoDto({
    required this.todoId,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdBy,
    this.dueDatetime,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoDto.fromJson(Map<String, dynamic> json) {
    return TodoDto(
      todoId: json['todo_id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'other',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      createdBy: json['created_by'] as String? ?? 'user',
      dueDatetime: json['due_datetime'] != null ? DateTime.parse(json['due_datetime'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todo_id': todoId,
      'title': title,
      'category': category,
      'priority': priority,
      'status': status,
      'created_by': createdBy,
      'due_datetime': dueDatetime?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class TodoCreateRequest {
  final String title;
  final String category;
  final String priority;
  final String status;
  final DateTime? dueDatetime;

  TodoCreateRequest({
    required this.title,
    this.category = 'other',
    this.priority = 'medium',
    this.status = 'pending',
    this.dueDatetime,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'category': category,
      'priority': priority,
      'status': status,
    };
    if (dueDatetime != null) {
      data['due_datetime'] = dueDatetime!.toIso8601String();
    }
    return data;
  }
}

class TodoUpdateRequest {
  final String? title;
  final String? category;
  final String? priority;
  final String? status;
  final DateTime? dueDatetime;

  TodoUpdateRequest({
    this.title,
    this.category,
    this.priority,
    this.status,
    this.dueDatetime,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (category != null) data['category'] = category;
    if (priority != null) data['priority'] = priority;
    if (status != null) data['status'] = status;
    if (dueDatetime != null) data['due_datetime'] = dueDatetime!.toIso8601String();
    return data;
  }
}
