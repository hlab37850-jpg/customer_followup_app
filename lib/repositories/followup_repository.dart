import '../database/app_database.dart';
import '../models/followup.dart';

class FollowupRepository {
  Future<List<Followup>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('followups', orderBy: 'date ASC');
    return rows.map(Followup.fromMap).toList();
  }

  Future<int> insert(Followup item) async {
    final db = await AppDatabase.instance.database;
    return db.insert('followups', item.toMap());
  }

  Future<int> update(Followup item) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'followups',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('followups', where: 'id = ?', whereArgs: [id]);
  }
}
