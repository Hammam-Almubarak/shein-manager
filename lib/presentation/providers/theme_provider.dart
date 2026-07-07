import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// وضع الثيم الحالي (فاتح/داكن/حسب النظام) - المستخدم يبدله من شاشة الإعدادات
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
