import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/database_service.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedServiceType = 'İç Yıkama';
  String _selectedVehicleType = 'Normal';
  double _calculatedPrice = 0.0;
  bool _isLoading = false;

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
    _calculatePrice();
  }

  Future<void> _calculatePrice() async {
    try {
      final price = await DatabaseService.getPrice(_selectedVehicleType, _selectedServiceType);
      setState(() {
        _calculatedPrice = price ?? 0.0;
      });
    } catch (e) {
      setState(() {
        _calculatedPrice = 0.0;
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

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        name: _nameController.text.trim(),
        plate: _formatPlate(_plateController.text),
        phone: _phoneController.text.trim(),
        serviceType: _selectedServiceType,
        vehicleType: _selectedVehicleType,
        price: _calculatedPrice,
        timestamp: DateTime.now(),
        notes: _notesController.text.trim(),
      );

      await DatabaseService.insertCustomer(customer);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servis kaydı başarıyla eklendi'),
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
        title: const Text('Yeni Servis Kaydı'),
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
                labelText: 'Müşteri Adı (Opsiyonel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Müşteri adı giriniz',
              ),
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
                labelText: 'Telefon (Opsiyonel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '0555 123 45 67',
              ),
              keyboardType: TextInputType.phone,
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
                });
                _calculatePrice();
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notlar (Opsiyonel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Ek notlarınızı yazabilirsiniz',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Fiyat: ${_calculatedPrice.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
                onPressed: _isLoading ? null : _saveCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kaydet',
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
    _notesController.dispose();
    super.dispose();
  }
} 