import '../database/app_database.dart';
import '../models/appointment.dart';

class AppointmentRepository {
  Future<List<Appointment>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('appointments', orderBy: 'date_time ASC');
    return rows.map(Appointment.fromMap).toList();
  }

  Future<int> insert(Appointment item) async {
    final db = await AppDatabase.instance.database;
    return db.insert('appointments', item.toMap());
  }

  Future<int> update(Appointment item) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'appointments',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }
}
