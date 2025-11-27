class Assignment {
  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool completed;
  final int subjectId;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.completed,
    required this.subjectId,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.tryParse(json['deadline'] ?? '') ?? DateTime.now(),
      completed: json['completed'] ?? false,
      subjectId: json['subjectId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "deadline": dueDate.toIso8601String(),
      "completed": completed,
      "subjectId": subjectId,
    };
  }
}
