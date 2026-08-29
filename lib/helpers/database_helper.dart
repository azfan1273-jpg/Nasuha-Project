import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;

  DatabaseHelper._init();

  // 🟢 GETTER DATABASE SQLITE NATIVE
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('app_laundry.db');
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // 🟢 SKEMA TABEL SQLITE
  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Orders Lokal
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        store_id TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        service_name TEXT,
        status TEXT,
        subtotal REAL,
        discount REAL,
        discount_percent REAL,
        total_price REAL,
        catatan TEXT,
        parfum TEXT,
        created_at TEXT,
        estimated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 2. Tabel Customers Lokal
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        store_id TEXT,
        name TEXT,
        phone TEXT,
        address TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // ==========================================
  // HELPER ORDER
  // ==========================================
  Future<void> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    await db.insert('orders', {
      'id': order['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'store_id': order['store_id']?.toString(),
      'customer_name': order['customer_name'] ?? '',
      'customer_phone': order['customer_phone'] ?? '',
      'service_name': order['service_name'] ?? '',
      'status': order['status'] ?? 'Antrian',
      'subtotal': (order['subtotal'] as num?)?.toDouble() ?? 0.0,
      'discount': (order['discount'] as num?)?.toDouble() ?? 0.0,
      'discount_percent': (order['discount_percent'] as num?)?.toDouble() ?? 0.0,
      'total_price': (order['total_price'] as num?)?.toDouble() ?? 0.0,
      'catatan': order['catatan'] ?? '',
      'parfum': order['parfum'] ?? '',
      'created_at': order['created_at'] ?? DateTime.now().toIso8601String(),
      'estimated_at': order['estimated_at'] ?? DateTime.now().toIso8601String(),
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    debugPrint('Order berhasil disimpan lokal di SQLite');
  }

  Future<List<Map<String, dynamic>>> getLocalOrders(String storeId) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> clearLocalOrders({String? storeId}) async {
    final db = await database;
    if (storeId != null) {
      await db.delete('orders', where: 'store_id = ?', whereArgs: [storeId]);
    } else {
      await db.delete('orders');
    }
    debugPrint('Database lokal dibersihkan.');
  }

  // ==========================================
  // HELPER PELANGGAN (OFFLINE & CACHE)
  // ==========================================
  Future<void> saveCustomersLocal(List<Map<String, dynamic>> customers) async {
    final db = await database;
    final batch = db.batch();
    for (var cust in customers) {
      batch.insert(
        'customers',
        {
          'id': cust['id']?.toString(),
          'store_id': cust['store_id']?.toString(),
          'name': cust['name'] ?? '',
          'phone': cust['phone'] ?? '-',
          'address': cust['address'] ?? '-',
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCustomersLocal(String keyword) async {
    final db = await database;
    if (keyword.trim().isEmpty) {
      return await db.query('customers', orderBy: 'name ASC');
    } else {
      final kw = '%${keyword.trim()}%';
      return await db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: [kw, kw],
        orderBy: 'name ASC',
      );
    }
  }

  Future<Map<String, dynamic>> insertCustomerOffline(Map<String, dynamic> data) async {
    final db = await database;
    final localId = DateTime.now().millisecondsSinceEpoch.toString();

    final payload = {
      'id': localId,
      'store_id': data['store_id']?.toString(),
      'name': data['name'] ?? '',
      'phone': data['phone'] ?? '-',
      'address': data['address'] ?? '-',
      'is_synced': 0,
    };

    await db.insert('customers', payload, conflictAlgorithm: ConflictAlgorithm.replace);
    return payload;
  }
}
