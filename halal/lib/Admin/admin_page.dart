import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:halal/Admin/landmark_manage.dart';
import 'package:halal/Admin/user_management.dart';
import 'package:halal/Admin/product_manage.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    Dashboard(),
    UserManagementPage(),
    ProductManage(),
    LandmarkManage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              } catch (e) {
                print('Error during logout: $e');
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Landmarks',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            icon: Icons.person,
            color: Colors.green,
            title: 'User Count',
            value: fetchUserCount(),
          ),
          const SizedBox(height: 10.0),
          _buildCard(
            icon: Icons.verified_user,
            color: Colors.orange,
            title: 'Product Count',
            value: fetchProductCount(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required IconData icon,
      required Color color,
      required String title,
      required Future<int> value}) {
    return FutureBuilder<int>(
      future: value,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}',
              style: TextStyle(color: Colors.white));
        } else {
          int count = snapshot.data ?? 0;
          return Card(
            color: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 32.0,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<int> fetchUserCount() async {
    QuerySnapshot<Map<String, dynamic>> userSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    return userSnapshot.size;
  }

  Future<int> fetchProductCount() async {
    QuerySnapshot<Map<String, dynamic>> productSnapshot =
        await FirebaseFirestore.instance.collection('products').get();
    return productSnapshot.size;
  }
}

void main() {
  runApp(
    MaterialApp(
      home: AdminPage(),
    ),
  );
}
