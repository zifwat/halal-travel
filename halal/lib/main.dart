import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:halal/pages/auth_page.dart';
import 'package:halal/pages/qibla_page.dart';
import 'pages/profile.dart';
import 'pages/itinerary_tab.dart';
import 'pages/product_list.dart';
import 'pages/home_tab.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'pages/scan_result.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MainApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder(
          future: _deviceSupport,
          builder: (_, AsyncSnapshot<bool?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error.toString()}"),
              );
            }
            if (snapshot.data!) {
              return QiblahCompassWidget();
            } else {
              return const Center(
                child: Text("Your device is not supported"),
              );
            }
          },
        ),
      ),
    );
  }
}

class Product {
  final String ingredients;
  final String status;
  final String productName;
  final String? imageUrl;

  Product({
    required this.ingredients,
    required this.status,
    required this.productName,
    this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      ingredients: map['ingredients'] ?? '',
      status: map['status'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.green,
        fontFamily: 'Arial',
      ),
      home: const AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _scanBarcodeResult = '';

  final List<Widget> _tabs = [
    const HomeTab(),
    const ItineraryTab(),
    const ProductList(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        body: _tabs[_currentIndex],
        bottomNavigationBar: BottomAppBar(
          elevation: 8,
          color: Color.fromARGB(255, 255, 255, 255),
          shape: const CircularNotchedRectangle(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.explore),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                ),
                const SizedBox(width: 60),
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 3;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Call the method with parentheses
            await scanBarcodeNormal();
          },
          child: const Icon(Icons.qr_code_scanner),
          backgroundColor: Color.fromARGB(255, 245, 245, 245),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = "Failed to get platform version";
    }

    if (!mounted) return;

    if (barcodeScanRes != "Scan cancelled") {
      final productDetails = await getProductDetails(barcodeScanRes);

      if (productDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultPage(product: productDetails),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan cancelled')),
      );
    }
  }
}

Future<Product?> getProductDetails(String barcode) async {
  try {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(barcode)
            .get();

    if (snapshot.exists) {
      return Product.fromMap(snapshot.data()!);
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching product details: $e');
    return null;
  }
}
