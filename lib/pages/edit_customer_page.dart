import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final TextEditingController _nameController;
  late final TextEditingController _plateController;
  late final TextEditingController _phoneController;
  late final TextEditingController _priceController;
  
  late String _selectedServiceType;
  late String _selectedVehicleType;
  double _calculatedPrice = 0.0;
  bool _isLoading = false;
  bool _isManualPrice = false;

  final List<String> _serviceTypes = [
    'İç Yıkama',
    'Dış Yıkama',
    'İç + Dış Yıkama',
  ];

  final List<String> _vehicleTypes = [
    'Normal',
    'SUV',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _plateController = TextEditingController(text: widget.customer.plate);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _priceController = TextEditingController(text: widget.customer.price.toStringAsFixed(2));
    _selectedServiceType = widget.customer.serviceType;
    _selectedVehicleType = widget.customer.vehicleType;
    _calculatedPrice = widget.customer.price;
  }

  Future<void> _calculatePrice() async {
    if (_isManualPrice) return; // Manuel fiyat aktifse hesaplama yapma
    
    try {
      final price = await DatabaseService.getPrice(_selectedVehicleType, _selectedServiceType);
      setState(() {
        _calculatedPrice = price ?? 0.0;
        _priceController.text = _calculatedPrice.toStringAsFixed(2);
      });
    } catch (e) {
      setState(() {
        _calculatedPrice = 0.0;
        _priceController.text = '0.00';
      });
    }
  }

  String _formatPlate(String plate) {
    // Boşlukları kaldır ve büyük harfe çevir
    String formatted = plate.replaceAll(' ', '').toUpperCase();
    
    // Sadece harf, rakam ve Türk karakterleri kabul et
    formatted = formatted.replaceAll(RegExp(r'[^A-Z0-9İĞÜŞÖÇ]'), '');
    
    return formatted;
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final manualPrice = double.tryParse(_priceController.text) ?? _calculatedPrice;
      
      final updatedCustomer = widget.customer.copyWith(
        name: _nameController.text.trim(),
        plate: _formatPlate(_plateController.text),
        phone: _phoneController.text.trim(),
        serviceType: _selectedServiceType,
        vehicleType: _selectedVehicleType,
        price: manualPrice,
      );

      await DatabaseService.updateCustomer(updatedCustomer);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servis kaydı başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatVehicleType(String vehicleType) {
    return vehicleType == 'Normal' ? 'Normal Araç' : 'SUV Araç';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servis Kaydını Düzenle'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Müşteri Adı',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Müşteri adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Plaka',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
                hintText: '34ABC123',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Plaka gerekli';
                }
                final formatted = _formatPlate(value);
                if (formatted.length < 5) {
                  return 'Geçerli bir plaka girin';
                }
                return null;
              },
              onChanged: (value) {
                // Plaka formatını göster
                final formatted = _formatPlate(value);
                if (formatted != value.toUpperCase()) {
                  _plateController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '0555 123 45 67',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              decoration: const InputDecoration(
                labelText: 'Araç Tipi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _vehicleTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_formatVehicleType(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleType = value!;
                  _isManualPrice = false; // Araç tipi değişince otomatik fiyat
                });
                _calculatePrice();
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedServiceType,
              decoration: const InputDecoration(
                labelText: 'Hizmet Tipi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_car_wash),
              ),
              items: _serviceTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServiceType = value!;
                  _isManualPrice = false; // Hizmet tipi değişince otomatik fiyat
                });
                _calculatePrice();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Fiyat (₺)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _isManualPrice = true; // Manuel fiyat girildi
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Fiyat gerekli';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Geçerli bir fiyat girin';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isManualPrice = false;
                    });
                    _calculatePrice();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Otomatik Fiyat Hesapla',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isManualPrice ? Colors.orange[50] : Colors.green[50],
                border: Border.all(color: _isManualPrice ? Colors.orange : Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isManualPrice ? Icons.edit : Icons.attach_money,
                    color: _isManualPrice ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isManualPrice ? 'Manuel Fiyat' : 'Otomatik Fiyat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isManualPrice ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Güncelle',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }
} 