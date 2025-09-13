import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import 'add_customer_page.dart';
import 'add_expense_page.dart';
import 'edit_customer_page.dart';
import 'edit_expense_page.dart';

class HomeTabsPage extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback? onDataChanged;
  final Function(DateTime)? onDateChanged;

  const HomeTabsPage({
    super.key,
    required this.selectedDate,
    this.onDataChanged,
    this.onDateChanged,
  });

  @override
  State<HomeTabsPage> createState() => _HomeTabsPageState();
}

class _HomeTabsPageState extends State<HomeTabsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Customer> _customers = [];
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomeTabsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await DatabaseService.getCustomersByDate(widget.selectedDate);
      final expenses = await DatabaseService.getExpensesByDate(widget.selectedDate);
      
      setState(() {
        _customers = customers;
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Veriler yüklenirken hata oluştu');
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
      // Parent widget'ı güncellemek için callback kullan
      if (mounted) {
        // Tarih değişikliğini parent'a bildir
        widget.onDateChanged?.call(picked);
        // Data changed callback'ini de çağır
        widget.onDataChanged?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa - ${DateFormat('dd.MM.yyyy').format(widget.selectedDate)}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Tarih Seç',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'GELİRLER', icon: Icon(Icons.trending_up)),
            Tab(text: 'GİDERLER', icon: Icon(Icons.trending_down)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomeTab(),
          _buildExpenseTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _addCustomer();
          } else if (_tabController.index == 1) {
            _addExpense();
          }
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: Icon(_tabController.index == 0 ? Icons.add : Icons.remove),
      ),
    );
  }

  Widget _buildIncomeTab() {
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

    return Column(
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
                  onRefresh: _loadData,
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
                                    if (customer.phone.isNotEmpty)
                                      InkWell(
                                        onTap: () => _callCustomer(customer.phone),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone, size: 16, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              customer.phone,
                                              style: const TextStyle(color: Colors.blue),
                                            ),
                                          ],
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
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.blue),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _editCustomer(customer);
                                            break;
                                          case 'delete':
                                            _showDeleteCustomerDialog(customer);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Düzenle'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Sil'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildExpenseTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: _expenses.isEmpty
                ? const Center(
                    child: Text(
                      'Bu tarihte gider kaydı bulunamadı',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            expense.description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Kategori: ${expense.category}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '-${expense.amount.toStringAsFixed(2)} ₺',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(expense.date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.red),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editExpense(expense);
                                      break;
                                    case 'delete':
                                      _showDeleteExpenseDialog(expense);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Düzenle'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Sil'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
  }

  Widget _buildSummaryTab() {
    final totalIncome = _customers.fold<double>(0, (sum, customer) => sum + customer.price);
    final totalExpense = _expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final netProfit = totalIncome - totalExpense;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Günlük Özet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Gelir',
                          totalIncome,
                          Colors.green,
                          Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          'Gider',
                          totalExpense,
                          Colors.red,
                          Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCard(
                    'Net Kazanç',
                    netProfit,
                    netProfit >= 0 ? Colors.blue : Colors.orange,
                    Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detaylar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Servis Sayısı: ${_customers.length}'),
                  Text('Gider Sayısı: ${_expenses.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(2)} ₺',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVehicleType(String vehicleType) {
    return vehicleType == 'Normal' ? 'Normal Araç' : 'SUV Araç';
  }

  Future<void> _addCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCustomerPage(),
      ),
    );
    if (result == true) {
      _loadData();
      widget.onDataChanged?.call();
    }
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpensePage(),
      ),
    );
    if (result == true) {
      _loadData();
      widget.onDataChanged?.call();
    }
  }

  Future<void> _editCustomer(Customer customer) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerPage(customer: customer),
      ),
    );

    if (result == true) {
      _loadData();
      widget.onDataChanged?.call();
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpensePage(expense: expense),
      ),
    );

    if (result == true) {
      _loadData();
      widget.onDataChanged?.call();
    }
  }

  Future<void> _callCustomer(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar('Telefon numarası aranamadı');
      }
    } catch (e) {
      _showErrorSnackBar('Telefon numarası aranamadı');
    }
  }

  Future<void> _showDeleteCustomerDialog(Customer customer) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Müşteri Kaydını Sil'),
          content: Text('${customer.name} (${customer.plate}) kaydını silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteCustomer(customer);
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteExpenseDialog(Expense expense) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gider Kaydını Sil'),
          content: Text('${expense.description} (${expense.amount.toStringAsFixed(2)} ₺) kaydını silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteExpense(expense);
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    try {
      if (customer.id != null) {
        await DatabaseService.deleteCustomer(customer.id!);
        _showSuccessSnackBar('Müşteri kaydı başarıyla silindi');
        _loadData();
        widget.onDataChanged?.call();
      } else {
        _showErrorSnackBar('Müşteri ID bulunamadı');
      }
    } catch (e) {
      _showErrorSnackBar('Müşteri kaydı silinirken hata oluştu');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      if (expense.id != null) {
        await DatabaseService.deleteExpense(expense.id!);
        _showSuccessSnackBar('Gider kaydı başarıyla silindi');
        _loadData();
        widget.onDataChanged?.call();
      } else {
        _showErrorSnackBar('Gider ID bulunamadı');
      }
    } catch (e) {
      _showErrorSnackBar('Gider kaydı silinirken hata oluştu');
    }
  }
} 