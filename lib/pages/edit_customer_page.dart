import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/database_service.dart';

class EditCustomerPage extends StatefulWidget {
  final Customer customer;

  const EditCustomerPage({super.key, required this.customer});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedVehicleType = '';
  String _selectedServiceType = '';
  double? _price;
  bool _isLoading = false;

  final List<String> _vehicleTypes = ['Normal', 'SUV'];
  final List<String> _serviceTypes = ['İç Yıkama', 'Dış Yıkama', 'İç + Dış Yıkama'];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.customer.name;
    _plateController.text = widget.customer.plate;
    _phoneController.text = widget.customer.phone;
    // Araç tipini güvenli şekilde ayarla
    if (_vehicleTypes.contains(widget.customer.vehicleType)) {
      _selectedVehicleType = widget.customer.vehicleType;
    } else {
      // Eğer araç tipi listede yoksa varsayılan değeri kullan
      _selectedVehicleType = 'Normal';
      print('⚠️ Bilinmeyen araç tipi: ${widget.customer.vehicleType}');
    }
    
    // Servis tipini güvenli şekilde ayarla
    if (_serviceTypes.contains(widget.customer.serviceType)) {
      _selectedServiceType = widget.customer.serviceType;
    } else {
      // Eğer servis tipi listede yoksa varsayılan değeri kullan
      _selectedServiceType = 'İç Yıkama';
      print('⚠️ Bilinmeyen servis tipi: ${widget.customer.serviceType}');
    }
    
    _price = widget.customer.price;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updatePrice() async {
    if (_selectedVehicleType.isEmpty || _selectedServiceType.isEmpty) return;
    
    try {
      final price = await DatabaseService.getPrice(_selectedVehicleType, _selectedServiceType);
      setState(() {
        _price = price ?? 0.0;
      });
    } catch (e) {
      // Hata durumunda mevcut fiyatı koru
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCustomer = Customer(
        id: widget.customer.id,
        name: _nameController.text.trim(),
        plate: _plateController.text.trim(),
        phone: _phoneController.text.trim(),
        serviceType: _selectedServiceType,
        vehicleType: _selectedVehicleType,
        price: _price ?? 0.0,
        timestamp: widget.customer.timestamp,
      );

      await DatabaseService.updateCustomer(updatedCustomer);
      
      _showSuccessSnackBar('Servis kaydı başarıyla güncellendi');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Servis kaydı güncellenirken hata oluştu');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servis Kaydı Düzenle'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Müşteri adı
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Müşteri Adı *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Müşteri adı gereklidir';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Plaka
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(
                        labelText: 'Plaka *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Plaka gereklidir';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Telefon
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Telefon gereklidir';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Araç tipi
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType.isNotEmpty ? _selectedVehicleType : null,
                      decoration: const InputDecoration(
                        labelText: 'Araç Tipi *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      items: _vehicleTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicleType = value ?? 'Normal';
                        });
                        _updatePrice();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Araç tipi seçin';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Hizmet tipi
                    DropdownButtonFormField<String>(
                      value: _selectedServiceType.isNotEmpty ? _selectedServiceType : null,
                      decoration: const InputDecoration(
                        labelText: 'Hizmet Tipi *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_car_wash),
                      ),
                      items: _serviceTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedServiceType = value ?? 'İç Yıkama';
                        });
                        _updatePrice();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Hizmet tipi seçin';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fiyat
                    TextFormField(
                      initialValue: _price?.toStringAsFixed(2),
                      decoration: const InputDecoration(
                        labelText: 'Fiyat (₺) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        _price = double.tryParse(value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Fiyat gereklidir';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Geçerli bir fiyat girin';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Güncelle butonu
                    ElevatedButton(
                      onPressed: _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Güncelle',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 