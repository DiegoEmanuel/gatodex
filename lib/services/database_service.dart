import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cat_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'gatodex.db'),
      version: 3,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE cats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          image_path TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          captured_at TEXT NOT NULL,
          entry_number INTEGER NOT NULL,
          name TEXT,
          card_name TEXT,
          rarity TEXT,
          element TEXT,
          power INTEGER,
          agility INTEGER,
          charisma INTEGER,
          ability TEXT,
          card_image_url TEXT
        )
      '''),
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE cats ADD COLUMN name TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE cats ADD COLUMN card_name TEXT');
          await db.execute('ALTER TABLE cats ADD COLUMN rarity TEXT');
          await db.execute('ALTER TABLE cats ADD COLUMN element TEXT');
          await db.execute('ALTER TABLE cats ADD COLUMN power INTEGER');
          await db.execute('ALTER TABLE cats ADD COLUMN agility INTEGER');
          await db.execute('ALTER TABLE cats ADD COLUMN charisma INTEGER');
          await db.execute('ALTER TABLE cats ADD COLUMN ability TEXT');
          await db.execute('ALTER TABLE cats ADD COLUMN card_image_url TEXT');
        }
      },
    );
  }

  Future<CatEntry> insert(CatEntry entry) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    final id = await db.insert('cats', map);
    return CatEntry(
      id: id,
      imagePath: entry.imagePath,
      latitude: entry.latitude,
      longitude: entry.longitude,
      capturedAt: entry.capturedAt,
      entryNumber: entry.entryNumber,
      name: entry.name,
    );
  }

  Future<void> delete(int id, String imagePath) async {
    final db = await database;
    await db.delete('cats', where: 'id = ?', whereArgs: [id]);
    try {
      await File(imagePath).delete();
    } catch (_) {}
  }

  Future<void> updateName(int id, String name) async {
    final db = await database;
    await db.update('cats', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCard(
    int id, {
    required String cardName,
    required String rarity,
    required String element,
    required int power,
    required int agility,
    required int charisma,
    required String ability,
  }) async {
    final db = await database;
    await db.update(
      'cats',
      {
        'card_name': cardName,
        'rarity': rarity,
        'element': element,
        'power': power,
        'agility': agility,
        'charisma': charisma,
        'ability': ability,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCardImageUrl(int id, String url) async {
    final db = await database;
    await db.update(
      'cats',
      {'card_image_url': url},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CatEntry>> getAll() async {
    final db = await database;
    final rows = await db.query('cats', orderBy: 'entry_number ASC');
    return rows.map(CatEntry.fromMap).toList();
  }

  Future<List<String>> getExistingNames() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT name FROM cats WHERE name IS NOT NULL ORDER BY name ASC',
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM cats');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<CatEntry?> findNearby(
    double lat,
    double lng, {
    double radiusMeters = 50,
  }) async {
    final all = await getAll();
    for (final cat in all) {
      if (cat.latitude == 0.0 && cat.longitude == 0.0) continue;
      final dist = _haversine(lat, lng, cat.latitude, cat.longitude);
      if (dist <= radiusMeters) return cat;
    }
    return null;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        _sin2(dLat / 2) +
        _sin2(dLon / 2) * _cos(_rad(lat1)) * _cos(_rad(lat2));
    return r * 2 * _asin(_sqrt(a));
  }

  double _rad(double d) => d * 3.141592653589793 / 180;
  double _sin2(double x) => _sin(x) * _sin(x);
  double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
  double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
  double _asin(double x) => x + x * x * x / 6 + 3 * x * x * x * x * x / 40;
  double _sqrt(double x) {
    if (x <= 0) return 0;
    var r = x;
    for (var i = 0; i < 20; i++) {
      r = (r + x / r) / 2;
    }
    return r;
  }
}
