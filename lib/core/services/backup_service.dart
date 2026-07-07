import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// خدمة النسخ الاحتياطي: تنسخ ملف SQLite الكامل للمشاركة/الاسترجاع
class BackupService {
  static const _dbFileName = 'shein_manager.sqlite';

  /// مسار قاعدة البيانات الحالية
  static Future<String> _dbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbFileName);
  }

  /// إنشاء نسخة احتياطية ومشاركتها (يفتح نافذة المشاركة)
  static Future<void> backup() async {
    final dbPath = await _dbPath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw StateError('ملف قاعدة البيانات غير موجود: $dbPath');
    }

    // نسخ الملف إلى مجلد مؤقت باسم يتضمن التاريخ والوقت
    final tempDir = await getTemporaryDirectory();
    final timestamp =
        DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final backupFileName = 'shein_manager_backup_$timestamp.sqlite';
    final backupPath = p.join(tempDir.path, backupFileName);

    await dbFile.copy(backupPath);

    // مشاركة الملف عبر نافذة مشاركة النظام
    await Share.shareXFiles(
      [XFile(backupPath, mimeType: 'application/octet-stream')],
      subject: 'نسخة احتياطية - إدارة طلبات SHEIN',
    );
  }

  /// استعادة قاعدة البيانات من ملف نسخة احتياطية
  /// ⚠️ يجب إعادة تشغيل التطبيق بعد الاستعادة لإعادة تهيئة الاتصال
  static Future<void> restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      dialogTitle: 'اختر ملف النسخة الاحتياطية (.sqlite)',
    );

    if (result == null || result.files.single.path == null) return;

    final sourcePath = result.files.single.path!;
    // التحقق من أن الملف هو قاعدة بيانات SQLite صحيحة
    final sourceFile = File(sourcePath);
    final header = await _readFileHeader(sourceFile);
    if (!header.startsWith('SQLite format 3')) {
      throw FormatException(
          'الملف المختار ليس قاعدة بيانات SQLite صحيحة');
    }

    final dbPath = await _dbPath();
    await sourceFile.copy(dbPath);
  }

  static Future<String> _readFileHeader(File file) async {
    try {
      final bytes = await file.openRead(0, 16).toList();
      final allBytes = bytes.expand((b) => b).toList();
      return String.fromCharCodes(allBytes);
    } catch (_) {
      return '';
    }
  }
}
