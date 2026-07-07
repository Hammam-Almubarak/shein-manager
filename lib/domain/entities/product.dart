/// كيان المنتج - بيانات مرجعية لمنتج SHEIN (وليس منتج مملوك للمندوب)
class Product {
  final int id;
  final String sheinProductId;
  final String sheinUrl;
  final String title;
  final String? description;
  final String? image;
  final String? color;
  final String? size;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.sheinProductId,
    required this.sheinUrl,
    required this.title,
    this.description,
    this.image,
    this.color,
    this.size,
    required this.createdAt,
  });

  Product copyWith({
    int? id,
    String? sheinProductId,
    String? sheinUrl,
    String? title,
    String? description,
    String? image,
    String? color,
    String? size,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      sheinProductId: sheinProductId ?? this.sheinProductId,
      sheinUrl: sheinUrl ?? this.sheinUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      color: color ?? this.color,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
