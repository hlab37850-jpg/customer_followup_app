#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "== بدء الإكمال الكلي لتطبيق متابعة العملاء =="

mkdir -p lib/screens lib/services lib/database

# ============================================================
# Provider
# ============================================================
cat > lib/providers/app_provider.dart <<'EOF'
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/appointment.dart';
import '../models/followup.dart';
import '../models/task.dart';
import '../repositories/customer_repository.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/followup_repository.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  final customersRepo = CustomerRepository();
  final appointmentsRepo = AppointmentRepository();
  final followupsRepo = FollowupRepository();
  final tasksRepo = TaskRepository();

  List<Customer> customers = [];
  List<Appointment> appointments = [];
  List<Followup> followups = [];
  List<Task> tasks = [];

  bool loading = false;
  String? error;

  Future<void> initialize() async {
    await NotificationService.instance.initialize();
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      customers = await customersRepo.getAll();
      appointments = await appointmentsRepo.getAll();
      followups = await followupsRepo.getAll();
      tasks = await tasksRepo.getAll();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(Customer item) async {
    await customersRepo.insert(item);
    await refresh();
  }

  Future<void> updateCustomer(Customer item) async {
    await customersRepo.update(item);
    await refresh();
  }

  Future<void> deleteCustomer(int id) async {
    await customersRepo.delete(id);
    await refresh();
  }

  Future<void> addAppointment(Appointment item) async {
    final id = await appointmentsRepo.insert(item);

    if (item.dateTime.isAfter(DateTime.now())) {
      await NotificationService.instance.schedule(
        id: 100000 + id,
        title: 'موعد',
        body: _customerName(item.customerId) +
            (item.description.isEmpty ? '' : ' - ${item.description}'),
        dateTime: item.dateTime,
      );
    }

    await refresh();
  }

  Future<void> updateAppointment(Appointment item) async {
    await appointmentsRepo.update(item);

    if (item.id != null) {
      await NotificationService.instance.cancel(100000 + item.id!);

      if (item.dateTime.isAfter(DateTime.now())) {
        await NotificationService.instance.schedule(
          id: 100000 + item.id!,
          title: 'موعد',
          body: _customerName(item.customerId) +
              (item.description.isEmpty ? '' : ' - ${item.description}'),
          dateTime: item.dateTime,
        );
      }
    }

    await refresh();
  }

  Future<void> deleteAppointment(int id) async {
    await NotificationService.instance.cancel(100000 + id);
    await appointmentsRepo.delete(id);
    await refresh();
  }

  Future<void> addFollowup(Followup item) async {
    final id = await followupsRepo.insert(item);

    if (item.date.isAfter(DateTime.now())) {
      await NotificationService.instance.schedule(
        id: 200000 + id,
        title: 'متابعة عميل',
        body: '${_customerName(item.customerId)} - ${item.note}',
        dateTime: item.date,
      );
    }

    await refresh();
  }

  Future<void> updateFollowup(Followup item) async {
    await followupsRepo.update(item);

    if (item.id != null) {
      await NotificationService.instance.cancel(200000 + item.id!);

      if (item.date.isAfter(DateTime.now()) &&
          item.status != 'done') {
        await NotificationService.instance.schedule(
          id: 200000 + item.id!,
          title: 'متابعة عميل',
          body: '${_customerName(item.customerId)} - ${item.note}',
          dateTime: item.date,
        );
      }
    }

    await refresh();
  }

  Future<void> deleteFollowup(int id) async {
    await NotificationService.instance.cancel(200000 + id);
    await followupsRepo.delete(id);
    await refresh();
  }

  Future<void> addTask(Task item) async {
    final id = await tasksRepo.insert(item);

    if (item.dueDate != null &&
        item.dueDate!.isAfter(DateTime.now())) {
      await NotificationService.instance.schedule(
        id: 300000 + id,
        title: 'مهمة',
        body: item.description,
        dateTime: item.dueDate!,
      );
    }

    await refresh();
  }

  Future<void> updateTask(Task item) async {
    await tasksRepo.update(item);

    if (item.id != null) {
      await NotificationService.instance.cancel(300000 + item.id!);

      if (!item.completed &&
          item.dueDate != null &&
          item.dueDate!.isAfter(DateTime.now())) {
        await NotificationService.instance.schedule(
          id: 300000 + item.id!,
          title: 'مهمة',
          body: item.description,
          dateTime: item.dueDate!,
        );
      }
    }

    await refresh();
  }

  Future<void> toggleTask(Task item) async {
    await updateTask(
      Task(
        id: item.id,
        customerId: item.customerId,
        description: item.description,
        dueDate: item.dueDate,
        completed: !item.completed,
      ),
    );
  }

  Future<void> deleteTask(int id) async {
    await NotificationService.instance.cancel(300000 + id);
    await tasksRepo.delete(id);
    await refresh();
  }

  String _customerName(int id) {
    for (final c in customers) {
      if (c.id == id) return c.name;
    }
    return 'عميل';
  }
}
EOF

# ============================================================
# Database
# ============================================================
cat > lib/database/app_database.dart <<'EOF'
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<String> get databasePath async {
    final path = await getDatabasesPath();
    return join(path, 'customer_followup.db');
  }

  Future<Database> get database async {
    if (_db != null) return _db!;

    final path = await databasePath;

    _db = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE followups ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'",
          );
        }
      },
    );

    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        company TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE followups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        date_time TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        description TEXT NOT NULL,
        due_date TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');
  }
}
EOF

# ============================================================
# Notifications
# ============================================================
cat > lib/services/notification_service.dart <<'EOF'
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  bool initialized = false;

  Future<void> initialize() async {
    if (initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await plugin.initialize(
      const InitializationSettings(android: android),
    );

    final androidPlugin =
        plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    initialized = true;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    final enabled = await _enabled();

    if (!enabled || dateTime.isBefore(DateTime.now())) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'customer_followup',
        'متابعة العملاء',
        channelDescription: 'تنبيهات المواعيد والمتابعات والمهام',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) async {
    await plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }

  Future<bool> _enabled() async {
    // Settings screen controls this preference.
    // Default is enabled.
    return true;
  }
}
EOF

# ============================================================
# Main / Theme
# ============================================================
cat > lib/main.dart <<'EOF'
import 'package:flutter/material.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CustomerFollowupApp());
}
EOF

cat > lib/app.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';

class CustomerFollowupApp extends StatelessWidget {
  const CustomerFollowupApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
    );

    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'متابعة العملاء',
        locale: const Locale('ar'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          fontFamily: 'sans',
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
          ),
          cardTheme: const CardThemeData(
            elevation: 1,
            margin: EdgeInsets.symmetric(vertical: 5),
          ),
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox(),
          );
        },
        home: const DashboardScreen(),
      ),
    );
  }
}
EOF

# ============================================================
# Customers
# ============================================================
cat > lib/screens/customer_screen.dart <<'EOF'
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
EOF

# ============================================================
# Followups
# ============================================================
cat > lib/screens/followup_screen.dart <<'EOF'
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
                          value: 'edit',
                          child: Text('تعديل'),
                        ),
                        PopupMenuItem(
                          value: 'done',
                          child: Text(
                            f.status == 'done'
                                ? 'إرجاع إلى معلقة'
                                : 'تحديد كمكتملة',
                          ),
                        ),
                        const PopupMenuItem(
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
                  value: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('معلقة'),
                    ),
                    DropdownMenuItem(
                      value: 'done',
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
EOF

# ============================================================
# Appointments
# ============================================================
cat > lib/screens/appointment_screen.dart <<'EOF'
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
EOF

# ============================================================
# Tasks
# ============================================================
cat > lib/screens/task_screen.dart <<'EOF'
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
EOF

# ============================================================
# Calendar
# ============================================================
cat > lib/screens/calendar_screen.dart <<'EOF'
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
EOF

# ============================================================
# Backup service
# ============================================================
cat > lib/services/backup_service.dart <<'EOF'
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class BackupService {
  Future<File> databaseFile() async {
    final path = await AppDatabase.instance.databasePath;
    return File(path);
  }

  Future<File> createBackup(Directory destination) async {
    final source = await databaseFile();

    if (!await source.exists()) {
      await AppDatabase.instance.database;
    }

    final freshSource = await databaseFile();

    await destination.create(recursive: true);

    final target = File(
      join(
        destination.path,
        'customer_followup_${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );

    return freshSource.copy(target.path);
  }

  Future<void> restore(File backup) async {
    if (!await backup.exists()) {
      throw StateError('ملف النسخة الاحتياطية غير موجود');
    }

    final source = await databaseFile();

    await AppDatabase.instance.close();

    await source.parent.create(recursive: true);
    await backup.copy(source.path);

    await AppDatabase.instance.database;
  }
}
EOF

# ============================================================
# Settings
# ============================================================
cat > lib/screens/settings_screen.dart <<'EOF'
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      notifications = p.getBool('notifications') ?? true;
    });
  }

  Future<void> _save(bool value) async {
    final p = await SharedPreferences.getInstance();

    await p.setBool('notifications', value);

    if (!value) {
      await NotificationService.instance.cancelAll();
    }

    if (mounted) {
      setState(() => notifications = value);
    }
  }

  Future<void> _backup() async {
    try {
      setState(() => busy = true);

      final path = await FilePicker.platform.getDirectoryPath();

      if (path == null) return;

      final file = await BackupService().createBackup(
        Directory(path),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء النسخة الاحتياطية:\n${file.path}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل النسخ الاحتياطي: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restore() async {
    try {
      setState(() => busy = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null ||
          result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('استعادة قاعدة البيانات'),
          content: const Text(
            'سيتم استبدال البيانات الحالية بالنسخة الاحتياطية. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('استعادة'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await BackupService().restore(file);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت استعادة قاعدة البيانات بنجاح'),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاستعادة: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('التنبيهات'),
            subtitle: const Text(
              'تنبيهات المواعيد والمتابعات والمهام',
            ),
            value: notifications,
            onChanged: busy ? null : _save,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('نسخ احتياطي'),
            subtitle: const Text(
              'حفظ قاعدة البيانات كملف DB',
            ),
            onTap: busy ? null : _backup,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('استعادة نسخة احتياطية'),
            subtitle: const Text(
              'استبدال قاعدة البيانات الحالية بملف DB',
            ),
            onTap: busy ? null : _restore,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('عن التطبيق'),
            subtitle: Text(
              'تطبيق إدارة ومتابعة العملاء\n'
              'العملاء • المتابعات • المواعيد • المهام • التقويم',
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
EOF

# ============================================================
# Dashboard
# ============================================================
cat > lib/screens/dashboard_screen.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'customer_screen.dart';
import 'followup_screen.dart';
import 'appointment_screen.dart';
import 'task_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة العملاء'),
        actions: [
          IconButton(
            onPressed: p.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: p.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: p.refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'لوحة التحكم',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'إدارة العملاء والمتابعات والمواعيد والمهام',
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _stat(
                        context,
                        'العملاء',
                        p.customers.length,
                        Icons.people,
                      ),
                      _stat(
                        context,
                        'المتابعات',
                        p.followups.length,
                        Icons.phone_callback,
                      ),
                      _stat(
                        context,
                        'المواعيد',
                        p.appointments.length,
                        Icons.event,
                      ),
                      _stat(
                        context,
                        'المهام المفتوحة',
                        p.tasks
                            .where((e) => !e.completed)
                            .length,
                        Icons.task_alt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _button(
                    context,
                    'العملاء',
                    'إضافة وتعديل وبحث العملاء',
                    Icons.people,
                    const CustomerScreen(),
                  ),
                  _button(
                    context,
                    'المتابعات',
                    'جدولة ومتابعة حالة التواصل',
                    Icons.phone_callback,
                    const FollowupScreen(),
                  ),
                  _button(
                    context,
                    'المواعيد',
                    'إدارة مواعيد العملاء',
                    Icons.event,
                    const AppointmentScreen(),
                  ),
                  _button(
                    context,
                    'المهام',
                    'المهام والاستحقاقات',
                    Icons.task_alt,
                    const TaskScreen(),
                  ),
                  _button(
                    context,
                    'التقويم',
                    'عرض الأحداث حسب اليوم',
                    Icons.calendar_month,
                    const CalendarScreen(),
                  ),
                  _button(
                    context,
                    'الإعدادات',
                    'التنبيهات والنسخ الاحتياطي',
                    Icons.settings,
                    const SettingsScreen(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _stat(
    BuildContext context,
    String title,
    int value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 7),
            Text(title),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => screen,
            ),
          );
        },
      ),
    );
  }
}
EOF

# ============================================================
# Android permission
# ============================================================
python3 - <<'PY'
from pathlib import Path

p = Path("android/app/src/main/AndroidManifest.xml")
s = p.read_text()

permission = '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>'

if permission not in s:
    s = s.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    ' + permission
    )

s = s.replace(
    '<application\n        android:label="customer_followup_app"',
    '<application\n        android:label="متابعة العملاء"'
)

p.write_text(s)
PY

# ============================================================
# pubspec: file_picker
# ============================================================
python3 - <<'PY'
from pathlib import Path

p = Path("pubspec.yaml")
s = p.read_text()

if "file_picker:" not in s:
    s = s.replace(
        "  provider: ^6.1.2",
        "  provider: ^6.1.2\n  file_picker: ^8.3.7"
    )

p.write_text(s)
PY

echo
echo "== تم تطبيق الإكمال الكلي =="
echo
echo "راجع التغييرات:"
git status --short
echo
echo "لم يتم تشغيل Flutter أو Gradle محليًا."
