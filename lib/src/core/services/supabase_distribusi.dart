import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDistribusiService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<List<String>> getTempatDistribusi() async {
    try {
      // Mengambil data dari Supabase
      final response = await _supabaseClient
          .from('distributions')
          .select('distribution_code');

      // Mengonversi data menjadi daftar string
      final List<String> tempatDistribusi = (response as List<dynamic>)
          .map((item) => item['distribution_code'] as String)
          .toList();

      return tempatDistribusi;
    } catch (e) {
      return [];
    }
  }
}
