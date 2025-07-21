import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';

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
      version: 5, // Versiyonu 5'e çıkardık
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
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Database upgrade: $oldVersion -> $newVersion');
    
    if (oldVersion < 5) {
      // Versiyon 5 için tüm tabloları yeniden oluştur
      try {
        print('🗑️ Eski tablolar siliniyor...');
        // Tüm tabloları sil
        await db.execute('DROP TABLE IF EXISTS customers');
        await db.execute('DROP TABLE IF EXISTS prices');
        
        print('📋 Yeni tablolar oluşturuluyor...');
        // Yeni tabloları oluştur
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
        
        await db.execute('''
          CREATE TABLE prices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicleType TEXT NOT NULL,
            serviceType TEXT NOT NULL,
            price REAL NOT NULL,
            UNIQUE(vehicleType, serviceType)
          )
        ''');
        
        print('💰 Varsayılan fiyatlar ekleniyor...');
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
        
        print('✅ Database version 5 upgrade başarılı - Tüm tablolar yeniden oluşturuldu');
      } catch (e) {
        print('❌ Versiyon 5 upgrade hatası: $e');
        print('📚 Stack trace: ${StackTrace.current}');
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
    try {
      print('🔍 getAllPrices başlatılıyor...');
      final db = await database;
      print('✅ Database bağlantısı başarılı');
      
      // Basit sorgu yap
      final prices = await db.query('prices', orderBy: 'vehicleType, serviceType');
      print('📊 ${prices.length} fiyat bulundu');
      
      if (prices.isEmpty) {
        print('⚠️ Fiyatlar boş, varsayılan fiyatlar ekleniyor...');
        await _insertDefaultPrices(db);
        return await db.query('prices', orderBy: 'vehicleType, serviceType');
      }
      
      return prices;
    } catch (e) {
      print('❌ getAllPrices hatası: $e');
      print('📚 Stack trace: ${StackTrace.current}');
      
      // Hata durumunda varsayılan fiyatları döndür
      return [
        {'vehicleType': 'Normal', 'serviceType': 'İç Yıkama', 'price': 50.0},
        {'vehicleType': 'Normal', 'serviceType': 'Dış Yıkama', 'price': 30.0},
        {'vehicleType': 'Normal', 'serviceType': 'İç + Dış Yıkama', 'price': 70.0},
        {'vehicleType': 'SUV', 'serviceType': 'İç Yıkama', 'price': 70.0},
        {'vehicleType': 'SUV', 'serviceType': 'Dış Yıkama', 'price': 45.0},
        {'vehicleType': 'SUV', 'serviceType': 'İç + Dış Yıkama', 'price': 100.0},
      ];
    }
  }

  static Future<void> _createDefaultPrices(Database db) async {
    // Fiyatlar tablosunu oluştur
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

  static Future<void> _insertDefaultPrices(Database db) async {
    print('💰 Varsayılan fiyatlar ekleniyor...');
    
    // Önce tabloyu oluştur
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
    
    print('✅ Varsayılan fiyatlar eklendi');
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

  // Rapor işlemleri
  static Future<Map<String, dynamic>> getReport(DateTime startDate, DateTime endDate) async {
    final customers = await getCustomersByDateRange(startDate, endDate);
    
    double totalEarnings = 0;
    Map<String, int> serviceCounts = {};
    Map<String, int> vehicleCounts = {};
    
    for (var customer in customers) {
      totalEarnings += customer.price;
      
      serviceCounts[customer.serviceType] = (serviceCounts[customer.serviceType] ?? 0) + 1;
      vehicleCounts[customer.vehicleType] = (vehicleCounts[customer.vehicleType] ?? 0) + 1;
    }
    
    return {
      'totalCustomers': customers.length,
      'totalEarnings': totalEarnings,
      'serviceCounts': serviceCounts,
      'vehicleCounts': vehicleCounts,
      'customers': customers,
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