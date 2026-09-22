import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  Future<File> databaseFile() async {
    final directory = await getDatabasesPath();
    return File(join(directory, 'customer_followup.db'));
  }

  Future<File> createBackup(Directory destination) async {
    final source = await databaseFile();

    if (!await source.exists()) {
      throw StateError('قاعدة البيانات غير موجودة');
    }

    await destination.create(recursive: true);

    final target = File(
      join(
        destination.path,
        'customer_followup_${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );

    return source.copy(target.path);
  }

  Future<void> restore(File backupFile) async {
    if (!await backupFile.exists()) {
      throw StateError('ملف النسخة الاحتياطية غير موجود');
    }

    final target = await databaseFile();

    if (await target.exists()) {
      await target.delete();
    }

    await backupFile.copy(target.path);
  }
}
