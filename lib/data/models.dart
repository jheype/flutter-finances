import 'package:flutter/material.dart';

// Tipo da categoria: receita ou despesa
enum CategoryType { expense, income }

class CategoryModel {
  final int? id;
  final String name;
  final CategoryType type;
  final int colorValue;

  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.colorValue,
  });

  CategoryModel copyWith({
    int? id,
    String? name,
    CategoryType? type,
    int? colorValue,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'color_value': colorValue,
      };

  static CategoryModel fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: (map['type'] as String) == 'income' ? CategoryType.income : CategoryType.expense,
      colorValue: map['color_value'] as int,
    );
  }

  Color get color => Color(colorValue);
}

class TransactionModel {
  final int? id;
  final DateTime date;
  final int amountCents; // negativo = despesa, positivo = receita
  final int categoryId;
  final String? note;

  const TransactionModel({
    this.id,
    required this.date,
    required this.amountCents,
    required this.categoryId,
    this.note,
  });

  TransactionModel copyWith({
    int? id,
    DateTime? date,
    int? amountCents,
    int? categoryId,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'amount_cents': amountCents,
        'category_id': categoryId,
        'note': note,
      };

  static TransactionModel fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      amountCents: map['amount_cents'] as int,
      categoryId: map['category_id'] as int,
      note: map['note'] as String?,
    );
  }
}

class BudgetModel {
  final int? id;
  final int categoryId;
  final int amountCents;
  final DateTime start;
  final String period; // ex: 'monthly'

  const BudgetModel({
    this.id,
    required this.categoryId,
    required this.amountCents,
    required this.start,
    this.period = 'monthly',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'amount_cents': amountCents,
        'start': start.millisecondsSinceEpoch,
        'period': period,
      };

  static BudgetModel fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      amountCents: map['amount_cents'] as int,
      start: DateTime.fromMillisecondsSinceEpoch(map['start'] as int),
      period: map['period'] as String,
    );
  }
}
