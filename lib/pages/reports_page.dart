import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import 'dart:math';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;
  List<Map<String, dynamic>> _dailyReports = [];
  List<Map<String, dynamic>> _monthlyReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // IndexedStack'i güncelle
    });
    _generateReport();
    _loadDailyReports();
    _loadMonthlyReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Public refresh method
  void refresh() {
    _generateReport();
    _loadDailyReports();
    _loadMonthlyReports();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await DatabaseService.getReport(_startDate, _endDate);
      setState(() {
        _reportData = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Rapor oluşturulurken hata oluştu');
    }
  }

  Future<void> _loadDailyReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> dailyReports = [];
      final now = DateTime.now();
      
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        // Günün başlangıcı ve sonu için tarih aralığı oluştur
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        final report = await DatabaseService.getReport(startOfDay, endOfDay);
        
        if (report['totalEarnings'] > 0 || report['totalExpenses'] > 0) {
          dailyReports.add({
            'date': date,
            'totalIncome': report['totalEarnings'],
            'totalExpenses': report['totalExpenses'],
            'netProfit': report['netProfit'],
            'customerCount': report['totalCustomers'],
            'expenseCount': report['expenses'].length,
          });
        }
      }
      
      setState(() {
        _dailyReports = dailyReports.reversed.toList(); // En yakın tarih üstte
        _isLoading = false;
      });
    } catch (e) {
      print('Günlük raporlar hatası: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Günlük raporlar yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _loadMonthlyReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> monthlyReports = [];
      final now = DateTime.now();
      
      for (int i = 11; i >= 0; i--) {
        final year = now.year;
        final month = now.month - i;
        
        if (month <= 0) {
          final adjustedYear = year - 1;
          final adjustedMonth = month + 12;
          final startDate = DateTime(adjustedYear, adjustedMonth, 1);
          final endDate = DateTime(adjustedYear, adjustedMonth + 1, 0);
          final report = await DatabaseService.getReport(startDate, endDate);
          
          if (report['totalEarnings'] > 0 || report['totalExpenses'] > 0) {
            monthlyReports.add({
              'year': adjustedYear,
              'month': adjustedMonth,
              'totalIncome': report['totalEarnings'],
              'totalExpenses': report['totalExpenses'],
              'netProfit': report['netProfit'],
              'customerCount': report['totalCustomers'],
              'expenseCount': report['expenses'].length,
            });
          }
        } else {
          final startDate = DateTime(year, month, 1);
          final endDate = DateTime(year, month + 1, 0);
          final report = await DatabaseService.getReport(startDate, endDate);
          
          if (report['totalEarnings'] > 0 || report['totalExpenses'] > 0) {
            monthlyReports.add({
              'year': year,
              'month': month,
              'totalIncome': report['totalEarnings'],
              'totalExpenses': report['totalExpenses'],
              'netProfit': report['netProfit'],
              'customerCount': report['totalCustomers'],
              'expenseCount': report['expenses'].length,
            });
          }
        }
      }
      
      setState(() {
        _monthlyReports = monthlyReports.reversed.toList(); // En yakın ay üstte
        _isLoading = false;
      });
    } catch (e) {
      print('Aylık raporlar hatası: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Aylık raporlar yüklenirken hata oluştu: $e');
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

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
      _generateReport();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tarih Aralığı'),
            Tab(text: 'Günlük Raporlar'),
            Tab(text: 'Aylık Raporlar'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [
          _buildDateRangeTab(),
          _buildDailyReportsTab(),
          _buildMonthlyReportsTab(),
        ],
      ),
    );
  }

  Widget _buildDateRangeTab() {
    return Column(
      children: [
        // Tarih seçimi
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectStartDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd.MM.yyyy').format(_startDate)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('ile', style: TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectEndDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd.MM.yyyy').format(_endDate)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Rapor içeriği
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reportData == null
                  ? const Center(child: Text('Rapor bulunamadı'))
                  : RefreshIndicator(
                      onRefresh: _generateReport,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Özet kartları
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Toplam Servis',
                                    _reportData!['totalCustomers'].toString(),
                                    Icons.people,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Toplam Gelir',
                                    '${_reportData!['totalEarnings'].toStringAsFixed(2)} ₺',
                                    Icons.trending_up,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Toplam Gider',
                                    '${_reportData!['totalExpenses'].toStringAsFixed(2)} ₺',
                                    Icons.trending_down,
                                    Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Net Kazanç',
                                    '${_reportData!['netProfit'].toStringAsFixed(2)} ₺',
                                    Icons.account_balance_wallet,
                                    _reportData!['netProfit'] >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Hizmet dağılımı
                            _buildSectionCard(
                              'Hizmet Dağılımı',
                              _reportData!['serviceCounts'] as Map<String, int>,
                              Icons.local_car_wash,
                            ),
                            const SizedBox(height: 16),
                            
                            // Araç dağılımı
                            _buildSectionCard(
                              'Araç Dağılımı',
                              _reportData!['vehicleCounts'] as Map<String, int>,
                              Icons.directions_car,
                            ),
                            const SizedBox(height: 16),
                            
                            // Gider kategorileri
                            if (_reportData!['expenseByCategory'] != null)
                              _buildExpenseCategoryCard(
                                'Gider Kategorileri',
                                _reportData!['expenseByCategory'] as Map<String, double>,
                                Icons.category,
                              ),
                            const SizedBox(height: 16),
                            
                            // Müşteri listesi
                            _buildCustomerList(_reportData!['customers'] as List<Customer>),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildDailyReportsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadDailyReports,
            child: _dailyReports.isEmpty
                ? const Center(
                    child: Text(
                      'Son 30 günde rapor bulunamadı',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100), // Daha az alt boşluk
                    itemCount: _dailyReports.length,
                    itemBuilder: (context, index) {
                      final report = _dailyReports[index];
                      final date = report['date'] as DateTime;
                      final totalIncome = report['totalIncome'] as double;
                      final totalExpenses = report['totalExpenses'] as double;
                      final netProfit = report['netProfit'] as double;
                      final customerCount = report['customerCount'] as int;
                      final expenseCount = report['expenseCount'] as int;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Sol taraf - Tarih ve detaylar
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd.MM.yyyy').format(date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.people, size: 14, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$customerCount',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.receipt, size: 14, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$expenseCount',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Sağ taraf - Finansal bilgiler
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${totalIncome.toStringAsFixed(0)} ₺',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '-${totalExpenses.toStringAsFixed(0)} ₺',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: netProfit >= 0 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${netProfit.toStringAsFixed(0)} ₺',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: netProfit >= 0 ? Colors.green : Colors.orange,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
  }

  Widget _buildMonthlyReportsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadMonthlyReports,
            child: _monthlyReports.isEmpty
                ? const Center(
                    child: Text(
                      'Son 12 ayda rapor bulunamadı',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100), // Daha az alt boşluk
                    itemCount: _monthlyReports.length,
                    itemBuilder: (context, index) {
                      final report = _monthlyReports[index];
                      final year = report['year'] as int;
                      final month = report['month'] as int;
                      final totalIncome = report['totalIncome'] as double;
                      final totalExpenses = report['totalExpenses'] as double;
                      final netProfit = report['netProfit'] as double;
                      final customerCount = report['customerCount'] as int;
                      final expenseCount = report['expenseCount'] as int;

                      final monthNames = [
                        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
                      ];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Sol taraf - Ay ve detaylar
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${monthNames[month - 1]} $year',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.people, size: 14, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$customerCount',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.receipt, size: 14, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$expenseCount',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Sağ taraf - Finansal bilgiler
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${totalIncome.toStringAsFixed(0)} ₺',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '-${totalExpenses.toStringAsFixed(0)} ₺',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: netProfit >= 0 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${netProfit.toStringAsFixed(0)} ₺',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: netProfit >= 0 ? Colors.green : Colors.orange,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Map<String, int> data, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title == 'Araç Dağılımı' ? _formatVehicleType(entry.key) : entry.key),
                  Text(
                    '${entry.value} adet',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCategoryCard(String title, Map<String, double> data, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    '${entry.value.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(List<Customer> customers) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Servis Kayıtları (${customers.length} adet)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...customers.map((customer) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${customer.formattedPlate} - ${customer.serviceType}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${customer.price.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _formatVehicleType(String vehicleType) {
    return vehicleType == 'Normal' ? 'Normal Araç' : 'SUV Araç';
  }


} 