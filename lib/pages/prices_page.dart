import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  List<Map<String, dynamic>> _prices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 _loadPrices başlatılıyor...');
      final prices = await DatabaseService.getAllPrices();
      print('📊 ${prices.length} fiyat alındı');
      
      // Fiyatları düzenli sırala: İç Yıkama, Dış Yıkama, İç + Dış Yıkama
      final sortedPrices = List<Map<String, dynamic>>.from(prices);
      sortedPrices.sort((a, b) {
        final serviceOrder = {'İç Yıkama': 1, 'Dış Yıkama': 2, 'İç + Dış Yıkama': 3};
        final aOrder = serviceOrder[a['serviceType']] ?? 0;
        final bOrder = serviceOrder[b['serviceType']] ?? 0;
        
        if (aOrder != bOrder) {
          return aOrder.compareTo(bOrder);
        }
        
        // Aynı hizmet tipinde araç tipine göre sırala: Normal, SUV
        final vehicleOrder = {'Normal': 1, 'SUV': 2};
        final aVehicleOrder = vehicleOrder[a['vehicleType']] ?? 0;
        final bVehicleOrder = vehicleOrder[b['vehicleType']] ?? 0;
        
        return aVehicleOrder.compareTo(bVehicleOrder);
      });
      
      print('✅ Fiyatlar başarıyla yüklendi ve sıralandı');
      setState(() {
        _prices = sortedPrices;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ _loadPrices hatası: $e');
      print('📚 Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Fiyatlar yüklenirken hata oluştu: $e');
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

  Future<void> _editPrice(Map<String, dynamic> price) async {
    final TextEditingController priceController = TextEditingController(
      text: price['price'].toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_formatVehicleType(price['vehicleType'])} - ${price['serviceType']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  price['vehicleType'] == 'Normal' ? Icons.directions_car : Icons.local_shipping,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatVehicleType(price['vehicleType']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getServiceIcon(price['serviceType']),
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  price['serviceType'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Fiyat (₺)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice == null || newPrice < 0) {
                _showErrorSnackBar('Geçerli bir fiyat girin');
                return;
              }
              
              try {
                await DatabaseService.updatePrice(price['id'], newPrice);
                Navigator.pop(context, true);
                _loadPrices();
                _showSuccessSnackBar('Fiyat başarıyla güncellendi');
              } catch (e) {
                _showErrorSnackBar('Fiyat güncellenirken hata oluştu');
              }
            },
            child: const Text('Güncelle'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadPrices();
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'İç Yıkama':
        return Icons.cleaning_services;
      case 'Dış Yıkama':
        return Icons.water_drop;
      case 'İç + Dış Yıkama':
        return Icons.local_car_wash;
      default:
        return Icons.local_car_wash;
    }
  }

  String _formatVehicleType(String vehicleType) {
    return vehicleType == 'Normal' ? 'Normal Araç' : 'SUV Araç';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiyatlandırma'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPrices,
              child: ListView.builder(
                itemCount: _prices.length,
                itemBuilder: (context, index) {
                  final price = _prices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: price['vehicleType'] == 'Normal' 
                            ? Colors.blue[100] 
                            : Colors.orange[100],
                        child: Icon(
                          price['vehicleType'] == 'Normal' 
                              ? Icons.directions_car 
                              : Icons.local_shipping,
                          color: price['vehicleType'] == 'Normal' 
                              ? Colors.blue[700] 
                              : Colors.orange[700],
                        ),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            _getServiceIcon(price['serviceType']),
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              price['serviceType'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        _formatVehicleType(price['vehicleType']),
                        style: TextStyle(
                          color: price['vehicleType'] == 'Normal' 
                              ? Colors.blue[700] 
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${price['price'].toStringAsFixed(2)} ₺',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _editPrice(price),
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Fiyatı Düzenle',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
} 