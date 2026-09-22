import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/followup.dart';
import '../providers/app_provider.dart';
import '../widgets/followup_tile.dart';

class FollowupScreen extends StatelessWidget {
  const FollowupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المتابعات')),
        floatingActionButton: FloatingActionButton(
          onPressed: p.customers.isEmpty
              ? null
              : () => _add(context),
          child: const Icon(Icons.add),
        ),
        body: p.followups.isEmpty
            ? const Center(child: Text('لا توجد بيانات'))
            : ListView.builder(
                itemCount: p.followups.length,
                itemBuilder: (_, i) => Dismissible(
                  key: ValueKey(p.followups[i].id),
                  onDismissed: (_) {
                    final id = p.followups[i].id;
                    if (id != null) p.deleteFollowup(id);
                  },
                  child: FollowupTile(followup: p.followups[i]),
                ),
              ),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final p = context.read<AppProvider>();
    int customerId = p.customers.first.id!;
    final note = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة متابعة'),
        content: TextField(
          controller: note,
          decoration: const InputDecoration(labelText: 'الملاحظة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );

    if (ok == true && note.text.trim().isNotEmpty && context.mounted) {
      await p.addFollowup(
        Followup(
          customerId: customerId,
          note: note.text.trim(),
          date: DateTime.now(),
        ),
      );
    }
  }
}
