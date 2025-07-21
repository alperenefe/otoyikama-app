import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import 'edit_customer_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllCustomers();
  }

  Future<void> _loadAllCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await DatabaseService.getAllCustomers();
      setState(() {
        _allCustomers = customers;
        // Mevcut arama filtresini koru
        if (_searchQuery.isEmpty) {
          _filteredCustomers = customers;
        } else {
          _filterCustomers(_searchQuery);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Servis kayıtları yüklenirken hata oluştu');
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

  @override
  void dispose() {
    super.dispose();
  }

  void _filterCustomers(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredCustomers = _allCustomers;
    } else {
      final normalizedQuery = query.toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c');
      
      _filteredCustomers = _allCustomers.where((customer) {
        final normalizedName = customer.name.toLowerCase()
            .replaceAll('ı', 'i')
            .replaceAll('ğ', 'g')
            .replaceAll('ü', 'u')
            .replaceAll('ş', 's')
            .replaceAll('ö', 'o')
            .replaceAll('ç', 'c');
        
        final normalizedPlate = customer.plate.toLowerCase()
            .replaceAll('ı', 'i')
            .replaceAll('ğ', 'g')
            .replaceAll('ü', 'u')
            .replaceAll('ş', 's')
            .replaceAll('ö', 'o')
            .replaceAll('ç', 'c');
        
        return normalizedName.contains(normalizedQuery) || 
               normalizedPlate.contains(normalizedQuery);
      }).toList();
    }
    
    setState(() {});
  }

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\\s\\-\\(\\)]'), '');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telefon Ara'),
        content: Text('$phoneNumber numarasını aramak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ara'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final url = Uri.parse('tel:$cleanNumber');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          _showSuccessSnackBar('Arama başlatılıyor...');
        } else {
          _showErrorSnackBar('Telefon uygulaması açılamadı');
        }
      } catch (e) {
        _showErrorSnackBar('Arama başlatılamadı');
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
        title: const Text('Tüm Kayıtlarda Arama'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Arama kutusu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Servis Kaydı Ara (Ad veya Plaka)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: 'Müşteri adı veya plaka girin...',
              ),
              onChanged: _filterCustomers,
            ),
          ),
          
          // Sonuç sayısı
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredCustomers.length} sonuç bulundu',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Servis kayıtları listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAllCustomers,
                    child: _filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty 
                                      ? 'Henüz servis kaydı bulunmuyor'
                                      : 'Arama kriterlerine uygun kayıt bulunamadı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  title: Text(
                                    customer.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Plaka: ${customer.formattedPlate}'),
                                      Text('Hizmet: ${customer.serviceType}'),
                                      Text('Araç: ${_formatVehicleType(customer.vehicleType)}'),
                                      Text('Tarih: ${DateFormat('dd.MM.yyyy').format(customer.timestamp)}'),
                                      GestureDetector(
                                        onTap: () => _callPhoneNumber(customer.phone),
                                        child: Text(
                                          'Telefon: ${customer.phone}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${customer.price.toStringAsFixed(2)} ₺',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('HH:mm').format(customer.timestamp),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditCustomerPage(customer: customer),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadAllCustomers();
                                    }
                                  },
                                  onLongPress: () {
                                    _showDeleteDialog(customer);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servis Kaydını Sil'),
        content: Text('${customer.name} (${customer.formattedPlate}) servis kaydını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseService.deleteCustomer(customer.id!);
                _loadAllCustomers();
                _showSuccessSnackBar('Servis kaydı başarıyla silindi');
              } catch (e) {
                _showErrorSnackBar('Servis kaydı silinirken hata oluştu');
              }
            },
            child: const Text('Sil'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
} 