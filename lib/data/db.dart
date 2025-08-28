import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Aumente este número sempre que fizer mudança de schema.
/// v1  -> schema inicial
/// v2  -> adiciona coluna `icon_key` em `categories`
const int kDbVersion = 2;

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'financas.db');

    return openDatabase(
      path,
      version: kDbVersion,
      onCreate: (db, version) async {
        await _createV1(db);
        if (version >= 2) {
          await _migrateToV2(db);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          await _createV1(db);
        }
        if (oldVersion < 2 && newVersion >= 2) {
          await _migrateToV2(db);
        }
      },
    );
  }

  /// ---------------- SCHEMA v1 ----------------
  Future<void> _createV1(Database db) async {
    // categories
    await db.execute('''
      CREATE TABLE categories (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT    NOT NULL,
        type      INTEGER NOT NULL,     -- 0 = expense, 1 = income
        color     INTEGER NOT NULL
      );
    ''');

    // transactions
    await db.execute('''
      CREATE TABLE transactions (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id   INTEGER NOT NULL,
        amount_cents  INTEGER NOT NULL, -- negativo = despesa; positivo = receita
        date          INTEGER NOT NULL, -- millisSinceEpoch
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_tx_date ON transactions(date);');
    await db.execute('CREATE INDEX idx_tx_cat  ON transactions(category_id);');

    // budgets
    await db.execute('''
      CREATE TABLE budgets (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id   INTEGER NOT NULL,
        amount_cents  INTEGER NOT NULL,
        start         INTEGER NOT NULL, -- millisSinceEpoch (início do período)
        period        TEXT    NOT NULL DEFAULT 'monthly',
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
      );
    ''');

    // (Opcional) sementes iniciais sem icon_key (virá na V2)
    await db.insert('categories', {
      'name': 'Mercado',
      'type': 0,
      'color': 0xFF7E57C2,
    });
    await db.insert('categories', {
      'name': 'Transporte',
      'type': 0,
      'color': 0xFF26A69A,
    });
    await db.insert('categories', {
      'name': 'Salário',
      'type': 1,
      'color': 0xFF42A5F5,
    });
  }

  /// ---------------- MIGRATION -> v2 ----------------
  Future<void> _migrateToV2(Database db) async {
    // adiciona coluna icon_key com default 'other'
    await db.execute(
      "ALTER TABLE categories ADD COLUMN icon_key TEXT NOT NULL DEFAULT 'other';",
    );

    // (Opcional) atualizar algumas categorias conhecidas com ícones bonitos:
    // Não falha se nomes não existirem — são atualizações "best-effort".
    await db.update('categories', {'icon_key': 'groceries'},
        where: 'LOWER(name) = ?', whereArgs: ['mercado']);
    await db.update('categories', {'icon_key': 'transport'},
        where: 'LOWER(name) = ?', whereArgs: ['transporte']);
    await db.update('categories', {'icon_key': 'salary'},
        where: 'LOWER(name) = ?', whereArgs: ['salário']);
  }
}
