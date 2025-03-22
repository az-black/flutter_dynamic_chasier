import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const KasirApp());
}

class KasirApp extends StatelessWidget {
  const KasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir Sederhana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomeKasir(),
    );
  }
}

class HomeKasir extends StatefulWidget {
  const HomeKasir({super.key});

  @override
  State<HomeKasir> createState() => _HomeKasirState();
}

class _HomeKasirState extends State<HomeKasir> with TickerProviderStateMixin {
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final currencyFormatter = NumberFormat('#,###', 'id_ID');
  late TabController _tabController;

  List<Map<String, dynamic>> produkBaru = [];
  List<Map<String, dynamic>> produkLama = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _paymentController.addListener(() {
      final text = _paymentController.text.replaceAll('.', '');
      final newText = formatCurrency(text);
      if (_paymentController.text != newText) {
        _paymentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    });
  }

  String formatCurrency(String value) {
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null) return '';
    return NumberFormat('#,###', 'id_ID').format(number);
  }

  List<Map<String, dynamic>> get semuaProdukAktif => [
    ...produkBaru.where((p) => p['qty'] > 0),
    ...produkLama.where((p) => p['qty'] > 0),
  ];

  int get total => semuaProdukAktif.fold(0, (sum, item) {
    int price = item['price'] ?? 0;
    int qty = item['qty'] ?? 0;
    return sum + price * qty;
  });

  void _updateQty(List<Map<String, dynamic>> list, int index, dynamic value) {
    setState(() {
      if (value is int) {
        list[index]['qty'] += value;
      } else if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) list[index]['qty'] = parsed;
      }
      if (list[index]['qty'] < 0) {
        list[index]['qty'] = 0;
      }
    });
  }

  void _editProduk(List<Map<String, dynamic>> list, int index) {
    final item = list[index];
    final nameController = TextEditingController(text: item['name']);
    final priceController = TextEditingController(text: item['price'].toString());
    final categoryController = TextEditingController(text: item['category'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nama')),
            TextField(controller: priceController, decoration: InputDecoration(labelText: 'Harga'), keyboardType: TextInputType.number),
            TextField(controller: categoryController, decoration: InputDecoration(labelText: 'Kategori')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            child: Text('Simpan'),
            onPressed: () {
              setState(() {
                list[index]['name'] = nameController.text;
                list[index]['price'] = int.tryParse(priceController.text) ?? 0;
                list[index]['category'] = categoryController.text;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _hapusProduk(List<Map<String, dynamic>> list, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            child: Text('Hapus'),
            onPressed: () {
              setState(() {
                list.removeAt(index);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _addProduct(List<Map<String, dynamic>> list, String name, int price, String category) {
    setState(() {
      list.add({'name': name, 'price': price, 'qty': 0, 'category': category});
    });
  }

  void _newTransaction() {
    setState(() {
      for (var p in produkBaru) p['qty'] = 0;
      for (var p in produkLama) p['qty'] = 0;
      _paymentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bayar = int.tryParse(_paymentController.text.replaceAll('.', '')) ?? 0;
    final kembalian = bayar >= total ? bayar - total : 0;
    final keyword = _searchController.text.toLowerCase();
    final hasilSearch = semuaProdukAktif.where((item) {
      return item['name'].toLowerCase().contains(keyword)
          || item['price'].toString().contains(keyword)
          || (item['category'] ?? '').toLowerCase().contains(keyword);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir Sederhana'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transaksi'),
            Tab(text: 'Produk Baru'),
            Tab(text: 'Produk Lama'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('Kasir App', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(leading: Icon(Icons.info), title: Text('Tentang Aplikasi')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransaksi(hasilSearch, bayar, kembalian),
          _buildProdukTab('Tambah Produk Baru', produkBaru),
          _buildProdukTab('Tambah Produk Lama', produkLama),
        ],
      ),
    );
  }

  Widget _buildTransaksi(List<Map<String, dynamic>> hasilSearch, int bayar, int kembalian) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(labelText: 'Cari produk...'),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 10),
          Expanded(
            child: hasilSearch.isEmpty
                ? Center(child: Text('Tidak ada produk ditemukan'))
                : ListView.builder(
              itemCount: hasilSearch.length,
              itemBuilder: (context, index) {
                final item = hasilSearch[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('${item['category'] ?? 'Umum'}\n'
                      '${currencyFormatter.format(item['price'])} x ${item['qty']} = Rp ${currencyFormatter.format(item['price'] * item['qty'])}'),
                  isThreeLine: true,
                );
              },
            ),
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: TextStyle(fontSize: 16)),
              Text('Rp ${currencyFormatter.format(total)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          TextField(
            controller: _paymentController,
            decoration: InputDecoration(labelText: 'Uang Pembeli'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kembalian:', style: TextStyle(fontSize: 16)),
              Text(bayar < total ? 'Uang tidak cukup' : 'Rp ${currencyFormatter.format(kembalian)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: bayar < total ? Colors.red : null)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: total > 0 && bayar >= total ? () {} : null, child: Text('Transaksi Selesai'))),
              SizedBox(width: 10),
              Expanded(child: OutlinedButton(onPressed: semuaProdukAktif.isNotEmpty ? _newTransaction : null, child: Text('Transaksi Baru'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProdukTab(String title, List<Map<String, dynamic>> list) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: TextField(controller: nameController, decoration: InputDecoration(labelText: 'Nama'))),
              SizedBox(width: 10),
              Expanded(child: TextField(controller: priceController, decoration: InputDecoration(labelText: 'Harga'), keyboardType: TextInputType.number)),
              SizedBox(width: 10),
              Expanded(child: TextField(controller: categoryController, decoration: InputDecoration(labelText: 'Kategori'))),
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.green),
                onPressed: () {
                  final name = nameController.text.trim();
                  final price = int.tryParse(priceController.text.trim());
                  final category = categoryController.text.trim();
                  if (name.isNotEmpty && price != null) {
                    _addProduct(list, name, price, category);
                    nameController.clear();
                    priceController.clear();
                    categoryController.clear();
                  }
                },
              )
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('Belum ada produk'))
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final qtyController = TextEditingController(text: item['qty'].toString());
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('${item['category'] ?? 'Umum'}\n'
                      '${currencyFormatter.format(item['price'])} x ${item['qty']} = Rp ${currencyFormatter.format(item['price'] * item['qty'])}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit, color: Colors.orange), onPressed: () => _editProduk(list, index)),
                      IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _hapusProduk(list, index)),
                      IconButton(icon: Icon(Icons.remove), onPressed: () => _updateQty(list, index, -1)),
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(4)),
                          onSubmitted: (val) => _updateQty(list, index, val),
                        ),
                      ),
                      IconButton(icon: Icon(Icons.add), onPressed: () => _updateQty(list, index, 1)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
