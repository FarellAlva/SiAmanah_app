// ignore_for_file: unnecessary_null_comparison

import 'package:supabase_flutter/supabase_flutter.dart';

class UserAmilService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fungsi untuk membaca data user_amil berdasarkan UUID dari autentikasi
  Future<Map<String, dynamic>?> getUserAmilData(String uuid) async {
    try {
      final response =
          await _client.from('user_amil').select().eq('id', uuid).single();

      if (response != null && response.isNotEmpty) {
        return response;
      } else {
        return null;
      }
    } catch (error) {
      return null;
    }
  }
}
