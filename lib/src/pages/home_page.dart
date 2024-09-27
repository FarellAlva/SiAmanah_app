// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, library_private_types_in_public_api, prefer_const_constructors_in_immutables, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unnecessary_null_comparison, prefer_if_null_operators

import 'package:flutter/material.dart';
import 'package:zakatapp/main.dart';
import 'package:zakatapp/src/core/services/supabase_distribusi.dart';
import 'package:zakatapp/src/core/services/supabase_service.dart';
import 'package:zakatapp/src/pages/login_page.dart';
import 'package:zakatapp/src/core/services/supabase_user_amil.dart';

class HomePage extends StatefulWidget {
  final String userId;

  HomePage({super.key, required this.userId});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String userName = "Amil";
  String fullname = 'Amil';
  bool isLoading = true;
  bool canContinue = false;

  List<String> distributions_place = [];
  String? selectedTempat;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchTempatDistribusi();
  }

  Future<void> _fetchUserData() async {
    try {
      final userAmilData =
          await UserAmilService().getUserAmilData(widget.userId);

      if (userAmilData != null) {
        setState(() {
          userName = userAmilData['username'];
          fullname = userAmilData['full_name'];
          isLoading = false;
        });

        if (!canContinue) {
          // _logoutAndRedirect();
        }
      } else {
        // _logoutAndRedirect();
      }
    } catch (e) {
      // _logoutAndRedirect();
    }
  }

  Future<void> _fetchTempatDistribusi() async {
    try {
      final tempatData =
          await SupabaseDistribusiService().getTempatDistribusi();
      setState(() {
        distributions_place = tempatData;
      });
    } catch (e) {
      setState(() {
        distributions_place = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset('lib/src/img/siamanah-web-logo.png',
              height: 145, width: 140),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.logout_outlined,
                color: const Color.fromARGB(255, 44, 137, 33)),
            label: Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 44, 137, 33),
              ),
            ),
            onPressed: () {
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assalamu’alaikum, $userName!',
                          style: TextStyle(
                            fontSize: 23,
                            color: Colors.white,
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Selamat datang $fullname',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white70,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.0),
                  _buildFilterBox(),
                  SizedBox(height: 20.0),
                  _buildSpotlightWidget(),
                  SizedBox(height: 20.0),
                ],
              ),
            ),
    );
  }

  Widget _buildSpotlightWidget() {
    final List<Map<String, String>> spotlightItems = [
      {
        'title': 'Indo bersama palestine',
        'image': 'lib/src/img/berita2images.png',
      },
      {
        'title': 'beasiswa 2024',
        'image': 'lib/src/img/berita1images.png',
      },
      {
        'title': 'Bantuan sembako',
        'image': 'lib/src/img/berita3.png',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.0),
        Text(
          'Spotlight BAZNAS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        SizedBox(height: 10.0),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: spotlightItems.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: EdgeInsets.only(right: 10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: AssetImage(spotlightItems[index]['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Text(
                    spotlightItems[index]['title']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBox() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            globalSelectedTempat == null
                ? 'Pilih Kode Distribusi'
                : 'Kode Distribusi: $globalSelectedTempat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 10.0),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: selectedTempat,
                  hint: Text(
                    globalSelectedTempat == null
                        ? 'Pilih Kode Tempat'
                        : globalSelectedTempat,
                  ),
                  isExpanded: true,
                  items: distributions_place.isNotEmpty
                      ? distributions_place.map((tempat) {
                          return DropdownMenuItem<String>(
                            value: tempat,
                            child: Text(tempat),
                          );
                        }).toList()
                      : [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Pencarian tidak ada'),
                          ),
                        ],
                  onChanged: (value) {
                    setState(() {
                      selectedTempat = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 10.0),
              ElevatedButton(
                onPressed: () {
                  if (selectedTempat != null) {
                    globalSelectedTempat = selectedTempat ?? '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kode Distribusi'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // Jika tidak ada tempat yang dipilih
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pilih Kode Distribusi terlebih dahulu!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(255, 52, 141, 56), // Warna hijau
                ),
                child: Text(
                  'Konfirmasi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Kembalikan false jika tidak logout
              },
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Kembalikan true jika logout
              },
              child: Text('Iya'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _logout(context);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await SupabaseService().signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout gagal')),
        );
      }
    }
  }
}
