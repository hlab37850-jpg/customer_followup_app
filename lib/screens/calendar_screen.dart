import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/date_utils.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    final events = [
      ...p.appointments.map(
        (e) => (
          date: e.dateTime,
          title: 'موعد: ${e.description}',
        ),
      ),
      ...p.followups.map(
        (e) => (
          date: e.date,
          title: 'متابعة: ${e.note}',
        ),
      ),
      ...p.tasks.where((e) => e.dueDate != null).map(
        (e) => (
          date: e.dueDate!,
          title: 'مهمة: ${e.description}',
        ),
      ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التقويم')),
        body: events.isEmpty
            ? const Center(child: Text('لا توجد بيانات'))
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text(events[i].title),
                  subtitle: Text(formatArabicDateTime(events[i].date)),
                ),
              ),
      ),
    );
  }
}
