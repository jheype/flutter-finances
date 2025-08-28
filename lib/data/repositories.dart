import 'package:sqflite/sqflite.dart';
import 'package:flutter_financas/data/db.dart';
import 'package:flutter_financas/data/models.dart';

/// ================= CATEGORY =================
class CategoryRepository {
  Future<Database> get _db async => (await AppDatabase.instance.database);

  Future<List<CategoryModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<int> upsert(CategoryModel c) async {
    final db = await _db;
    if (c.id == null) {
      return db.insert('categories', c.toMap());
    } else {
      return db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    }
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

/// ================= TRANSACTION =================
class TransactionRepository {
  Future<Database> get _db async => (await AppDatabase.instance.database);

  Future<List<TransactionModel>> getAll({DateTime? from, DateTime? to}) async {
    final db = await _db;
    String where = '';
    List<Object?> args = [];

    if (from != null) {
      where += 'date >= ?';
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'date < ?';
      args.add(to.millisecondsSinceEpoch);
    }

    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where,
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return rows.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getRecent({int limit = 10}) async {
    final db = await _db;
    final rows = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<int> insert(TransactionModel t) async {
    final db = await _db;
    return db.insert('transactions', t.toMap());
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalBalanceCents() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT SUM(amount_cents) as total FROM transactions');
    final val = rows.first['total'] as int?;
    return val ?? 0;
  }

  Future<List<Map<String, int>>> lastMonthsNet(int months) async {
    final db = await _db;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (months - 1), 1);

    final rows = await db.rawQuery('''
      SELECT strftime('%Y%m', date/1000, 'unixepoch') AS ym,
             SUM(amount_cents) AS total
      FROM transactions
      WHERE date >= ?
      GROUP BY ym
      ORDER BY ym ASC
    ''', [start.millisecondsSinceEpoch]);

    return rows.map((row) {
      final ym = int.parse(row['ym'] as String);
      final total = row['total'] as int? ?? 0;
      return {'yyyymm': ym, 'total': total};
    }).toList();
  }
}

/// ================= BUDGET =================
class BudgetRepository {
  Future<Database> get _db async => (await AppDatabase.instance.database);

  Future<List<BudgetModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('budgets', orderBy: 'start DESC');
    return rows.map((m) => BudgetModel.fromMap(m)).toList();
  }

  Future<int> upsert(BudgetModel b) async {
    final db = await _db;
    if (b.id == null) {
      return db.insert('budgets', b.toMap());
    } else {
      return db.update('budgets', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
    }
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
