import 'package:sqflite/sqflite.dart';

import 'package:flutter_financas/data/db.dart';
import 'package:flutter_financas/data/models.dart';

class CategoryRepository {
  final Future<Database> _db = AppDb.instance.database;

  Future<List<CategoryModel>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'categories',
      orderBy: 'type DESC, name ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<int> upsert(CategoryModel c) async {
    final db = await _db;
    if (c.id == null) {
      // create
      return db.insert('categories', c.toMap());
    } else {
      // update
      await db.update('categories', c.toMap(), where: 'id=?', whereArgs: [c.id]);
      return c.id!;
    }
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('categories', where: 'id=?', whereArgs: [id]);
  }
}

class TransactionRepository {
  final Future<Database> _db = AppDb.instance.database;

  Future<List<TransactionModel>> getAll({DateTime? from, DateTime? to}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (from != null) {
      where.add('date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('date < ?');
      args.add(to.millisecondsSinceEpoch);
    }

    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<int> insert(TransactionModel t) async {
    final db = await _db;
    return db.insert('transactions', t.toMap());
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('transactions', where: 'id=?', whereArgs: [id]);
  }

  Future<int> totalBalanceCents() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT SUM(amount_cents) as total FROM transactions');
    final total = rows.first['total'] as int?;
    return total ?? 0;
  }

  Future<List<Map<String, int>>> lastMonthsNet(int count) async {
    final db = await _db;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month - count + 1, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final rows = await db.rawQuery(
      'SELECT strftime("%Y%m", datetime(date/1000, "unixepoch")) as ym, '
      'SUM(amount_cents) as total '
      'FROM transactions '
      'WHERE date >= ? AND date < ? '
      'GROUP BY ym ORDER BY ym ASC',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );

    final out = <Map<String, int>>[];
    DateTime cursor = DateTime(start.year, start.month);
    while (!DateTime(cursor.year, cursor.month + 1).isAfter(end)) {
      final ym = (cursor.year * 100) + cursor.month;
      final found = rows.cast<Map<String, Object?>>().firstWhere(
            (e) => int.parse(e['ym'] as String) == ym,
            orElse: () => {'ym': '$ym', 'total': 0},
          );
      out.add({
        'yyyymm': ym,
        'total': (found['total'] as int?) ?? 0,
      });
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return out;
  }
}

class BudgetRepository {}
