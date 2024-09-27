import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Fungsi untuk logout
  Future<void> signOut() async {
    // ignore: unused_local_variable
    final response = await Supabase.instance.client.auth.signOut();
  }
}
