// lib/core/services/global_error_handler.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalErrorHandler {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  static Future<T?> run<T>({
    required BuildContext context,
    required Future<T> Function() action,
  }) async {
    try {
      return await action();
    } on SocketException {
      showCustomError('Please connect to the internet. Check your network.');
    } on TimeoutException {
      showCustomError('Connection timed out. Please check your internet.');
    } on AuthException catch (e) {
      String message = e.message.toLowerCase();
      final code = e.statusCode ?? '';

      if (message.contains('invalid login credentials') || code == '400') {
        showCustomError('Incorrect email or password. If you don\'t have an account, please Sign Up.');
      } else if (message.contains('email not confirmed')) {
        showCustomError('Please verify your email address before logging in.');
      } else if (message.contains('user already registered')) {
        showCustomError('You are already registered with this email. Please login.');
      } else if (message.contains('password should be at least')) {
        showCustomError('Your password is too short. It must be at least 6 characters.');
      } else if (message.contains('rate limit')) {
        showCustomError('Too many attempts. Please wait a minute and try again.');
      } else if (message.contains('invalid otp') || message.contains('invalid token')) {
        showCustomError('The OTP code is incorrect. Please try again.');
      } else if (message.contains('expired')) {
        showCustomError('The code has expired. Please request a new one.');
      } else {
        showCustomError(e.message);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        showCustomError('This record already exists in our system.');
      } else {
        showCustomError('Database error: ${e.message}');
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('network is unreachable')) {
        showCustomError('Please connect to the internet. Check your network.');
      } else if (errorString.contains('timeout')) {
        showCustomError('Connection timed out. Please check your internet.');
      } else if (errorString.contains('photo_access_denied')) {
        showCustomError('Gallery permission is required to upload images.');
      } else {
        showCustomError('Something went wrong. Please try again later.');
      }
    }
    return null;
  }

  static void showCustomError(String message) {
    if (scaffoldMessengerKey.currentState == null) {
      debugPrint('⚠️ Snackbar failed: scaffoldMessengerKey is null!');
      return;
    }
    scaffoldMessengerKey.currentState!.clearSnackBars();
    scaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showCustomSuccess(String message) {
    if (scaffoldMessengerKey.currentState == null) return;
    scaffoldMessengerKey.currentState!.clearSnackBars();
    scaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static Future<bool> requestCamera(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(context, 'Camera', 'We need camera access to take photos.');
    } else {
      showCustomError('Camera permission is required.');
    }
    return false;
  }

  // ✅ Simplified: Let ImagePicker handle permissions natively
  static Future<bool> requestGallery(BuildContext context) async {
    return true;
  }

  static void showGallerySettingsDialog(BuildContext context) {
    _showSettingsDialog(context, 'Photos', 'We need access to your gallery to upload images.');
  }

  static void _showSettingsDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1d3b27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$title Permission Required', style: const TextStyle(color: Colors.white)),
        content: Text('$message\n\nPlease enable it in app settings.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF49e8c3)),
            child: const Text('Open Settings', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}