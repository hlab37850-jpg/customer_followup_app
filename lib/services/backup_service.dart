import 'dart:io';
import 'package:path/path.dart';

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
}
