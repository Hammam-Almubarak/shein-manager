import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'usecase_providers.dart';
import '../../domain/usecases/global_search_usecase.dart';

/// نص البحث الشامل الحالي (يُستخدم من شريط بحث عام بأعلى التطبيق)
final globalSearchQueryProvider = StateProvider<String>((ref) => '');

/// نتيجة البحث الشامل - تُعاد حسابها تلقائيًا عند تغيّر globalSearchQueryProvider
final globalSearchResultsProvider =
    FutureProvider<GlobalSearchResults>((ref) {
  final query = ref.watch(globalSearchQueryProvider);
  return ref.watch(globalSearchUseCaseProvider)(query);
});
