import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    final day = DateTime(
      selected.year,
      selected.month,
      selected.day,
    );

    final events = <_Event>[];

    for (final a in p.appointments) {
      if (_sameDay(a.dateTime, day)) {
        events.add(
          _Event(
            a.dateTime,
            'موعد',
            a.description.isEmpty
                ? 'موعد عميل'
                : a.description,
            Icons.event,
          ),
        );
      }
    }

    for (final f in p.followups) {
      if (_sameDay(f.date, day)) {
        events.add(
          _Event(
            f.date,
            'متابعة',
            f.note,
            Icons.phone_callback,
          ),
        );
      }
    }

    for (final t in p.tasks) {
      if (t.dueDate != null &&
          _sameDay(t.dueDate!, day)) {
        events.add(
          _Event(
            t.dueDate!,
            'مهمة',
            t.description,
            Icons.task_alt,
          ),
        );
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: const Text('التقويم')),
      body: ListView(
        children: [
          CalendarDatePicker(
            initialDate: selected,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              setState(() => selected = date);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat(
                'EEEE yyyy/MM/dd',
                'ar',
              ).format(selected),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('لا توجد أحداث في هذا اليوم'),
              ),
            )
          else
            ...events.map(
              (e) => Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: Icon(e.icon),
                  title: Text(e.title),
                  subtitle: Text(e.description),
                  trailing: Text(
                    DateFormat('HH:mm').format(e.date),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}

class _Event {
  final DateTime date;
  final String title;
  final String description;
  final IconData icon;

  const _Event(
    this.date,
    this.title,
    this.description,
    this.icon,
  );
}
