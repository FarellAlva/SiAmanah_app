// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:zakatapp/main.dart';
import 'package:zakatapp/src/pages/scanner_ktp.dart';
import 'package:zakatapp/src/pages/home_page.dart';

import 'package:zakatapp/src/pages/reg_ktp.dart';

class Navbar extends StatefulWidget {
  final String userId;
  // Tambahkan properti ini

  const Navbar({
    super.key,
    required this.userId,
    // Pastikan ini disertakan
  });

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Gunakan userId dan selectedTempat dari widget untuk membuat halaman
    _pages = [
      HomePage(userId: widget.userId),
      ScannerKtp(
        selectedTempat: globalSelectedTempat,
      ),
      RegKtp(
        selectedTempat: globalSelectedTempat,
      ),
    ];
  }

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Scan KTP';
      case 2:
        return 'Register';
      case 3:
        return 'Settings'; // Pastikan ini sesuai dengan halaman yang benar
      default:
        return 'App';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isHomePage = _selectedIndex == 0;

    return Scaffold(
      appBar: isHomePage
          ? null
          : AppBar(
              backgroundColor: Colors.green,
              title: Text(
                _getTitle(_selectedIndex),
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontFamily: 'Amiri',
                ),
              ),
              centerTitle: true,
            ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        items: [
          BottomNavigationBarItem(
            icon: _buildIconWithIndicator(Icons.home, Icons.home_outlined, 0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildIconWithIndicator(Icons.center_focus_strong,
                Icons.center_focus_strong_outlined, 1),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: _buildIconWithIndicator(
                Icons.person_pin_sharp, Icons.person_pin_outlined, 2),
            label: 'Register',
          ),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }

  Widget _buildIconWithIndicator(
      IconData selectedIcon, IconData unselectedIcon, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _selectedIndex == index ? Colors.green : Colors.transparent,
            width: 0.8,
          ),
        ),
      ),
      child: Icon(
        _selectedIndex == index ? selectedIcon : unselectedIcon,
        color: _selectedIndex == index ? Colors.green : Colors.black,
      ),
    );
  }
}
