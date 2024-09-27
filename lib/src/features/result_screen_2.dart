// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ResultScreen2 extends StatefulWidget {
  final String text; // NIK yang diteruskan dari RegKtp

  const ResultScreen2({super.key, required this.text});

  @override
  State<ResultScreen2> createState() => _ResultScreen2State();
}

class _ResultScreen2State extends State<ResultScreen2> {
  bool isLoading = true;
  dynamic mustahikData;
  final _nikController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _salaryRangeController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String? _selectedCategory;
  File? _image; // To store the picked image

  @override
  void initState() {
    super.initState();
    _nikController.text = widget.text;
    _fetchMustahikData();
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status == PermissionStatus.granted;
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

  Future<void> _pickImage() async {
    final storageStatus = await _requestStoragePermission();
    if (!storageStatus) {
      // Permission denied. Inform user and retry on request.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Storage permission is required to upload images. Please grant permission and try again.')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    final client = Supabase.instance.client;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_image';
    try {
      await client.storage.from('test_storage').upload(
            fileName,
            image,
          );

      // If upload was successful, get the public URL
      final publicUrl =
          client.storage.from('test_storage').getPublicUrl(fileName);
      return publicUrl;
    } catch (error) {
      // Handle the error

      return null;
    }
  }

  Future<void> _submitForm() async {
    final nik = int.tryParse(_nikController.text.trim());
    final fullname = _fullnameController.text.trim();
    final occupation = _occupationController.text.trim();
    final salaryRange = double.tryParse(_salaryRangeController.text.trim());
    final phoneNumber = _phoneNumberController.text.trim();

    if (nik == null ||
        fullname.isEmpty ||
        occupation.isEmpty ||
        salaryRange == null ||
        _selectedCategory == null ||
        phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field.')),
      );
      return;
    }

    final client = Supabase.instance.client;

    try {
      // Upload image if selected
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      // Insert data into 'mustahik' table
      await client.from('mustahik').insert({
        'nik': nik,
        'full_name': fullname,
        'occupation': occupation,
        'income_range': salaryRange,
        'mustahik_type': _selectedCategory,
        'phone_number': phoneNumber,
        'supporting_documents': imageUrl, // Store the image URL if needed
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrasi KTP',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : mustahikData != null
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'NIK terdaftar pada database.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 103, 65, 63)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromARGB(255, 163, 134, 132),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning,
                                color: const Color.fromARGB(255, 50, 46, 45),
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Mustahik dengan NIK ini tidak terdaftar dalam sistem.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 145, 130, 130),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nikController,
                          decoration: const InputDecoration(
                            labelText: 'NIK',
                            border: OutlineInputBorder(),
                          ),
                          enabled: false,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _fullnameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama lengkap',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _occupationController,
                          decoration: const InputDecoration(
                            labelText: 'Pekerjaan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _salaryRangeController,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Pendapatan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          hint: const Text('Kategori mustahik'),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                          items: <String>[
                            'Fakir',
                            'Miskin',
                            'Amil',
                            'Mualaf',
                            'Riqab',
                            'Gharim',
                            'Ibnu Sabil',
                            'Fisabilillah',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'No. HP',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Pilih Gambar'),
                        ),
                        if (_image != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Image.file(
                              _image!,
                              height: 200,
                            ),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
