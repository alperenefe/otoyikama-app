import 'package:flutter/material.dart';
import '../models/expense_category.dart';
import '../services/database_service.dart';
import 'prices_page.dart';
import 'add_expense_category_page.dart';

class CustomizationPage extends StatefulWidget {
  const CustomizationPage({super.key});

  @override
  State<CustomizationPage> createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // FloatingActionButton'ı güncellemek için
    });
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await DatabaseService.getExpenseCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Kategoriler yüklenirken hata oluştu');
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Özelleştirme'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'FİYATLAR', icon: Icon(Icons.attach_money)),
            Tab(text: 'GİDER KATEGORİLERİ', icon: Icon(Icons.category)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const PricesPage(),
          _buildExpenseCategoriesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _addCategory,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildExpenseCategoriesTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadCategories,
            child: _categories.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz kategori eklenmemiş',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: category.description != null
                              ? Text(category.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editCategory(category),
                                tooltip: 'Düzenle',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCategory(category),
                                tooltip: 'Sil',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseCategoryPage(),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _editCategory(ExpenseCategory category) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseCategoryPage(category: category),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(ExpenseCategory category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Sil'),
        content: Text('${category.name} kategorisini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await DatabaseService.deleteExpenseCategory(category.id!);
        _loadCategories();
        _showSuccessSnackBar('Kategori başarıyla silindi');
      } catch (e) {
        _showErrorSnackBar('Kategori silinirken hata oluştu');
      }
    }
  }
} 