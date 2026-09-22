import '../database/app_database.dart';
import '../models/customer.dart';

class CustomerRepository {
  Future<List<Customer>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('customers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<int> insert(Customer customer) async {
    final db = await AppDatabase.instance.database;
    return db.insert('customers', customer.toMap());
  }

  Future<int> update(Customer customer) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
