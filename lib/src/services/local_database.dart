import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/mappers/restaurant_mapper.dart';
import '../data/mock_restaurants.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;
  bool _isDisabled = false;

  bool get isAvailable => !_isDisabled && _database != null;

  bool get _supportsLocalDatabase {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    if (_database != null || _isDisabled) return;

    if (!_supportsLocalDatabase) {
      _isDisabled = true;
      debugPrint('Local database disabled: unsupported platform');
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(documentsDir.path, 'sitcheck.db');

      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await _createSchema(db);
        },
      );

      await _seedRestaurantsIfNeeded();
    } catch (error, stackTrace) {
      _isDisabled = true;
      debugPrint('Local database init failed: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<Database> get database async {
    if (_isDisabled) {
      throw StateError('Local database disabled');
    }
    if (_database == null) {
      await init();
    }
    if (_isDisabled || _database == null) {
      throw StateError('Local database unavailable');
    }
    return _database!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE restaurants (
        id TEXT PRIMARY KEY,
        owner_id TEXT,
        name TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        restaurant_id TEXT NOT NULL,
        table_id TEXT NOT NULL,
        guest_name TEXT NOT NULL,
        guest_phone TEXT NOT NULL,
        guest_count INTEGER NOT NULL,
        booking_date TEXT NOT NULL,
        booking_time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        image_path TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        slot_key TEXT NOT NULL,
        UNIQUE(restaurant_id, table_id, slot_key)
      )
    ''');

    await db.execute('''
      CREATE TABLE owners (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        password_hash TEXT NOT NULL,
        restaurant_id TEXT,
        address TEXT,
        profile_image_path TEXT,
        banner_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedRestaurantsIfNeeded() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM restaurants'),
        ) ??
        0;
    if (count > 0) return;

    for (final restaurant in mockRestaurants) {
      final payload = RestaurantMapper.toPayload(restaurant);
      final now = DateTime.now().toIso8601String();
      await db.insert(
        'restaurants',
        {
          'id': restaurant.id,
          'owner_id': restaurant.ownerId,
          'name': restaurant.name,
          'payload': payload,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Map<String, dynamic>?> getRestaurantRow(String id) async {
    final db = await database;
    final rows = await db.query(
      'restaurants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    final db = await database;
    return db.query('restaurants', orderBy: 'name ASC');
  }

  Future<void> saveRestaurantPayload(String id, Map<String, dynamic> payload) async {
    final db = await database;
    await db.update(
      'restaurants',
      {
        'payload': jsonEncode(payload),
        'updated_at': DateTime.now().toIso8601String(),
        'name': payload['name'] ?? '',
        'owner_id': payload['owner_id'] ?? '',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

