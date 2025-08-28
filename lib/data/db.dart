import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter_financas/data/models.dart';

class AppDb {
  static final AppDb instance = AppDb._();
  AppDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'financas.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL CHECK (type IN ('expense','income')),
            color_value INTEGER NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date INTEGER NOT NULL,
            amount_cents INTEGER NOT NULL,
            category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
            note TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
            amount_cents INTEGER NOT NULL,
            start INTEGER NOT NULL,
            period TEXT NOT NULL DEFAULT 'monthly'
          );
        ''');

        await db.insert(
          'categories',
          const CategoryModel(
            name: 'Salário',
            type: CategoryType.income,
            colorValue: 0xFF66BB6A,
          ).toMap(),
        );
        await db.insert(
          'categories',
          const CategoryModel(
            name: 'Mercado',
            type: CategoryType.expense,
            colorValue: 0xFFAB47BC,
          ).toMap(),
        );
        await db.insert(
          'categories',
          const CategoryModel(
            name: 'Transporte',
            type: CategoryType.expense,
            colorValue: 0xFF5C6BC0,
          ).toMap(),
        );
        await db.insert(
          'categories',
          const CategoryModel(
            name: 'Lazer',
            type: CategoryType.expense,
            colorValue: 0xFF42A5F5,
          ).toMap(),
        );
      },
    );
  }
}
