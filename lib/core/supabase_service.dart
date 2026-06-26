import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppStrings.supabaseUrl,
      anonKey: AppStrings.supabaseAnonKey,
    );
  }

  static User? get currentUser => supabase.auth.currentUser;
  static String? get currentUserId => supabase.auth.currentUser?.id;
  static Session? get currentSession => supabase.auth.currentSession;

  static Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  static bool get isPremium {
    final email = currentUser?.email?.toLowerCase().trim();
    return email == AppStrings.premiumEmail.toLowerCase();
  }

  static bool requirePremium(BuildContext context) {
    if (isPremium) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Somente usuários Premium podem realizar esta ação.')),
          ],
        ),
        backgroundColor: AppColors.greyDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return false;
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password, String name) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    return response;
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      await supabase.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      return supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteFile(String bucket, String path) async {
    await supabase.storage.from(bucket).remove([path]);
  }
}
