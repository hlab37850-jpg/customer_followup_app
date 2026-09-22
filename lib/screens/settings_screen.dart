import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      notifications = p.getBool('notifications') ?? true;
    });
  }

  Future<void> _save(bool value) async {
    final p = await SharedPreferences.getInstance();

    await p.setBool('notifications', value);

    if (!value) {
      await NotificationService.instance.cancelAll();
    }

    if (mounted) {
      setState(() => notifications = value);
    }
  }

  Future<void> _backup() async {
    try {
      setState(() => busy = true);

      final path = await FilePicker.platform.getDirectoryPath();

      if (path == null) return;

      final file = await BackupService().createBackup(
        Directory(path),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء النسخة الاحتياطية:\n${file.path}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل النسخ الاحتياطي: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restore() async {
    try {
      setState(() => busy = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null ||
          result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('استعادة قاعدة البيانات'),
          content: const Text(
            'سيتم استبدال البيانات الحالية بالنسخة الاحتياطية. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('استعادة'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await BackupService().restore(file);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت استعادة قاعدة البيانات بنجاح'),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاستعادة: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('التنبيهات'),
            subtitle: const Text(
              'تنبيهات المواعيد والمتابعات والمهام',
            ),
            value: notifications,
            onChanged: busy ? null : _save,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('نسخ احتياطي'),
            subtitle: const Text(
              'حفظ قاعدة البيانات كملف DB',
            ),
            onTap: busy ? null : _backup,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('استعادة نسخة احتياطية'),
            subtitle: const Text(
              'استبدال قاعدة البيانات الحالية بملف DB',
            ),
            onTap: busy ? null : _restore,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('عن التطبيق'),
            subtitle: Text(
              'تطبيق إدارة ومتابعة العملاء\n'
              'العملاء • المتابعات • المواعيد • المهام • التقويم',
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
