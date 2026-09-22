import '../database/app_database.dart';
import '../models/task.dart';

class TaskRepository {
  Future<List<Task>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tasks', orderBy: 'completed ASC, due_date ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<int> insert(Task item) async {
    final db = await AppDatabase.instance.database;
    return db.insert('tasks', item.toMap());
  }

  Future<int> update(Task item) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'tasks',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
