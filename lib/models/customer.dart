class Customer {
  final int? id;
  final String name;
  final String plate;
  final String phone;
  final String serviceType;
  final String vehicleType;
  final double price;
  final DateTime timestamp;
  final String notes;

  Customer({
    this.id,
    required this.name,
    required this.plate,
    required this.phone,
    required this.serviceType,
    required this.vehicleType,
    required this.price,
    required this.timestamp,
    this.notes = '',
  });

  String get formattedPlate {
    if (plate.length < 2) return plate;
    
    // Türk plaka formatları
    if (plate.length == 5) {
      // 34ABC formatı
      return '${plate.substring(0, 2)} ${plate.substring(2)}';
    } else if (plate.length == 6) {
      // 34ABC1 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 7) {
      // 34ABC12 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 8) {
      // 34ABC123 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 9) {
      // 34ABC1234 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 10) {
      // 34ABC12345 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 11) {
      // 34ABC123456 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 12) {
      // 34ABC1234567 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 13) {
      // 34ABC12345678 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 14) {
      // 34ABC123456789 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    } else if (plate.length == 15) {
      // 34ABC1234567890 formatı
      return '${plate.substring(0, 2)} ${plate.substring(2, 5)} ${plate.substring(5)}';
    }
    
    return plate;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'plate': plate,
      'phone': phone,
      'serviceType': serviceType,
      'vehicleType': vehicleType,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      plate: map['plate'] as String,
      phone: map['phone'] as String,
      serviceType: map['serviceType'] as String,
      vehicleType: map['vehicleType'] as String? ?? 'Normal',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] as String),
      notes: map['notes'] as String? ?? '',
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? plate,
    String? phone,
    String? serviceType,
    String? vehicleType,
    double? price,
    DateTime? timestamp,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      plate: plate ?? this.plate,
      phone: phone ?? this.phone,
      serviceType: serviceType ?? this.serviceType,
      vehicleType: vehicleType ?? this.vehicleType,
      price: price ?? this.price,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
} 