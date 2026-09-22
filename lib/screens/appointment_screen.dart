import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/customer.dart';
import '../providers/app_provider.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('المواعيد')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            p.customers.isEmpty ? null : () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('موعد جديد'),
      ),
      body: p.appointments.isEmpty
          ? const Center(child: Text('لا توجد بيانات'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: p.appointments.length,
              itemBuilder: (_, i) {
                final a = p.appointments[i];
                final c = _customer(p.customers, a.customerId);

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(
                      c?.name ?? 'عميل محذوف',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${a.description.isEmpty ? 'موعد' : a.description}\n'
                      '${DateFormat('yyyy/MM/dd - HH:mm').format(a.dateTime)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _edit(context, item: a);
                        } else {
                          context
                              .read<AppProvider>()
                              .deleteAppointment(a.id!);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('تعديل'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  static Customer? _customer(
    List<Customer> customers,
    int id,
  ) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _edit(
    BuildContext context, {
    Appointment? item,
  }) async {
    final p = context.read<AppProvider>();
    int customerId = item?.customerId ?? p.customers.first.id!;
    DateTime date = item?.dateTime ?? DateTime.now().add(
      const Duration(hours: 1),
    );
    final description =
        TextEditingController(text: item?.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'إضافة موعد' : 'تعديل الموعد'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: customerId,
                  decoration: const InputDecoration(labelText: 'العميل'),
                  items: p.customers
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id!,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => customerId = v);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('التاريخ والوقت'),
                  subtitle: Text(
                    DateFormat('yyyy/MM/dd - HH:mm').format(date),
                  ),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (d == null) return;

                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date),
                    );

                    if (t != null) {
                      setDialogState(() {
                        date = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          t.hour,
                          t.minute,
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !context.mounted) return;

    final value = Appointment(
      id: item?.id,
      customerId: customerId,
      dateTime: date,
      description: description.text.trim(),
    );

    if (item == null) {
      await p.addAppointment(value);
    } else {
      await p.updateAppointment(value);
    }
  }
}
