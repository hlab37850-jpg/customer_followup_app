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

    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة العملاء'),
        actions: [
          IconButton(
            onPressed: p.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'إدارة العملاء والمتابعات والمواعيد والمهام',
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _stat(
                        context,
                        'العملاء',
                        p.customers.length,
                        Icons.people,
                      ),
                      _stat(
                        context,
                        'المتابعات',
                        p.followups.length,
                        Icons.phone_callback,
                      ),
                      _stat(
                        context,
                        'المواعيد',
                        p.appointments.length,
                        Icons.event,
                      ),
                      _stat(
                        context,
                        'المهام المفتوحة',
                        p.tasks
                            .where((e) => !e.completed)
                            .length,
                        Icons.task_alt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _button(
                    context,
                    'العملاء',
                    'إضافة وتعديل وبحث العملاء',
                    Icons.people,
                    const CustomerScreen(),
                  ),
                  _button(
                    context,
                    'المتابعات',
                    'جدولة ومتابعة حالة التواصل',
                    Icons.phone_callback,
                    const FollowupScreen(),
                  ),
                  _button(
                    context,
                    'المواعيد',
                    'إدارة مواعيد العملاء',
                    Icons.event,
                    const AppointmentScreen(),
                  ),
                  _button(
                    context,
                    'المهام',
                    'المهام والاستحقاقات',
                    Icons.task_alt,
                    const TaskScreen(),
                  ),
                  _button(
                    context,
                    'التقويم',
                    'عرض الأحداث حسب اليوم',
                    Icons.calendar_month,
                    const CalendarScreen(),
                  ),
                  _button(
                    context,
                    'الإعدادات',
                    'التنبيهات والنسخ الاحتياطي',
                    Icons.settings,
                    const SettingsScreen(),
                  ),
                ],
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
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 7),
            Text(title),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => screen,
            ),
          );
        },
      ),
    );
  }
}
