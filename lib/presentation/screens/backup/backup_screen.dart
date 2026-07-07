import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/orders_providers.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/theme/app_colors.dart';

/// شاشة النسخ الاحتياطي والتصدير
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي والتصدير')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- قسم النسخ الاحتياطي ---
          _SectionHeader(
            icon: Icons.cloud_upload_outlined,
            title: 'النسخ الاحتياطي للبيانات',
            subtitle: 'احفظ قاعدة البيانات الكاملة في مكان آمن',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.backup_rounded,
            title: 'إنشاء نسخة احتياطية',
            subtitle: 'يحفظ ملف SQLite الكامل ويفتح نافذة المشاركة',
            color: AppColors.secondary,
            onTap: () => _doAction(
              context: context,
              label: 'جاري إنشاء النسخة الاحتياطية...',
              action: () => BackupService.backup(),
              successMsg: 'تم إنشاء النسخة الاحتياطية بنجاح ✅',
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.restore_rounded,
            title: 'استعادة من نسخة احتياطية',
            subtitle: 'اختر ملف .sqlite لاستعادة بياناتك (يستلزم إعادة تشغيل التطبيق)',
            color: Colors.orange,
            onTap: () => _confirmRestore(context),
          ),

          const SizedBox(height: 28),

          // --- قسم التصدير ---
          _SectionHeader(
            icon: Icons.upload_file_outlined,
            title: 'تصدير البيانات',
            subtitle: 'صدّر طلباتك بتنسيقات مختلفة',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.table_chart_rounded,
            title: 'تصدير إلى Excel',
            subtitle: 'ملف .xlsx يحتوي ملخص الطلبات + تفاصيل المنتجات',
            color: const Color(0xFF1D6F42),
            onTap: () async {
              final ordersAsync = ref.read(ordersListProvider);
              ordersAsync.whenData((orders) {
                if (orders.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا توجد طلبات للتصدير')),
                  );
                  return;
                }
                _doAction(
                  context: context,
                  label: 'جاري تصدير Excel...',
                  action: () => ExportService.exportToExcel(orders),
                  successMsg: 'تم تصدير Excel بنجاح ✅',
                );
              });
            },
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.picture_as_pdf_rounded,
            title: 'تصدير إلى PDF',
            subtitle: 'تقرير PDF احترافي جاهز للطباعة',
            color: const Color(0xFFD32F2F),
            onTap: () async {
              final ordersAsync = ref.read(ordersListProvider);
              ordersAsync.whenData((orders) {
                if (orders.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا توجد طلبات للتصدير')),
                  );
                  return;
                }
                _doAction(
                  context: context,
                  label: 'جاري إنشاء PDF...',
                  action: () => ExportService.exportToPdf(orders),
                  successMsg: 'تم إنشاء PDF بنجاح ✅',
                );
              });
            },
          ),

          const SizedBox(height: 28),

          // تحذير الاستعادة
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تحذير: استعادة النسخة الاحتياطية ستستبدل بياناتك الحالية بالكامل. '
                    'تأكد من إنشاء نسخة احتياطية من البيانات الحالية قبل الاستعادة.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doAction({
    required BuildContext context,
    required String label,
    required Future<void> Function() action,
    required String successMsg,
  }) async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );

    try {
      await action();
      if (context.mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الاستعادة'),
        content: const Text(
          'سيتم استبدال كل بياناتك الحالية بمحتوى ملف النسخة الاحتياطية.\n\n'
          'هذا الإجراء لا يمكن التراجع عنه.\n\n'
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _doAction(
        context: context,
        label: 'جاري استعادة النسخة الاحتياطية...',
        action: () => BackupService.restore(),
        successMsg:
            'تمت الاستعادة. أعد تشغيل التطبيق لتطبيق التغييرات',
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
