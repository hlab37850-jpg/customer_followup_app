import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/app_provider.dart';
import '../widgets/customer_card.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final q = search.text.trim().toLowerCase();

    final items = p.customers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.company.toLowerCase().contains(q))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('العملاء')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addCustomer(context),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'بحث',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (_, i) => CustomerCard(
                        customer: items[i],
                        onDelete: () => _delete(context, items[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustomer(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final company = TextEditingController();
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة عميل'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
              TextField(controller: company, decoration: const InputDecoration(labelText: 'الشركة')),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty && context.mounted) {
      await context.read<AppProvider>().addCustomer(
            Customer(
              name: name.text.trim(),
              phone: phone.text.trim(),
              company: company.text.trim(),
              notes: notes.text.trim(),
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
    }
  }

  Future<void> _delete(BuildContext context, Customer customer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text('هل تريد حذف "${customer.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );

    if (ok == true && customer.id != null && context.mounted) {
      await context.read<AppProvider>().deleteCustomer(customer.id!);
    }
  }
}
