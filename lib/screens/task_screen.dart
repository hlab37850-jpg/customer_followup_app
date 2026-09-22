import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/customer.dart';
import '../providers/app_provider.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('المهام')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add_task),
        label: const Text('مهمة جديدة'),
      ),
      body: p.tasks.isEmpty
          ? const Center(child: Text('لا توجد بيانات'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: p.tasks.length,
              itemBuilder: (_, i) {
                final item = p.tasks[i];
                final customer = _customer(
                  p.customers,
                  item.customerId,
                );

                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: item.completed,
                      onChanged: (_) =>
                          p.toggleTask(item),
                    ),
                    title: Text(
                      item.description,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text([
                      if (customer != null)
                        'العميل: ${customer.name}',
                      if (item.dueDate != null)
                        'الاستحقاق: ${DateFormat('yyyy/MM/dd - HH:mm').format(item.dueDate!)}',
                    ].join('\n')),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _edit(context, item: item);
                        } else {
                          p.deleteTask(item.id!);
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
    int? id,
  ) {
    if (id == null) return null;

    for (final c in customers) {
      if (c.id == id) return c;
    }

    return null;
  }

  Future<void> _edit(
    BuildContext context, {
    Task? item,
  }) async {
    final p = context.read<AppProvider>();

    int? customerId = item?.customerId;
    DateTime? dueDate = item?.dueDate;
    final description =
        TextEditingController(text: item?.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'إضافة مهمة' : 'تعديل المهمة'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int?>(
                  value: customerId,
                  decoration: const InputDecoration(
                    labelText: 'العميل (اختياري)',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('بدون عميل'),
                    ),
                    ...p.customers.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setDialogState(() => customerId = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'المهمة *',
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('موعد الاستحقاق'),
                  subtitle: Text(
                    dueDate == null
                        ? 'غير محدد'
                        : DateFormat(
                            'yyyy/MM/dd - HH:mm',
                          ).format(dueDate!),
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final initial =
                              dueDate ?? DateTime.now();

                          final d = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (d == null) return;

                          final t = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(initial),
                          );

                          if (t != null) {
                            setDialogState(() {
                              dueDate = DateTime(
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
                      if (dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setDialogState(() => dueDate = null);
                          },
                        ),
                    ],
                  ),
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

    if (result != true ||
        description.text.trim().isEmpty ||
        !context.mounted) {
      return;
    }

    final value = Task(
      id: item?.id,
      customerId: customerId,
      description: description.text.trim(),
      dueDate: dueDate,
      completed: item?.completed ?? false,
    );

    if (item == null) {
      await p.addTask(value);
    } else {
      await p.updateTask(value);
    }
  }
}
