import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'customer_screen.dart';
import 'followup_screen.dart';
import 'appointment_screen.dart';
import 'task_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('متابعة العملاء'),
          actions: [
            IconButton(
              onPressed: p.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: p.loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: p.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'لوحة التحكم',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        _stat(context, 'العملاء', p.customers.length,
                            Icons.people),
                        _stat(context, 'المتابعات', p.followups.length,
                            Icons.phone_callback),
                        _stat(context, 'المواعيد', p.appointments.length,
                            Icons.event),
                        _stat(
                          context,
                          'المهام المفتوحة',
                          p.tasks.where((e) => !e.completed).length,
                          Icons.task_alt,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _button(context, 'العملاء', Icons.people,
                        const CustomerScreen()),
                    _button(context, 'المتابعات', Icons.phone_callback,
                        const FollowupScreen()),
                    _button(context, 'المواعيد', Icons.event,
                        const AppointmentScreen()),
                    _button(context, 'المهام', Icons.task_alt,
                        const TaskScreen()),
                    _button(context, 'التقويم', Icons.calendar_month,
                        const CalendarScreen()),
                    _button(context, 'الإعدادات', Icons.settings,
                        const SettingsScreen()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String title,
    int value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title),
            Text(
              '$value',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}
