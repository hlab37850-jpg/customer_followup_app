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
