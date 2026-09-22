import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      notifications = p.getBool('notifications') ?? true;
    });
  }

  Future<void> _save(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifications', value);
    setState(() => notifications = value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('التنبيهات'),
              subtitle: const Text('تفعيل إعدادات التنبيهات المحلية'),
              value: notifications,
              onChanged: _save,
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('عن التطبيق'),
              subtitle: Text('تطبيق إدارة ومتابعة العملاء'),
            ),
          ],
        ),
      ),
    );
  }
}
