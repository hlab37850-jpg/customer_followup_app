import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../providers/app_provider.dart';
import '../widgets/appointment_tile.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المواعيد')),
        floatingActionButton: FloatingActionButton(
          onPressed: p.customers.isEmpty ? null : () => _add(context),
          child: const Icon(Icons.add),
        ),
        body: p.appointments.isEmpty
            ? const Center(child: Text('لا توجد بيانات'))
            : ListView.builder(
                itemCount: p.appointments.length,
                itemBuilder: (_, i) => Dismissible(
                  key: ValueKey(p.appointments[i].id),
                  onDismissed: (_) {
                    final id = p.appointments[i].id;
                    if (id != null) p.deleteAppointment(id);
                  },
                  child: AppointmentTile(appointment: p.appointments[i]),
                ),
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
        title: const Text('إضافة موعد'),
        content: TextField(
          controller: description,
          decoration: const InputDecoration(labelText: 'الوصف'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await p.addAppointment(
        Appointment(
          customerId: p.customers.first.id!,
          dateTime: DateTime.now(),
          description: description.text.trim(),
        ),
      );
    }
  }
}
