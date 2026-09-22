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
