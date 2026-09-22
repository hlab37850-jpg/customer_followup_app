#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=========================================="
echo " CUSTOMER FOLLOW-UP - FULL REPAIR"
echo "=========================================="

ROOT="$(pwd)"

echo "[1/9] Creating backup..."
tar -czf "../customer_followup_app-before-repair.tar.gz" \
  --exclude='.git' \
  . 2>/dev/null || true

echo "[2/9] Moving the real Flutter project to repository root..."

if [ -d "customer_followup_app/android" ]; then
    rm -rf android ios web linux macos windows
    rm -rf lib test
    rm -f pubspec.yaml pubspec.lock analysis_options.yaml .metadata

    cp -a customer_followup_app/android .
    [ -d customer_followup_app/ios ] && cp -a customer_followup_app/ios .
    [ -d customer_followup_app/web ] && cp -a customer_followup_app/web .
    [ -d customer_followup_app/linux ] && cp -a customer_followup_app/linux .
    [ -d customer_followup_app/macos ] && cp -a customer_followup_app/macos .
    [ -d customer_followup_app/windows ] && cp -a customer_followup_app/windows .

    cp -a customer_followup_app/.gitignore .
    cp -a customer_followup_app/analysis_options.yaml .
fi

rm -rf customer_followup_app

echo "[3/9] Creating Flutter application files..."

mkdir -p lib/database
mkdir -p lib/models
mkdir -p lib/providers
mkdir -p lib/repositories
mkdir -p lib/screens
mkdir -p lib/services
mkdir -p lib/utils
mkdir -p lib/widgets
mkdir -p test
mkdir -p .github/workflows

cat > pubspec.yaml <<'EOF'
name: customer_followup_app
description: Arabic customer follow-up management application.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.3.3+1
  path: ^1.9.0
  flutter_local_notifications: ^17.2.4
  shared_preferences: ^2.3.3
  intl: ^0.19.0
  uuid: ^4.5.1
  url_launcher: ^6.3.1
  timezone: ^0.9.4
  provider: ^6.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
EOF

cat > lib/main.dart <<'EOF'
import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
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
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'متابعة العملاء',
        locale: const Locale('ar'),
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          fontFamily: 'sans',
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
EOF

cat > lib/database/app_database.dart <<'EOF'
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'customer_followup.db');

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
            'ALTER TABLE followups ADD COLUMN status TEXT NOT NULL DEFAULT "pending"',
          );
        }
      },
    );

    return _db!;
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

cat > lib/models/customer.dart <<'EOF'
class Customer {
  final int? id;
  final String name;
  final String phone;
  final String company;
  final String notes;
  final String createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.company,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'company': company,
        'notes': notes,
        'created_at': createdAt,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        company: map['company'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        createdAt: map['created_at'] as String? ?? '',
      );
}
EOF

cat > lib/models/appointment.dart <<'EOF'
class Appointment {
  final int? id;
  final int customerId;
  final DateTime dateTime;
  final String description;

  const Appointment({
    this.id,
    required this.customerId,
    required this.dateTime,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'date_time': dateTime.toIso8601String(),
        'description': description,
      };

  factory Appointment.fromMap(Map<String, dynamic> map) => Appointment(
        id: map['id'] as int?,
        customerId: map['customer_id'] as int,
        dateTime: DateTime.parse(map['date_time'] as String),
        description: map['description'] as String? ?? '',
      );
}
EOF

cat > lib/models/followup.dart <<'EOF'
class Followup {
  final int? id;
  final int customerId;
  final String note;
  final DateTime date;
  final String status;

  const Followup({
    this.id,
    required this.customerId,
    required this.note,
    required this.date,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'note': note,
        'date': date.toIso8601String(),
        'status': status,
      };

  factory Followup.fromMap(Map<String, dynamic> map) => Followup(
        id: map['id'] as int?,
        customerId: map['customer_id'] as int,
        note: map['note'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
        status: map['status'] as String? ?? 'pending',
      );
}
EOF

cat > lib/models/task.dart <<'EOF'
class Task {
  final int? id;
  final int? customerId;
  final String description;
  final DateTime? dueDate;
  final bool completed;

  const Task({
    this.id,
    this.customerId,
    required this.description,
    this.dueDate,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'completed': completed ? 1 : 0,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as int?,
        customerId: map['customer_id'] as int?,
        description: map['description'] as String? ?? '',
        dueDate: map['due_date'] == null
            ? null
            : DateTime.tryParse(map['due_date'] as String),
        completed: (map['completed'] as int? ?? 0) == 1,
      );
}
EOF

cat > lib/repositories/customer_repository.dart <<'EOF'
import '../database/app_database.dart';
import '../models/customer.dart';

class CustomerRepository {
  Future<List<Customer>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('customers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<int> insert(Customer customer) async {
    final db = await AppDatabase.instance.database;
    return db.insert('customers', customer.toMap());
  }

  Future<int> update(Customer customer) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
EOF

cat > lib/repositories/appointment_repository.dart <<'EOF'
import '../database/app_database.dart';
import '../models/appointment.dart';

class AppointmentRepository {
  Future<List<Appointment>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('appointments', orderBy: 'date_time ASC');
    return rows.map(Appointment.fromMap).toList();
  }

  Future<int> insert(Appointment item) async {
    final db = await AppDatabase.instance.database;
    return db.insert('appointments', item.toMap());
  }

  Future<int> update(Appointment item) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'appointments',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }
}
EOF

cat > lib/repositories/followup_repository.dart <<'EOF'
import '../database/app_database.dart';
import '../models/followup.dart';

class FollowupRepository {
  Future<List<Followup>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('followups', orderBy: 'date ASC');
    return rows.map(Followup.fromMap).toList();
  }

  Future<int> insert(Followup item) async {
    final db = await AppDatabase.instance.database;
    return db.insert('followups', item.toMap());
  }

  Future<int> update(Followup item) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'followups',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('followups', where: 'id = ?', whereArgs: [id]);
  }
}
EOF

cat > lib/repositories/task_repository.dart <<'EOF'
import '../database/app_database.dart';
import '../models/task.dart';

class TaskRepository {
  Future<List<Task>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tasks', orderBy: 'completed ASC, due_date ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<int> insert(Task item) async {
    final db = await AppDatabase.instance.database;
    return db.insert('tasks', item.toMap());
  }

  Future<int> update(Task item) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'tasks',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
EOF

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

  Future<void> initialize() async => refresh();

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
    await appointmentsRepo.insert(item);
    await refresh();
  }

  Future<void> deleteAppointment(int id) async {
    await appointmentsRepo.delete(id);
    await refresh();
  }

  Future<void> addFollowup(Followup item) async {
    await followupsRepo.insert(item);
    await refresh();
  }

  Future<void> deleteFollowup(int id) async {
    await followupsRepo.delete(id);
    await refresh();
  }

  Future<void> addTask(Task item) async {
    await tasksRepo.insert(item);
    await refresh();
  }

  Future<void> toggleTask(Task item) async {
    await tasksRepo.update(
      Task(
        id: item.id,
        customerId: item.customerId,
        description: item.description,
        dueDate: item.dueDate,
        completed: !item.completed,
      ),
    );
    await refresh();
  }

  Future<void> deleteTask(int id) async {
    await tasksRepo.delete(id);
    await refresh();
  }
}
EOF

cat > lib/utils/date_utils.dart <<'EOF'
import 'package:intl/intl.dart';

String formatArabicDate(DateTime date) {
  return DateFormat('yyyy/MM/dd', 'ar').format(date);
}

String formatArabicDateTime(DateTime date) {
  return DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(date);
}
EOF

cat > lib/widgets/customer_card.dart <<'EOF'
import 'package:flutter/material.dart';
import '../models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(customer.name),
        subtitle: Text(
          [
            if (customer.phone.isNotEmpty) customer.phone,
            if (customer.company.isNotEmpty) customer.company,
          ].join(' • '),
        ),
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
      ),
    );
  }
}
EOF

cat > lib/widgets/appointment_tile.dart <<'EOF'
import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../utils/date_utils.dart';

class AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  const AppointmentTile({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.event),
      title: Text(formatArabicDateTime(appointment.dateTime)),
      subtitle: Text(appointment.description),
    );
  }
}
EOF

cat > lib/widgets/followup_tile.dart <<'EOF'
import 'package:flutter/material.dart';
import '../models/followup.dart';
import '../utils/date_utils.dart';

class FollowupTile extends StatelessWidget {
  final Followup followup;
  const FollowupTile({super.key, required this.followup});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        followup.status == 'done'
            ? Icons.check_circle
            : Icons.notifications_none,
      ),
      title: Text(formatArabicDate(followup.date)),
      subtitle: Text(followup.note),
    );
  }
}
EOF

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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('متابعة العملاء'),
          actions: [
            IconButton(
              onPressed: p.refresh,
              icon: const Icon(Icons.refresh),
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
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        _stat(context, 'العملاء', p.customers.length,
                            Icons.people),
                        _stat(context, 'المتابعات', p.followups.length,
                            Icons.phone_callback),
                        _stat(context, 'المواعيد', p.appointments.length,
                            Icons.event),
                        _stat(
                          context,
                          'المهام المفتوحة',
                          p.tasks.where((e) => !e.completed).length,
                          Icons.task_alt,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _button(context, 'العملاء', Icons.people,
                        const CustomerScreen()),
                    _button(context, 'المتابعات', Icons.phone_callback,
                        const FollowupScreen()),
                    _button(context, 'المواعيد', Icons.event,
                        const AppointmentScreen()),
                    _button(context, 'المهام', Icons.task_alt,
                        const TaskScreen()),
                    _button(context, 'التقويم', Icons.calendar_month,
                        const CalendarScreen()),
                    _button(context, 'الإعدادات', Icons.settings,
                        const SettingsScreen()),
                  ],
                ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title),
            Text(
              '$value',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}
EOF

cat > lib/screens/customer_screen.dart <<'EOF'
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
EOF

cat > lib/screens/followup_screen.dart <<'EOF'
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
EOF

cat > lib/screens/appointment_screen.dart <<'EOF'
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
EOF

cat > lib/screens/task_screen.dart <<'EOF'
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
EOF

cat > lib/screens/calendar_screen.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/date_utils.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    final events = [
      ...p.appointments.map(
        (e) => (
          date: e.dateTime,
          title: 'موعد: ${e.description}',
        ),
      ),
      ...p.followups.map(
        (e) => (
          date: e.date,
          title: 'متابعة: ${e.note}',
        ),
      ),
      ...p.tasks.where((e) => e.dueDate != null).map(
        (e) => (
          date: e.dueDate!,
          title: 'مهمة: ${e.description}',
        ),
      ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التقويم')),
        body: events.isEmpty
            ? const Center(child: Text('لا توجد بيانات'))
            : ListView.builder(
                itemCount: events.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text(events[i].title),
                  subtitle: Text(formatArabicDateTime(events[i].date)),
                ),
              ),
      ),
    );
  }
}
EOF

cat > lib/screens/settings_screen.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      notifications = p.getBool('notifications') ?? true;
    });
  }

  Future<void> _save(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifications', value);
    setState(() => notifications = value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('التنبيهات'),
              subtitle: const Text('تفعيل إعدادات التنبيهات المحلية'),
              value: notifications,
              onChanged: _save,
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('عن التطبيق'),
              subtitle: Text('تطبيق إدارة ومتابعة العملاء'),
            ),
          ],
        ),
      ),
    );
  }
}
EOF

cat > lib/services/notification_service.dart <<'EOF'
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const settings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: settings),
    );
  }
}
EOF

cat > lib/services/backup_service.dart <<'EOF'
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  Future<File> databaseFile() async {
    final directory = await getDatabasesPath();
    return File(join(directory, 'customer_followup.db'));
  }

  Future<File> createBackup(Directory destination) async {
    final source = await databaseFile();
    if (!await source.exists()) {
      throw StateError('قاعدة البيانات غير موجودة');
    }

    await destination.create(recursive: true);
    final target = File(
      join(
        destination.path,
        'customer_followup_${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );

    return source.copy(target.path);
  }
}
EOF

echo "[4/9] Removing obsolete workflows..."
rm -f .github/workflows/build.yml
rm -f .github/workflows/build-apk.yml
rm -f .github/workflows/android-build.yml

echo "[5/9] Creating single cloud build workflow..."

cat > .github/workflows/android-build.yml <<'EOF'
name: Customer Follow-up Android Build

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Flutter version
        run: flutter --version

      - name: Get dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Test
        run: flutter test

      - name: Build release APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: customer-followup-release
          path: build/app/outputs/flutter-apk/app-release.apk
          if-no-files-found: error
EOF

echo "[6/9] Creating real tests..."

cat > test/model_test.dart <<'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_followup_app/models/customer.dart';
import 'package:customer_followup_app/models/task.dart';

void main() {
  test('Customer map conversion works', () {
    final customer = Customer(
      id: 1,
      name: 'عميل',
      phone: '000',
      company: 'شركة',
      createdAt: DateTime(2026).toIso8601String(),
    );

    final copy = Customer.fromMap(customer.toMap());

    expect(copy.id, 1);
    expect(copy.name, 'عميل');
    expect(copy.phone, '000');
  });

  test('Task completed state is persisted in map', () {
    final task = Task(
      id: 3,
      description: 'اختبار',
      completed: true,
    );

    final map = task.toMap();

    expect(map['completed'], 1);
  });
}
EOF

cat > test/widget_test.dart <<'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_followup_app/app.dart';

void main() {
  testWidgets('Application starts', (tester) async {
    await tester.pumpWidget(const CustomerFollowupApp());
    await tester.pump();

    expect(find.text('لوحة التحكم'), findsOneWidget);
    expect(find.text('متابعة العملاء'), findsOneWidget);
  });
}
EOF

rm -f test/appointment_test.dart
rm -f test/customer_test.dart
rm -f test/followup_test.dart

echo "[7/9] Cleaning generated/obsolete project files..."

find . -name '.DS_Store' -delete
find . -name '*.dart' -size 0 -delete

echo "[8/9] Checking final structure..."

echo
echo "===== EMPTY DART FILES ====="
if find lib -name '*.dart' -type f -size 0 | grep -q .; then
    echo "ERROR: Empty Dart files remain"
    exit 1
else
    echo "OK: No empty Dart files"
fi

echo
echo "===== WORKFLOWS ====="
find .github/workflows -maxdepth 1 -type f -print

echo
echo "===== DART FILE COUNT ====="
find lib -name '*.dart' -type f | wc -l

echo
echo "===== PROJECT ROOT ====="
find . -maxdepth 2 -type f \
  -not -path './.git/*' \
  | sort | head -100

echo "[9/9] Preparing Git commit..."

git add -A

git status --short

git commit -m "Rebuild customer follow-up application"

git push origin main

echo
echo "=========================================="
echo " REPAIR PUSHED SUCCESSFULLY"
echo "=========================================="
echo
echo "Run:"
echo "gh run list --repo hlab37850-jpg/customer_followup_app --limit 5"
