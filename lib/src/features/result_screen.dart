// ignore_for_file: prefer_const_constructors, unnecessary_null_comparison, unused_element, library_private_types_in_public_api, sort_child_properties_last, empty_catches, non_constant_identifier_names, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zakatapp/main.dart';

class ResultScreen extends StatefulWidget {
  final String text; // NIK yang dipindai
  final String userId; // ID amil

  const ResultScreen({
    super.key,
    required this.text,
    required this.userId,
  });

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, dynamic>? mustahikData;
  String? distributionPlaceName; // String untuk nama tempat
  String? distribution_deskripsi;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMustahikData();
    _fetchTempatData();
    _fetchDistributiondeskripsi();
  }

  Future<void> _fetchMustahikData() async {
    final client = Supabase.instance.client;
    try {
      final data = await client
          .from('mustahik')
          .select()
          .eq('nik', widget.text)
          .single();

      setState(() {
        mustahikData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        mustahikData = null;
        isLoading = false;
      });
    }
  }

  Future<int?> _fetchDistributionId() async {
    final client = Supabase.instance.client;
    try {
      final response = await client
          .from('distributions')
          .select(
            'id',
          )
          .eq('distribution_code',
              globalSelectedTempat) // globalSelectedTempat digunakan untuk filter
          .single();

      if (response != null) {
        return response['id'];
      }
    } catch (e) {}
    return null;
  }

  Future<void> _fetchDistributiondeskripsi() async {
    final client = Supabase.instance.client;
    try {
      final response = await client
          .from('distributions')
          .select('deskripsi') // Pilih kolom 'deskripsi'
          .eq('distribution_code', globalSelectedTempat)
          .single();

      final data = response;
      if (data != null) {
        setState(() {
          distribution_deskripsi = data['deskripsi'];
        });
      } else {
        setState(() {
          distribution_deskripsi = 'Data tidak ditemukan';
        });
      }
    } catch (e) {
      setState(() {
        distribution_deskripsi = 'Error mengambil data';
      });
    }
  }

  Future<bool> _checkMustahikHistory(int mustahikId, int distributionId) async {
    final client = Supabase.instance.client;
    try {
      final response = await client
          .from('history')
          .select()
          .eq('mustahik_id', mustahikId)
          .eq('distribution_id', distributionId)
          .single();

      return response != null; // True jika data ada, false jika tidak
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchTempatData() async {
    final client = Supabase.instance.client;
    try {
      final data = await client
          .from('distributions')
          .select('distribution_places(name)')
          .eq('distribution_code', globalSelectedTempat)
          .single();
      setState(() {
        if (data != null && data['distribution_places'] != null) {
          distributionPlaceName = data['distribution_places']
              ['name']; // Simpan 'name' dari distribution_places
        } else {
          distributionPlaceName = 'Data tidak ditemukan';
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        distributionPlaceName = 'Error mengambil data';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchdistribusitype() async {
    final client = Supabase.instance.client;
    try {
      final data = await client
          .from('distributions')
          .select('distribution_type(name)')
          .eq('distribution_code', globalSelectedTempat)
          .single();
      setState(() {
        if (data != null && data['distribution_type'] != null) {
          distribution_deskripsi = data['distribution_type']
              ['name']; // Simpan 'name' dari distribution_places
        } else {
          distribution_deskripsi = 'Data tidak ditemukan';
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        distribution_deskripsi = 'Error mengambil data';
        isLoading = false;
      });
    }
  }

  Future<void> _confirmDistribution(int mustahikId, int distributionId) async {
    final client = Supabase.instance.client;

    try {
      // Periksa validitas ID amil
      if (widget.userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ID Amil tidak valid')),
        );
        return;
      }

      // Menulis data ke tabel history
      final now = DateTime.now().toIso8601String();
      final insertResponse = await client.from('history').insert({
        'distribution_id': distributionId,
        'mustahik_id': mustahikId,
        'amil_id': widget.userId, // Gunakan UUID di sini
        'received_at': now,
      });

      if (insertResponse.error != null) {
        throw insertResponse.error!;
      }

      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengambilan zakat berhasil dikonfirmasi')),
      );

      setState(() {
        // Update state agar kotak "Sudah diambil" muncul
        mustahikData!['status_pengambilan'] = 'Sudah diambil';
      });
    } catch (e) {}
  }

  Future<void> _updateDistribution(
      BuildContext context, String type, String mustahikId) async {
    // ... (kode _updateDistribution tetap sama)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan KTP',
          style: TextStyle(
            fontSize: 25,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildInfoCard('Informasi Scan', [
                  _buildInfoRow(
                    'Tempat',
                    distributionPlaceName != null
                        ? distributionPlaceName!
                        : 'Loading...',
                  ),
                  _buildInfoRow(
                    'Deskripsi',
                    distribution_deskripsi != null
                        ? distribution_deskripsi!
                        : 'Loading...',
                  ),
                ]),
                SizedBox(height: 16),
                if (mustahikData != null)
                  _buildInfoCard('Data Mustahik', [
                    _buildInfoRow('NIK', widget.text),
                    _buildInfoRow('Nama',
                        mustahikData!['full_name'] ?? 'Nama tidak tersedia'),
                    _buildInfoRow('Alamat',
                        mustahikData!['address'] ?? 'Alamat tidak tersedia'),
                    _buildInfoRow(
                        'Kategori',
                        mustahikData!['mustahik_type'] ??
                            'Kategori tidak tersedia'),
                    _buildInfoRow(
                        'Status approval',
                        mustahikData!['approval_status'] ??
                            'Status approval tidak tersedia'),
                  ]),
                SizedBox(height: 16),
                if (mustahikData != null &&
                    mustahikData!['supporting_documents'] != null)
                  Image.network(
                    mustahikData!['supporting_documents'],
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Gambar tidak tersedia');
                    },
                  ),
                SizedBox(height: 16),
                // Status Pending
                if (mustahikData != null &&
                    mustahikData!['approval_status'] == 'Pending')
                  _buildWarningCard(
                    title: 'Status Pending',
                    message:
                        'Permohonan mustahik ini masih dalam proses dan belum disetujui.',
                  ),

                // Status Ditolak
                if (mustahikData != null &&
                    mustahikData!['approval_status'] == 'Ditolak')
                  _buildWarningCard(
                    title: 'Status Ditolak',
                    message:
                        'Permohonan mustahik ini telah ditolak oleh sistem.',
                  ),

                if (mustahikData != null &&
                    mustahikData!['approval_status'] == 'Disetujui')
                  FutureBuilder<int?>(
                    future: _fetchDistributionId(), // Mengambil distribution_id
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator(); // Loading
                      }

                      final distributionId = snapshot.data;

                      if (distributionId == null) {
                        return Text('Distribution ID tidak ditemukan');
                      }

                      return FutureBuilder<bool>(
                        future: _checkMustahikHistory(
                            mustahikData!['id'], distributionId),
                        builder: (context, historySnapshot) {
                          if (!historySnapshot.hasData) {
                            return CircularProgressIndicator(); // Loading
                          }

                          final hasTaken = historySnapshot.data ?? false;

                          return Column(
                            children: [
                              _buildInfoCard(
                                'Detail Pengambilan Zakat',
                                [
                                  _buildInfoRow(
                                    'Status',
                                    hasTaken
                                        ? 'Sudah diambil'
                                        : 'Belum diambil',
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              if (!hasTaken && distributionId != null)
                                ElevatedButton(
                                  onPressed: () async {
                                    final quotaPerPerson =
                                        mustahikData!['quota_per_person'] ?? 1;

                                    await _confirmDistribution(
                                        mustahikData!['id'] as int,
                                        distributionId);

                                    // Menampilkan Snackbar konfirmasi
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Pengembalian zakat telah dikonfirmasi')),
                                    );
                                  },
                                  child: Text('Konfirmasi Pengembalian'),
                                ),
                              if (hasTaken)
                                _buildWarningCard(
                                  title: 'Pengambilan Zakat',
                                  message:
                                      'Mustahik ini sudah melakukan pengambilan zakat.',
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                if (mustahikData == null)
                  _buildWarningCard(
                    title: 'NIK Tidak Terdaftar',
                    message:
                        'Mustahik dengan NIK ini tidak terdaftar dalam sistem.',
                  ),
              ],
            ),
    );
  }

  Widget _buildWarningCard({required String title, required String message}) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red,
            size: 40,
          ),
          SizedBox(height: 13),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildUnregisteredUserCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Pengguna Tidak Terdaftar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mustahik dengan NIK ini tidak terdaftar dalam sistem.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
