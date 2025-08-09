import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

class DatabaseService {
  static Database? _database;

  static Future<void> init() async {
    try {
      print('🔄 Database başlatılıyor...');
      await database; // Database'i initialize et
      print('✅ Database başarıyla başlatıldı');
    } catch (e) {
      print('❌ Database başlatma hatası: $e');
      rethrow;
    }
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'otoyikama.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Müşteriler tablosu
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        plate TEXT NOT NULL,
        phone TEXT NOT NULL,
        serviceType TEXT NOT NULL,
        vehicleType TEXT NOT NULL,
        price REAL NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Fiyatlar tablosu
    await db.execute('''
      CREATE TABLE prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleType TEXT NOT NULL,
        serviceType TEXT NOT NULL,
        price REAL NOT NULL,
        UNIQUE(vehicleType, serviceType)
      )
    ''');

    // Gider kategorileri tablosu
    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Giderler tablosu
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Varsayılan fiyatları ekle
    await db.insert('prices', {
      'vehicleType': 'Normal',
      'serviceType': 'İç Yıkama',
      'price': 50.0
    });
    await db.insert('prices', {
      'vehicleType': 'Normal',
      'serviceType': 'Dış Yıkama',
      'price': 30.0
    });
    await db.insert('prices', {
      'vehicleType': 'Normal',
      'serviceType': 'İç + Dış Yıkama',
      'price': 70.0
    });
    await db.insert('prices', {
      'vehicleType': 'SUV',
      'serviceType': 'İç Yıkama',
      'price': 70.0
    });
    await db.insert('prices', {
      'vehicleType': 'SUV',
      'serviceType': 'Dış Yıkama',
      'price': 45.0
    });
    await db.insert('prices', {
      'vehicleType': 'SUV',
      'serviceType': 'İç + Dış Yıkama',
      'price': 100.0
    });

    // Varsayılan gider kategorisi ekle
    await db.insert('expense_categories', {
      'name': 'Yemek',
      'description': 'Günlük yemek giderleri',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Database upgrade: $oldVersion -> $newVersion');
    
    if (oldVersion < 6) {
      try {
        print('📋 Yeni tablolar ekleniyor...');
        
        // Gider kategorileri tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS expense_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Giderler tablosu
        await db.execute('''
          CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            date DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Varsayılan gider kategorisi ekle
        await db.insert('expense_categories', {
          'name': 'Yemek',
          'description': 'Günlük yemek giderleri',
          'createdAt': DateTime.now().toIso8601String(),
        });

        print('✅ Yeni tablolar başarıyla eklendi');
      } catch (e) {
        print('❌ Database upgrade hatası: $e');
      }
    }
  }

  // Müşteri işlemleri
  static Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  static Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'timestamp DESC'
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  static Future<List<Customer>> getCustomersByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC'
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  static Future<List<Customer>> getCustomersByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC'
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  static Future<List<Customer>> searchByPlate(String plate) async {
    final db = await database;
    final normalizedPlate = _normalizePlate(plate);
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(plate, " ", ""), "İ", "I"), "Ğ", "G"), "Ü", "U"), "Ş", "S"), "Ö", "O") LIKE ?',
      whereArgs: ['%$normalizedPlate%'],
      orderBy: 'timestamp DESC'
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  static Future<List<Customer>> searchByName(String name) async {
    final db = await database;
    final normalizedName = _normalizeText(name);
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, "İ", "I"), "Ğ", "G"), "Ü", "U"), "Ş", "S"), "Ö", "O") LIKE ?',
      whereArgs: ['%$normalizedName%'],
      orderBy: 'timestamp DESC'
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  static Future<List<Customer>> searchByPhone(String phone) async {
    final db = await database;
    final normalizedPhone = _normalizeText(phone);
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "İ", "I"), "Ğ", "G"), "Ü", "U"), "Ş", "S"), "Ö", "O") LIKE ?',
      whereArgs: ['%$normalizedPhone%'],
      orderBy: 'timestamp DESC'
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  static Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id]
    );
  }

  static Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // Fiyat işlemleri
  static Future<List<Map<String, dynamic>>> getAllPrices() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('prices');
      return maps;
    } catch (e) {
      // Eğer prices tablosu yoksa, varsayılan fiyatları oluştur ve tekrar dene
      await _createDefaultPrices(db);
      final List<Map<String, dynamic>> maps = await db.query('prices');
      return maps;
    }
  }

  static Future<void> _createDefaultPrices(Database db) async {
    try {
      // Prices tablosunu oluştur
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vehicleType TEXT NOT NULL,
          serviceType TEXT NOT NULL,
          price REAL NOT NULL,
          UNIQUE(vehicleType, serviceType)
        )
      ''');

      // Varsayılan fiyatları ekle
      await _insertDefaultPrices(db);
    } catch (e) {
      print('❌ Varsayılan fiyatlar oluşturulurken hata: $e');
    }
  }

  static Future<void> _insertDefaultPrices(Database db) async {
    await db.insert('prices', {
      'vehicleType': 'Normal',
      'serviceType': 'İç Yıkama',
      'price': 50.0
    });
    await db.insert('prices', {
      'vehicleType': 'Normal',
      'serviceType': 'Dış Yıkama',
      'price': 30.0
    });
    await db.insert('prices', {
      'vehicleType': 'Normal',
      'serviceType': 'İç + Dış Yıkama',
      'price': 70.0
    });
    await db.insert('prices', {
      'vehicleType': 'SUV',
      'serviceType': 'İç Yıkama',
      'price': 70.0
    });
    await db.insert('prices', {
      'vehicleType': 'SUV',
      'serviceType': 'Dış Yıkama',
      'price': 45.0
    });
    await db.insert('prices', {
      'vehicleType': 'SUV',
      'serviceType': 'İç + Dış Yıkama',
      'price': 100.0
    });
  }

  static Future<double?> getPrice(String vehicleType, String serviceType) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'prices',
        where: 'vehicleType = ? AND serviceType = ?',
        whereArgs: [vehicleType, serviceType]
      );
      
      if (maps.isNotEmpty) {
        return maps.first['price'] as double;
      }
      return null;
    } catch (e) {
      // Eğer prices tablosu yoksa, varsayılan fiyatları oluştur ve tekrar dene
      await _createDefaultPrices(db);
      final List<Map<String, dynamic>> maps = await db.query(
        'prices',
        where: 'vehicleType = ? AND serviceType = ?',
        whereArgs: [vehicleType, serviceType]
      );
      
      if (maps.isNotEmpty) {
        return maps.first['price'] as double;
      }
      return null;
    }
  }

  static Future<void> updatePrice(int id, double price) async {
    final db = await database;
    await db.update(
      'prices',
      {'price': price},
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // Gider kategorileri işlemleri
  static Future<List<ExpenseCategory>> getExpenseCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expense_categories', orderBy: 'name');
    return List.generate(maps.length, (i) => ExpenseCategory.fromMap(maps[i]));
  }

  static Future<ExpenseCategory> addExpenseCategory(String name, String? description) async {
    final db = await database;
    final id = await db.insert('expense_categories', {
      'name': name,
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return ExpenseCategory(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  static Future<void> updateExpenseCategory(int id, String name, String? description) async {
    final db = await database;
    await db.update(
      'expense_categories',
      {
        'name': name,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  static Future<void> deleteExpenseCategory(int id) async {
    final db = await database;
    await db.delete(
      'expense_categories',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // Gider işlemleri
  static Future<List<Expense>> getExpensesByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'date DESC'
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  static Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC'
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  static Future<Expense> addExpense(String category, String description, double amount, DateTime date) async {
    final db = await database;
    final id = await db.insert('expenses', {
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    });
    return Expense(
      id: id,
      category: category,
      description: description,
      amount: amount,
      date: date,
    );
  }

  static Future<void> updateExpense(int id, String category, String description, double amount, DateTime date) async {
    final db = await database;
    await db.update(
      'expenses',
      {
        'category': category,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  static Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // Güncellenmiş rapor işlemleri
  static Future<Map<String, dynamic>> getReport(DateTime startDate, DateTime endDate) async {
    final customers = await getCustomersByDateRange(startDate, endDate);
    final expenses = await getExpensesByDateRange(startDate, endDate);
    
    double totalEarnings = 0;
    double totalExpenses = 0;
    Map<String, int> serviceCounts = {};
    Map<String, int> vehicleCounts = {};
    Map<String, double> expenseByCategory = {};
    
    for (var customer in customers) {
      totalEarnings += customer.price;
      serviceCounts[customer.serviceType] = (serviceCounts[customer.serviceType] ?? 0) + 1;
      vehicleCounts[customer.vehicleType] = (vehicleCounts[customer.vehicleType] ?? 0) + 1;
    }
    
    for (var expense in expenses) {
      totalExpenses += expense.amount;
      expenseByCategory[expense.category] = (expenseByCategory[expense.category] ?? 0) + expense.amount;
    }
    
    return {
      'totalCustomers': customers.length,
      'totalEarnings': totalEarnings,
      'totalExpenses': totalExpenses,
      'netProfit': totalEarnings - totalExpenses,
      'serviceCounts': serviceCounts,
      'vehicleCounts': vehicleCounts,
      'expenseByCategory': expenseByCategory,
      'customers': customers,
      'expenses': expenses,
    };
  }

  // Yardımcı fonksiyonlar
  static String _normalizePlate(String plate) {
    return plate
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ş', 'S')
        .replaceAll('Ö', 'O')
        .replaceAll(' ', '');
  }

  static String _normalizeText(String text) {
    return text
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ş', 'S')
        .replaceAll('Ö', 'O');
  }
} 