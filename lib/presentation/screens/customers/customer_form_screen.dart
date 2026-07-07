import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/usecase_providers.dart';
import '../../../domain/entities/customer.dart';

/// شاشة نموذج العميل - تعمل بوضعين:
/// - إنشاء عميل جديد: initialCustomer == null
/// - تعديل عميل موجود: initialCustomer != null
class CustomerFormScreen extends ConsumerStatefulWidget {
  /// في وضع التعديل: يُمرَّر customerId + initialCustomer (إن وُجد)
  final int? customerId;
  final Customer? initialCustomer;

  const CustomerFormScreen({
    super.key,
    this.customerId,
    this.initialCustomer,
  });

  bool get isEditMode => initialCustomer != null || customerId != null;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialCustomer?.fullName);
    _phoneCtrl = TextEditingController(text: widget.initialCustomer?.phoneNumber);
    _notesCtrl = TextEditingController(text: widget.initialCustomer?.notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (widget.isEditMode) {
        await ref.read(updateCustomerUseCaseProvider).call(
              widget.initialCustomer!.copyWith(
                fullName: _nameCtrl.text.trim(),
                phoneNumber: _phoneCtrl.text.trim(),
                notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              ),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تعديل بيانات العميل بنجاح')),
          );
          Navigator.pop(context, true);
        }
      } else {
        await ref.read(createCustomerUseCaseProvider).call(
              fullName: _nameCtrl.text.trim(),
              phoneNumber: _phoneCtrl.text.trim(),
              notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة العميل بنجاح')),
          );
          Navigator.pop(context, true);
        }
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message.toString())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'تعديل بيانات العميل' : 'عميل جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            // أيقونة ترحيبية
            Center(
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 28, top: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            // حقل الاسم
            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل *',
                hintText: 'مثال: محمد أحمد',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
                if (v.trim().length < 2) return 'الاسم يجب أن يكون حرفين على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // حقل الهاتف
            TextFormField(
              controller: _phoneCtrl,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف *',
                hintText: 'مثال: 0501234567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // حقل الملاحظات
            TextFormField(
              controller: _notesCtrl,
              textInputAction: TextInputAction.done,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'أي تفاصيل إضافية عن العميل...',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(widget.isEditMode ? 'حفظ التعديلات' : 'إضافة العميل'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
