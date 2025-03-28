import 'package:flutter/material.dart';
import 'pages/home_pages.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: KasirApp(), // <- Halaman utama diambil dari file lain
    );
  }
}
