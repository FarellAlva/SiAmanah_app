// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Tambahkan import ini
import 'package:zakatapp/src/features/result_screen.dart';

class ScannerKtp extends StatefulWidget {
  final String selectedTempat;

  const ScannerKtp({super.key, required this.selectedTempat});

  @override
  State<ScannerKtp> createState() => _ScannerKtpState();
}

class _ScannerKtpState extends State<ScannerKtp> with WidgetsBindingObserver {
  bool _isPermissionGranted = false;
  late final Future<void> _future;
  CameraController? _cameraController;
  final textRecognizer = TextRecognizer();
  String? userId; // Tambahkan variabel ini untuk menyimpan UUID pengguna

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _future = _requestCameraPermission();
    _getUserId(); // Ambil UUID pengguna saat inisialisasi
  }

  Future<void> _getUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      userId = user?.id;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      _startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        return Stack(
          children: [
            if (_isPermissionGranted)
              FutureBuilder<List<CameraDescription>>(
                future: availableCameras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _initCameraController(snapshot.data!);

                    return Center(
                      child: Stack(
                        children: [
                          if (_cameraController != null)
                            CameraPreview(_cameraController!),
                          _buildOverlay(),
                        ],
                      ),
                    );
                  } else {
                    return const LinearProgressIndicator();
                  }
                },
              ),
            Scaffold(
              backgroundColor:
                  _isPermissionGranted ? Color.fromARGB(0, 193, 22, 22) : null,
              body: _isPermissionGranted
                  ? Stack(
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              if (_cameraController != null)
                                CameraPreview(_cameraController!),
                              _buildOverlay(),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height *
                              0.15, // 10% dari tinggi layar dari bawah
                          left: MediaQuery.of(context).size.width * 0.5 -
                              75, // Pusatkan tombol secara horizontal
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ElevatedButton(
                              onPressed: _scanImage,
                              child: const Text(
                                'Scan KTP',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                        child: const Text(
                          'Loading camera',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _isPermissionGranted = status == PermissionStatus.granted;
      });
    }
  }

  void _startCamera() {
    if (mounted && _cameraController != null) {
      _cameraSelected(_cameraController!.description);
    }
  }

  void _stopCamera() {
    if (mounted && _cameraController != null) {
      _cameraController?.dispose();
      _cameraController = null;
    }
  }

  void _initCameraController(List<CameraDescription> cameras) {
    if (_cameraController != null) {
      return;
    }

    // Select the first rear camera.
    CameraDescription? camera;
    for (var i = 0; i < cameras.length; i++) {
      final CameraDescription current = cameras[i];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }

    if (camera != null) {
      _cameraSelected(camera);
    }
  }

  Future<void> _cameraSelected(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(FlashMode.off);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _scanImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera controller is not initialized'),
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);

    try {
      final pictureFile = await _cameraController!.takePicture();
      final file = File(pictureFile.path);

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final extractedNik = _extractNik(recognizedText.text);

      if (!mounted) return;

      if (extractedNik == 'NIK not found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NIK tidak ditemukan'),
          ),
        );
      } else if (extractedNik.length != 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NIK tidak tepat'),
          ),
        );
      } else {
        await navigator.push(
          MaterialPageRoute(
            builder: (BuildContext context) => ResultScreen(
              text: extractedNik,
              userId: userId ?? 'unknown', // Kirimkan UUID pengguna
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Terjadi kesalahan saat memproses gambar: ${e.toString()}'),
          ),
        );
      }
    }
  }

  String _extractNik(String text) {
    final nikIndex = text.indexOf('NIK');
    final colonIndex = text.indexOf(':', nikIndex);

    if (nikIndex == -1 || colonIndex == -1) {
      return 'NIK not found';
    }

    final start = colonIndex + 1;
    final nikText = text.substring(start).trim();

    final nikMatch = RegExp(r'\d+').firstMatch(nikText);
    return nikMatch?.group(0) ?? 'NIK not found';
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Background Overlay with some transparency
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          // Overlay Box
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: MediaQuery.sizeOf(context).height * 0.8,
                  height: MediaQuery.sizeOf(context).height * 0.29,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
