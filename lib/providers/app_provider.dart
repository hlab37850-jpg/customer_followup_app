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
