import 'package:supabase_flutter/supabase_flutter.dart';

class ApiConfig {
  static const String cloudinaryApiKey = '174196584956159';
  static const String cloudinaryApiSecret = 'xUJqaRlxBUIM_NsSlOmxo0rVo4E';
  static const String cloudinaryCloudName = 'c-762ef34dd8ad4ea764d4c3c6846e9f';

  static const String supabaseUrl = 'https://xzwbzhjdzxmwzepyuhn.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6d25iemhqZHp4bXd6ZXB5dWhuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODU0NjcxOSwiZXhwIjoyMDY0MTIyNzE5fQ.Qau8BFgwZ6cW5ktwgVWqVE0cskUr-jvz42DPc3_VKrg';

  static final SupabaseClient supabase = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
  );
}
