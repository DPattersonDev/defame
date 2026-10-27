import 'package:supabase_flutter/supabase_flutter.dart';

import 'demo.dart';

/// The server returns public projections; anonymous author IDs never reach UI.
class DeFameApi {
  static String? get userId =>
      DemoStore.active.value ? DemoStore.userId : client.auth.currentUser?.id;
  static Future<void> signOut() async {
    if (DemoStore.active.value) {
      DemoStore.active.value = false;
    } else {
      await client.auth.signOut();
    }
  }

  static final client = Supabase.instance.client;

  static Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    if (DemoStore.active.value) return DemoStore.call(action, values);
    try {
      final response = await client.functions.invoke(
        'defame-api',
        body: {'action': action, ...values},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['error'] != null) throw Exception(data['error']);
      return data;
    } on FunctionException catch (error) {
      final details = error.details;
      throw Exception(
        details is Map
            ? details['error'] ?? 'The request could not be completed.'
            : 'Service unavailable. Please try again.',
      );
    }
  }

  static String message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
