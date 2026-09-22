#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "== إصلاح أخطاء Flutter Analyze =="

# إزالة الاستيراد غير المستخدم
sed -i "/package:sqflite\/sqflite.dart/d" lib/services/backup_service.dart

# Flutter 3.33+ : value -> initialValue في DropdownButtonFormField
sed -i 's/^[[:space:]]*value: /            initialValue: /' lib/screens/appointment_screen.dart
sed -i 's/^[[:space:]]*value: /            initialValue: /' lib/screens/followup_screen.dart
sed -i 's/^[[:space:]]*value: /            initialValue: /' lib/screens/task_screen.dart

# إصلاح const في NotificationService
sed -i 's/AndroidNotificationDetails(/const AndroidNotificationDetails(/' lib/services/notification_service.dart
sed -i 's/AndroidNotificationChannel(/const AndroidNotificationChannel(/' lib/services/notification_service.dart

echo "== تم تطبيق الإصلاحات =="

echo
echo "التغييرات:"
git status --short
