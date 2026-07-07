import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/usecase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/order_item.dart';

/// Bottom Sheet لإضافة أو تعديل منتج ضمن طلب.
/// عند الحفظ:
///   - يُنشئ منتجًا جديدًا في جدول products (CreateProductUseCase)
///   - ثم يُضيف عنصرًا للطلب (AddOrderItemUseCase)
/// عند التعديل:
///   - يُحدِّث العنصر الموجود (UpdateOrderItemUseCase)
///   (المنتج لا يتغير في وضع التعديل - فقط الكمية والأسعار)
class AddOrderItemSheet extends ConsumerStatefulWidget {
  final int orderId;
  final OrderItem? existingItem; // null = إضافة جديدة
  final VoidCallback onSaved;

  const AddOrderItemSheet({
    super.key,
    required this.orderId,
    this.existingItem,
    required this.onSaved,
  });

  bool get isEditMode => existingItem != null;

  @override
  ConsumerState<AddOrderItemSheet> createState() => _AddOrderItemSheetState();
}

class _AddOrderItemSheetState extends ConsumerState<AddOrderItemSheet> {
  final _formKey = GlobalKey<FormState>();

  // حقول المنتج (فقط في وضع الإضافة)
  final _sheinIdCtrl = TextEditingController();
  final _sheinUrlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();

  // حقول السعر والكمية (في الوضعين)
  final _quantityCtrl = TextEditingController(text: '1');
  final _purchasePriceCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();

  bool _saving = false;
  double _profit = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      final item = widget.existingItem!;
      // في التعديل، نملأ حقول المنتج بالبيانات الحالية
      _sheinIdCtrl.text = item.product.sheinProductId;
      _sheinUrlCtrl.text = item.product.sheinUrl;
      _titleCtrl.text = item.product.title;
      _descCtrl.text = item.product.description ?? '';
      _imageCtrl.text = item.product.image ?? '';
      _colorCtrl.text = item.product.color ?? '';
      _sizeCtrl.text = item.product.size ?? '';
      _quantityCtrl.text = '${item.quantity}';
      _purchasePriceCtrl.text = '${item.purchasePrice}';
      _sellingPriceCtrl.text = '${item.sellingPrice}';
      _profit = item.sellingPrice - item.purchasePrice;
    }
    _purchasePriceCtrl.addListener(_updateProfit);
    _sellingPriceCtrl.addListener(_updateProfit);
  }

  void _updateProfit() {
    final purchase = double.tryParse(_purchasePriceCtrl.text) ?? 0;
    final selling = double.tryParse(_sellingPriceCtrl.text) ?? 0;
    setState(() => _profit = selling - purchase);
  }

  @override
  void dispose() {
    _sheinIdCtrl.dispose();
    _sheinUrlCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _colorCtrl.dispose();
    _sizeCtrl.dispose();
    _quantityCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final qty = int.parse(_quantityCtrl.text.trim());
      final purchase = double.parse(_purchasePriceCtrl.text.trim());
      final selling = double.parse(_sellingPriceCtrl.text.trim());

      if (widget.isEditMode) {
        // تعديل: نُنشئ منتجًا جديدًا بالبيانات المُحدَّثة ثم نُحدِّث العنصر
        final productId = await ref.read(createProductUseCaseProvider).call(
              sheinProductId: _sheinIdCtrl.text.trim(),
              sheinUrl: _sheinUrlCtrl.text.trim(),
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              image: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
              color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
              size: _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
            );

        await ref.read(updateOrderItemUseCaseProvider).call(
              itemId: widget.existingItem!.id,
              orderId: widget.orderId,
              productId: productId,
              quantity: qty,
              purchasePrice: purchase,
              sellingPrice: selling,
            );
      } else {
        // إضافة جديدة: أنشئ المنتج أولاً ثم أضفه للطلب
        final productId = await ref.read(createProductUseCaseProvider).call(
              sheinProductId: _sheinIdCtrl.text.trim(),
              sheinUrl: _sheinUrlCtrl.text.trim(),
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              image: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
              color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
              size: _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
            );

        await ref.read(addOrderItemUseCaseProvider).call(
              orderId: widget.orderId,
              productId: productId,
              quantity: qty,
              purchasePrice: purchase,
              sellingPrice: selling,
            );
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  widget.isEditMode ? 'تم تعديل المنتج' : 'تم إضافة المنتج')),
        );
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message.toString())));
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

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollCtrl) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              // مقبض السحب
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // العنوان
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      widget.isEditMode ? 'تعديل المنتج' : 'إضافة منتج',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // النموذج
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      _SectionHeader('معلومات المنتج'),
                      const SizedBox(height: 10),

                      // SHEIN Product ID
                      _FormField(
                        controller: _sheinIdCtrl,
                        label: 'معرّف المنتج SHEIN *',
                        hint: 'مثال: 789456123',
                        icon: Icons.tag_rounded,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'معرّف SHEIN مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // SHEIN URL
                      _FormField(
                        controller: _sheinUrlCtrl,
                        label: 'رابط المنتج على SHEIN *',
                        hint: 'https://ar.shein.com/...',
                        icon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'رابط المنتج مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // اسم المنتج
                      _FormField(
                        controller: _titleCtrl,
                        label: 'اسم المنتج *',
                        hint: 'مثال: فستان صيفي شيفون',
                        icon: Icons.title_rounded,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'اسم المنتج مطلوب'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // وصف
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'الوصف (اختياري)',
                          hintText: 'تفاصيل إضافية...',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              controller: _colorCtrl,
                              label: 'اللون',
                              hint: 'أسود',
                              icon: Icons.palette_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              controller: _sizeCtrl,
                              label: 'المقاس',
                              hint: 'M',
                              icon: Icons.straighten_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // رابط الصورة
                      _FormField(
                        controller: _imageCtrl,
                        label: 'رابط الصورة (اختياري)',
                        hint: 'https://...',
                        icon: Icons.image_outlined,
                        keyboardType: TextInputType.url,
                      ),

                      const SizedBox(height: 20),
                      _SectionHeader('الكمية والأسعار'),
                      const SizedBox(height: 10),

                      // الكمية
                      _FormField(
                        controller: _quantityCtrl,
                        label: 'الكمية *',
                        hint: '1',
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final qty = int.tryParse(v?.trim() ?? '');
                          if (qty == null || qty <= 0) {
                            return 'الكمية يجب أن تكون أكبر من صفر';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              controller: _purchasePriceCtrl,
                              label: 'سعر الشراء * (\$)',
                              hint: '0.00',
                              icon: Icons.arrow_downward_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              iconColor: AppColors.purchaseColor,
                              validator: (v) {
                                final p = double.tryParse(v?.trim() ?? '');
                                if (p == null || p < 0) return 'أدخل سعرًا صحيحًا';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              controller: _sellingPriceCtrl,
                              label: 'سعر البيع * (\$)',
                              hint: '0.00',
                              icon: Icons.arrow_upward_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              iconColor: AppColors.sellingColor,
                              validator: (v) {
                                final p = double.tryParse(v?.trim() ?? '');
                                if (p == null || p < 0) return 'أدخل سعرًا صحيحًا';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // عرض الربح تلقائيًا
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _profit >= 0
                              ? AppColors.profitColor.withValues(alpha: 0.12)
                              : Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _profit >= 0
                                ? AppColors.profitColor.withValues(alpha: 0.4)
                                : Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _profit >= 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: _profit >= 0
                                  ? AppColors.profitColor
                                  : Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الربح التلقائي للوحدة الواحدة',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  Text(
                                    AppFormatters.currency(_profit),
                                    style: TextStyle(
                                      color: _profit >= 0
                                          ? AppColors.profitColor
                                          : Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_profit < 0)
                              Text(
                                '⚠️ خسارة',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // زر الحفظ
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(widget.isEditMode
                            ? 'حفظ التعديلات'
                            : 'إضافة إلى الطلب'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---- مساعدات ----

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color? iconColor;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(icon, color: iconColor),
      ),
      validator: validator,
    );
  }
}
