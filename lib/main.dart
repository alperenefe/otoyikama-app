import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/customer.dart';
import 'services/database_service.dart';
import 'pages/add_customer_page.dart';
import 'pages/edit_customer_page.dart';
import 'pages/prices_page.dart';
import 'pages/reports_page.dart';
import 'pages/search_page.dart';
import 'pages/home_tabs_page.dart';
import 'pages/customization_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Database'i başlat
  try {
    await DatabaseService.init();
    print('✅ Database başarıyla başlatıldı');
  } catch (e) {
    print('❌ Database başlatma hatası: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oto Yıkama',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();
  int _reportsPageKey = 0; // ReportsPage'i yeniden oluşturmak için
  int _searchPageKey = 0; // SearchPage'i yeniden oluşturmak için

  void _refreshReportsPage() {
    setState(() {
      _reportsPageKey++; // ReportsPage'i yeniden oluştur
      _searchPageKey++; // SearchPage'i de yeniden oluştur
    });
  }

  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTabsPage(
            selectedDate: _selectedDate,
            onDataChanged: _refreshReportsPage,
            onDateChanged: _updateSelectedDate,
          ),
          SearchPage(
            key: ValueKey(_searchPageKey),
          ),
          ReportsPage(key: ValueKey(_reportsPageKey)),
          const CustomizationPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Raporlar sekmesine geçince otomatik yenile
          if (index == 2) {
            _refreshReportsPage();
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Arama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Raporlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Özelleştirme',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback? onCustomerAdded;

  const HomePage({
    super.key,
    required this.selectedDate,
    this.onCustomerAdded,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadCustomers();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await DatabaseService.getCustomersByDate(widget.selectedDate);
      setState(() {
        _customers = customers;
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != widget.selectedDate) {
      setState(() {
        // selectedDate'yi güncellemek için parent'a bildir
      });
      // Parent widget'ı güncellemek için callback kullan
      if (mounted) {
        final mainScreen = context.findAncestorStateOfType<_MainScreenState>();
        if (mainScreen != null) {
          mainScreen.setState(() {
            mainScreen._selectedDate = picked;
          });
        }
      }
    }
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

  void _showEditOptions(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servis Kaydı İşlemleri'),
        content: Text('${customer.name} için ne yapmak istiyorsunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteDialog(customer);
            },
            child: const Text('Sil'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCustomerPage(customer: customer),
                ),
              );
              if (result == true) {
                _loadCustomers();
                // Raporlar sayfasını da yenile
                widget.onCustomerAdded?.call();
              }
            },
            child: const Text('Düzenle'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _customers.where((customer) {
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      final normalizedQuery = query
          .replaceAll('ı', 'i')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c');
      
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Servis Kayıtları - ${DateFormat('dd.MM.yyyy').format(widget.selectedDate)}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Tarih Seç',
          ),
        ],
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
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Servis kayıtları listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    child: filteredCustomers.isEmpty
                        ? const Center(
                            child: Text(
                              'Bu tarihte servis kaydı bulunamadı',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
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
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEditOptions(customer),
                                        tooltip: 'Düzenle/Sil',
            ),
          ],
        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCustomerPage(),
            ),
          );
          if (result == true) {
            _loadCustomers();
            // Raporlar sayfasını da yenile
            widget.onCustomerAdded?.call();
          }
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
                _loadCustomers();
                // Raporlar sayfasını da yenile
                widget.onCustomerAdded?.call();
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
