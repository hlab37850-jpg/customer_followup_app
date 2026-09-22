import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/app_provider.dart';

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

    final items = p.customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.company.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('العملاء')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCustomer(context),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة عميل'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'البحث بالاسم أو الهاتف أو الشركة',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('لا توجد بيانات'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final c = items[i];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              c.name.isEmpty ? '?' : c.name.characters.first,
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text([
                            if (c.phone.isNotEmpty) c.phone,
                            if (c.company.isNotEmpty) c.company,
                            if (c.notes.isNotEmpty) c.notes,
                          ].join(' • ')),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editCustomer(context, customer: c);
                              } else {
                                _delete(context, c);
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
          ),
        ],
      ),
    );
  }

  Future<void> _editCustomer(
    BuildContext context, {
    Customer? customer,
  }) async {
    final name = TextEditingController(text: customer?.name ?? '');
    final phone = TextEditingController(text: customer?.phone ?? '');
    final company = TextEditingController(text: customer?.company ?? '');
    final notes = TextEditingController(text: customer?.notes ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(customer == null ? 'إضافة عميل' : 'تعديل العميل'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم العميل *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: company,
                decoration: const InputDecoration(labelText: 'الشركة'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
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
    );

    if (ok != true || name.text.trim().isEmpty || !context.mounted) return;

    final item = Customer(
      id: customer?.id,
      name: name.text.trim(),
      phone: phone.text.trim(),
      company: company.text.trim(),
      notes: notes.text.trim(),
      createdAt:
          customer?.createdAt ?? DateTime.now().toIso8601String(),
    );

    final p = context.read<AppProvider>();

    if (customer == null) {
      await p.addCustomer(item);
    } else {
      await p.updateCustomer(item);
    }
  }

  Future<void> _delete(
    BuildContext context,
    Customer customer,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text(
          'سيتم حذف العميل "${customer.name}" وكل المتابعات والمواعيد المرتبطة به.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (ok == true && customer.id != null && context.mounted) {
      await context.read<AppProvider>().deleteCustomer(customer.id!);
    }
  }
}
