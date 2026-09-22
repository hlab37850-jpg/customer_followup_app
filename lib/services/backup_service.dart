import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class BackupService {
  Future<File> databaseFile() async {
    final path = await AppDatabase.instance.databasePath;
    return File(path);
  }

  Future<File> createBackup(Directory destination) async {
    final source = await databaseFile();

    if (!await source.exists()) {
      await AppDatabase.instance.database;
    }

    final freshSource = await databaseFile();

    await destination.create(recursive: true);

    final target = File(
      join(
        destination.path,
        'customer_followup_${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );

    return freshSource.copy(target.path);
  }

  Future<void> restore(File backup) async {
    if (!await backup.exists()) {
      throw StateError('ملف النسخة الاحتياطية غير موجود');
    }

    final source = await databaseFile();

    await AppDatabase.instance.close();

    await source.parent.create(recursive: true);
    await backup.copy(source.path);

    await AppDatabase.instance.database;
  }
}
