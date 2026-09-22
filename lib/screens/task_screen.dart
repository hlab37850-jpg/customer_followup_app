import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المهام')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _add(context),
          child: const Icon(Icons.add),
        ),
        body: p.tasks.isEmpty
            ? const Center(child: Text('لا توجد بيانات'))
            : ListView.builder(
                itemCount: p.tasks.length,
                itemBuilder: (_, i) {
                  final item = p.tasks[i];
                  return Dismissible(
                    key: ValueKey(item.id),
                    onDismissed: (_) {
                      if (item.id != null) p.deleteTask(item.id!);
                    },
                    child: CheckboxListTile(
                      value: item.completed,
                      onChanged: (_) => p.toggleTask(item),
                      title: Text(
                        item.description,
                        style: TextStyle(
                          decoration: item.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final p = context.read<AppProvider>();
    final description = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مهمة'),
        content: TextField(
          controller: description,
          decoration: const InputDecoration(labelText: 'المهمة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );

    if (ok == true && description.text.trim().isNotEmpty && context.mounted) {
      await p.addTask(
        Task(
          customerId: p.customers.isEmpty ? null : p.customers.first.id,
          description: description.text.trim(),
        ),
      );
    }
  }
}
