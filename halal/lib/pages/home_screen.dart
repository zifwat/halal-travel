//takjadi pakai page ni sbb dh ltak dalam main.dart

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:halal/pages/product_list.dart';
import 'package:halal/pages/home_tab.dart';
import 'package:halal/pages/itinerary_tab.dart';
import 'package:halal/pages/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const ItineraryTab(),
    const ProductList(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Halal Travel App',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Add search functionality
            },
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white,
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
                  log("_currentIndex: $_currentIndex");
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
        onPressed: () {
          // Add functionality for the floating action button
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
