import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/customers_providers.dart';
import '../../providers/usecase_providers.dart';
import '../../../domain/entities/customer.dart';
import '../../../core/utils/formatters.dart';

/// شاشة إنشاء طلب جديد
/// - اختيار العميل (بحث في القائمة)
/// - تاريخ الوصول المتوقع (اختياري)
/// - ملاحظات (اختياري)
class OrderFormScreen extends ConsumerStatefulWidget {
  /// إذا مُرِّر customerId، يُحدَّد العميل تلقائيًا (مثلاً من بروفايل العميل)
  final int? preselectedCustomerId;

  const OrderFormScreen({super.key, this.preselectedCustomerId});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _notesCtrl = TextEditingController();
  Customer? _selectedCustomer;
  DateTime? _expectedArrivalDate;
  bool _saving = false;
  bool _customerSearchOpen = false;
  final _customerSearchCtrl = TextEditingController();
  String _customerQuery = '';

  @override
  void dispose() {
    _notesCtrl.dispose();
    _customerSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedArrivalDate ??
          DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
      helpText: 'تاريخ الوصول المتوقع',
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
    );
    if (picked != null) {
      setState(() => _expectedArrivalDate = picked);
    }
  }

  Future<void> _save() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل أولاً')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final orderId = await ref.read(createOrderUseCaseProvider).call(
            customerId: _selectedCustomer!.id,
            expectedArrivalDate: _expectedArrivalDate,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الطلب بنجاح')),
        );
        Navigator.pop(context, orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(customersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('طلب جديد')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          // -- اختيار العميل --
          Text('العميل *',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),

          if (_selectedCustomer == null) ...[
            // زر اختيار العميل
            OutlinedButton.icon(
              onPressed: () => setState(() => _customerSearchOpen = true),
              icon: const Icon(Icons.person_search_rounded),
              label: const Text('اختر عميلاً...'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ] else ...[
            // بطاقة العميل المختار
            _SelectedCustomerCard(
              customer: _selectedCustomer!,
              onClear: () => setState(() => _selectedCustomer = null),
            ),
          ],

          // قائمة البحث عن العميل
          if (_customerSearchOpen) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customerSearchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _customerQuery = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو الهاتف...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 8),
            customersAsync.when(
              data: (customers) {
                final filtered = _customerQuery.isEmpty
                    ? customers
                    : customers
                        .where((c) =>
                            c.fullName.toLowerCase().contains(_customerQuery) ||
                            c.phoneNumber.contains(_customerQuery))
                        .toList();
                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('لا توجد نتائج',
                        textAlign: TextAlign.center),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            c.fullName.isNotEmpty ? c.fullName[0] : '؟',
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(c.fullName),
                        subtitle: Text(c.phoneNumber),
                        onTap: () => setState(() {
                          _selectedCustomer = c;
                          _customerSearchOpen = false;
                          _customerSearchCtrl.clear();
                          _customerQuery = '';
                        }),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('خطأ: $err'),
            ),
          ],

          const SizedBox(height: 24),

          // -- تاريخ الوصول المتوقع --
          Text('تاريخ الوصول المتوقع (اختياري)',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      color: _expectedArrivalDate != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _expectedArrivalDate != null
                          ? AppFormatters.date(_expectedArrivalDate!)
                          : 'اضغط لاختيار التاريخ',
                      style: TextStyle(
                        color: _expectedArrivalDate != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (_expectedArrivalDate != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () =>
                          setState(() => _expectedArrivalDate = null),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // -- ملاحظات --
          TextFormField(
            controller: _notesCtrl,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              hintText: 'أي تفاصيل خاصة بالطلب...',
              prefixIcon: Icon(Icons.notes_rounded),
              alignLabelWithHint: true,
            ),
          ),
        ],
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
                : const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('إنشاء الطلب'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onClear;

  const _SelectedCustomerCard(
      {required this.customer, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: 18,
            child: Text(
              customer.fullName.isNotEmpty ? customer.fullName[0] : '؟',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.fullName,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(customer.phoneNumber,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'تغيير العميل',
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
