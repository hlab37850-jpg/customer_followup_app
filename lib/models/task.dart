class Task {
  final int? id;
  final int? customerId;
  final String description;
  final DateTime? dueDate;
  final bool completed;

  const Task({
    this.id,
    this.customerId,
    required this.description,
    this.dueDate,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'completed': completed ? 1 : 0,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as int?,
        customerId: map['customer_id'] as int?,
        description: map['description'] as String? ?? '',
        dueDate: map['due_date'] == null
            ? null
            : DateTime.tryParse(map['due_date'] as String),
        completed: (map['completed'] as int? ?? 0) == 1,
      );
}
