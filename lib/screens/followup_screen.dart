import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/followup.dart';
import '../models/customer.dart';
import '../providers/app_provider.dart';

class FollowupScreen extends StatelessWidget {
  const FollowupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('المتابعات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            p.customers.isEmpty ? null : () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('متابعة جديدة'),
      ),
      body: p.followups.isEmpty
          ? const Center(child: Text('لا توجد بيانات'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: p.followups.length,
              itemBuilder: (_, i) {
                final f = p.followups[i];
                final customer = _customer(p.customers, f.customerId);

                return Card(
                  child: ListTile(
                    leading: Icon(
                      f.status == 'done'
                          ? Icons.check_circle
                          : Icons.phone_callback,
                    ),
                    title: Text(
                      customer?.name ?? 'عميل محذوف',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${f.note}\n${DateFormat('yyyy/MM/dd - HH:mm').format(f.date)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _edit(context, item: f);
                        } else if (v == 'done') {
                          context.read<AppProvider>().updateFollowup(
                                Followup(
                                  id: f.id,
                                  customerId: f.customerId,
                                  note: f.note,
                                  date: f.date,
                                  status: f.status == 'done'
                                      ? 'pending'
                                      : 'done',
                                ),
                              );
                        } else {
                          context.read<AppProvider>().deleteFollowup(f.id!);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
            initialValue: 'edit',
                          child: Text('تعديل'),
                        ),
                        PopupMenuItem(
            initialValue: 'done',
                          child: Text(
                            f.status == 'done'
                                ? 'إرجاع إلى معلقة'
                                : 'تحديد كمكتملة',
                          ),
                        ),
                        const PopupMenuItem(
            initialValue: 'delete',
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
    Followup? item,
  }) async {
    final p = context.read<AppProvider>();
    int customerId = item?.customerId ?? p.customers.first.id!;
    DateTime date = item?.date ?? DateTime.now();
    final note = TextEditingController(text: item?.note ?? '');
    String status = item?.status ?? 'pending';

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'إضافة متابعة' : 'تعديل المتابعة'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
            initialValue: customerId,
                  decoration: const InputDecoration(labelText: 'العميل'),
                  items: p.customers
                      .map(
                        (c) => DropdownMenuItem(
            initialValue: c.id!,
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
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'الملاحظة *',
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('موعد المتابعة'),
                  subtitle: Text(
                    DateFormat('yyyy/MM/dd - HH:mm').format(date),
                  ),
                  trailing: const Icon(Icons.calendar_month),
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
                DropdownButtonFormField<String>(
            initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [
                    DropdownMenuItem(
            initialValue: 'pending',
                      child: Text('معلقة'),
                    ),
                    DropdownMenuItem(
            initialValue: 'done',
                      child: Text('مكتملة'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => status = v);
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

    if (result != true || note.text.trim().isEmpty || !context.mounted) {
      return;
    }

    final value = Followup(
      id: item?.id,
      customerId: customerId,
      note: note.text.trim(),
      date: date,
      status: status,
    );

    if (item == null) {
      await p.addFollowup(value);
    } else {
      await p.updateFollowup(value);
    }
  }
}
