import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Future<Database> open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'customer_followup.db'),
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, company TEXT)');
        await db.execute('CREATE TABLE followups(id INTEGER PRIMARY KEY AUTOINCREMENT, customerId INTEGER, note TEXT, date TEXT)');
        await db.execute('CREATE TABLE appointments(id INTEGER PRIMARY KEY AUTOINCREMENT, customerId INTEGER, dateTime TEXT, description TEXT)');
        await db.execute('CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, customerId INTEGER, description TEXT, completed INTEGER)');
      },
      version: 1,
    );
  }
}
