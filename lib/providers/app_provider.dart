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
