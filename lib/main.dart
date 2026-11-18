import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام المبيعات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.cairoTextTheme(), // خط عربي
        primarySwatch: Colors.indigo,
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

  // قائمة المنتجات
  List<Map<String, dynamic>> products = [];
  // اسم المحل
  String storeName = "محل الكهربائيات والإنشائيات";

  @override
  void initState() {
    super.initState();
    _loadData(); // تحميل البيانات عند فتح التطبيق
  }

  // دالة تحميل البيانات من ذاكرة الهاتف
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedProducts = prefs.getString('products');
    String? savedName = prefs.getString('storeName');
    setState(() {
      if (savedProducts != null) {
        products = List<Map<String, dynamic>>.from(jsonDecode(savedProducts));
      }
      if (savedName != null) storeName = savedName;
    });
  }

  // دالة حفظ البيانات في ذاكرة الهاتف
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', jsonEncode(products));
    await prefs.setString('storeName', storeName);
  }

  // نافذة إضافة منتج جديد
  void _addProductDialog() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController priceCtrl = TextEditingController();
    TextEditingController qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منتج جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المنتج')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'السعر'), keyboardType: TextInputType.number),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'الكمية'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                setState(() {
                  products.add({
                    'name': nameCtrl.text,
                    'price': double.parse(priceCtrl.text),
                    'qty': int.parse(qtyCtrl.text),
                  });
                });
                _saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(storeName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => setState(() => _currentIndex = 4), // الانتقال للإعدادات
          )
        ],
      ),
      body: _currentIndex == 0 
          ? _buildInventory() 
          : _currentIndex == 4 
              ? _buildSettings() 
              : const Center(child: Text('هذه الصفحة قيد التطوير حالياً')),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _addProductDialog,
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'بيع'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'الديون'),
          BottomNavigationBarItem(icon: Icon(Icons.construction), label: 'الإيجار'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }

  // واجهة المخزن
  Widget _buildInventory() {
    if (products.isEmpty) {
      return const Center(child: Text('المخزن فارغ. اضغط على + لإضافة منتج'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          child: ListTile(
            title: Text(p['name']),
            subtitle: Text('السعر: ${p['price']} | الكمية: ${p['qty']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => products.removeAt(index));
                _saveData();
              },
            ),
          ),
        );
      },
    );
  }

  // واجهة الإعدادات
  Widget _buildSettings() {
    TextEditingController storeCtrl = TextEditingController(text: storeName);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text('إعدادات المحل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: storeCtrl,
            decoration: const InputDecoration(labelText: 'اسم المحل', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() => storeName = storeCtrl.text);
              _saveData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')));
            },
            child: const Text('حفظ التعديلات'),
          )
        ],
      ),
    );
  }
}
