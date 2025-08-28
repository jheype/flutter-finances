import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_financas/data/models.dart';
import 'package:flutter_financas/data/repositories.dart';

final categoriesAllProvider = FutureProvider<List<CategoryModel>>(
  (ref) => CategoryRepository().getAll(),
);
