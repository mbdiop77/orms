import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> initialize() async {
    assert(url.isNotEmpty, 'SUPABASE_URL manquant — lance avec --dart-define-from-file=env/dev.json');
    assert(anonKey.isNotEmpty, 'SUPABASE_ANON_KEY manquant — lance avec --dart-define-from-file=env/dev.json');

    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
    );
  }
}

final supabase = Supabase.instance.client;