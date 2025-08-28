import 'package:flutter/material.dart';
import 'package:flutter_financas/core/category_icons.dart';

/// ===== Helpers robustos para conversão =====

int _toInt(Object? v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) {
    final s = v.trim();
    final n = int.tryParse(s);
    if (n != null) return n;
    final hex = s.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
    final hexInt = int.tryParse(hex, radix: 16);
    if (hexInt != null) return hexInt;
  }
  throw FormatException('Não foi possível converter "$v" para int');
}

String _toString(Object? v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

DateTime _toDate(Object? v) {
  if (v == null) return DateTime.now();
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) {
    final d = DateTime.tryParse(v);
    if (d != null) return d;
    final n = int.tryParse(v);
    if (n != null) return DateTime.fromMillisecondsSinceEpoch(n);
  }
  throw FormatException('Data inválida: $v');
}

enum CategoryType { expense, income }

CategoryType _typeFromDb(Object? v) {
  if (v is int) return v == 1 ? CategoryType.income : CategoryType.expense;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == '1' || s == 'income' || s == 'receita') return CategoryType.income;
    return CategoryType.expense;
  }
  return CategoryType.expense;
}

int _typeToDb(CategoryType t) => t == CategoryType.income ? 1 : 0;

/// ===== CategoryModel =====
class CategoryModel {
  final int? id;
  final String name;
  final CategoryType type;
  final int colorValue;
  final String iconKey;

  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    this.iconKey = 'other',
  });

  Color get color => Color(colorValue);
  IconData get icon => iconFromKey(iconKey);

  CategoryModel copyWith({
    int? id,
    String? name,
    CategoryType? type,
    int? colorValue,
    String? iconKey,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  factory CategoryModel.fromMap(Map<String, Object?> m) {
    return CategoryModel(
      id: m['id'] == null ? null : _toInt(m['id']),
      name: _toString(m['name']),
      type: _typeFromDb(m['type']),
      colorValue: _toInt(m['color']),
      iconKey: _toString(m['icon_key'], fallback: 'other'),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': _typeToDb(type),
      'color': colorValue,
      'icon_key': iconKey,
    };
  }
}

/// ===== TransactionModel =====
class TransactionModel {
  final int? id;
  final int categoryId;
  final int amountCents;
  final DateTime date;

  const TransactionModel({
    this.id,
    required this.categoryId,
    required this.amountCents,
    required this.date,
  });

  factory TransactionModel.fromMap(Map<String, Object?> m) {
    return TransactionModel(
      id: m['id'] == null ? null : _toInt(m['id']),
      categoryId: _toInt(m['category_id']),
      amountCents: _toInt(m['amount_cents']),
      date: _toDate(m['date']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount_cents': amountCents,
      'date': date.millisecondsSinceEpoch,
    };
  }
}

/// ===== BudgetModel (compatível com seu construtor) =====
/// fields no DB: id, category_id, amount_cents, start, period
class BudgetModel {
  final int? id;
  final int categoryId;
  final int amountCents; // limite em centavos
  final DateTime start; // início do período
  final String period; // 'monthly' por padrão

  const BudgetModel({
    this.id,
    required this.categoryId,
    required this.amountCents,
    required this.start,
    this.period = 'monthly',
  });

  factory BudgetModel.fromMap(Map<String, Object?> m) {
    return BudgetModel(
      id: m['id'] == null ? null : _toInt(m['id']),
      categoryId: _toInt(m['category_id']),
      amountCents: _toInt(m['amount_cents']),
      start: _toDate(m['start']),
      period: _toString(m['period'], fallback: 'monthly'),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount_cents': amountCents,
      'start': start.millisecondsSinceEpoch,
      'period': period,
    };
  }
}
