// lib/features/provider/auth_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  String? _userRole;
  bool _isCnicVerified = false;
  bool _isFaceVerified = false;
  String? _cnicNumber;

  // Getters
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _user?['id'] ?? Supabase.instance.client.auth.currentUser?.id;
  String? get userRole => _userRole;
  bool get isCnicVerified => _isCnicVerified;
  bool get isFaceVerified => _isFaceVerified;
  String? get cnicNumber => _cnicNumber;
  bool get isProvider => _userRole == 'provider';
  bool get isUser => _userRole == 'user';

  // ============================================================
  // LOGIN
  // ============================================================
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.signIn(email, password);
      if (response.user != null) {
        String? role = response.user!.userMetadata?['role'] as String?;
        print('🔍 Auth - Role from metadata: $role');

        final dbRole = await _service.getUserRole(response.user!.id);
        print('🔍 Auth - Role from DB: $dbRole');

        if (dbRole != null) {
          role = dbRole;
        }

        // Get profile
        _user = await _service.getUserProfile(response.user!.id);
        if (_user != null && role == null) {
          role = _user!['role'] as String?;
        }

        // Final role assignment
        _userRole = role ?? 'user';
        print('✅ Identified final role: $_userRole');

        // Load verification status
        await _loadVerificationStatus();

        // Sync role to user object and database if needed
        if (_user != null) {
          if (_user!['role'] != _userRole) {
            _user!['role'] = _userRole;
            await _service.updateUserProfile(response.user!.id, {
              'role': _userRole,
            });
          }
        } else {
          // If no profile exists, create one
          try {
            await _service.updateUserProfile(response.user!.id, {
              'email': email,
              'role': _userRole,
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            print('⚠️ Auth - Could not create/update profile: $e');
          }
        }

        print('✅ User logged in: ${_user?['full_name'] ?? email}');
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.signUp(email, password, fullName, role);
      if (response.user != null) {
        final userId = response.user!.id;

        // Update profile with additional fields
        final Map<String, dynamic> updateData = {
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (phone != null && phone.isNotEmpty) {
          updateData['phone'] = phone;
        }

        await _service.updateUserProfile(userId, updateData);

        _user = await _service.getUserProfile(userId);
        _userRole = _user?['role'] ?? role;

        // Load verification status
        await _loadVerificationStatus();

        print('✅ User registered: ${_user?['full_name']}');
        print('✅ User role: $_userRole');
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // REGISTER WITH VERIFICATION
  // ============================================================
  Future<bool> registerWithVerification({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String cnicNumber,
    required String cnicFrontImage,
    required String cnicBackImage,
    required String faceImage,
    required String faceEmbedding,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First register the user
      final success = await register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
      );

      if (success && _user != null) {
        final userId = _user!['id'];

        // Save verification data
        await _service.saveUserWithVerification(
          userId: userId,
          cnicNumber: cnicNumber,
          cnicFrontImage: cnicFrontImage,
          cnicBackImage: cnicBackImage,
          faceImage: faceImage,
          faceEmbedding: faceEmbedding,
        );

        // Update local state
        _cnicNumber = cnicNumber;
        _isCnicVerified = true;
        _isFaceVerified = true;

        // Reload user profile to get updated data
        _user = await _service.getUserProfile(userId);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // LOAD VERIFICATION STATUS
  // ============================================================
  Future<void> _loadVerificationStatus() async {
    try {
      final userId = this.userId;
      if (userId == null) return;

      final profile = await _service.getUserProfile(userId);
      if (profile != null) {
        _cnicNumber = profile['cnic'] as String?;
        _isCnicVerified = profile['cnic_verified'] ?? false;
        _isFaceVerified = profile['face_verified'] ?? false;

        print('📋 CNIC: $_cnicNumber');
        print('✅ CNIC Verified: $_isCnicVerified');
        print('✅ Face Verified: $_isFaceVerified');
      }
    } catch (e) {
      print('❌ Error loading verification status: $e');
    }
  }

  // ============================================================
  // UPDATE USER PROFILE
  // ============================================================
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = _service.userId;
    if (userId != null) {
      await _service.updateUserProfile(userId, data);
      _user = await _service.getUserProfile(userId);
      _userRole = _user?['role'] ?? _userRole ?? 'user';
      await _loadVerificationStatus();
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE VERIFICATION STATUS
  // ============================================================
  Future<void> updateVerificationStatus({
    bool? cnicVerified,
    bool? faceVerified,
    String? cnicNumber,
  }) async {
    final userId = _service.userId;
    if (userId == null) return;

    final Map<String, dynamic> updateData = {};
    if (cnicVerified != null) updateData['cnic_verified'] = cnicVerified;
    if (faceVerified != null) updateData['face_verified'] = faceVerified;
    if (cnicNumber != null) updateData['cnic'] = cnicNumber;

    if (updateData.isNotEmpty) {
      updateData['updated_at'] = DateTime.now().toIso8601String();
      await _service.updateUserProfile(userId, updateData);
      _user = await _service.getUserProfile(userId);
      await _loadVerificationStatus();
      notifyListeners();
    }
  }

  // ============================================================
  // CHECK CNIC EXISTS
  // ============================================================
  Future<bool> checkCNICExists(String cnicNumber) async {
    try {
      return await _service.checkCNICExists(cnicNumber);
    } catch (e) {
      print('❌ Error checking CNIC: $e');
      return false;
    }
  }

  // ============================================================
  // UPLOAD VERIFICATION IMAGES
  // ============================================================
  Future<String> uploadVerificationImage(
      String userId,
      String type,
      File imageFile,
      ) async {
    try {
      return await _service.uploadVerificationImage(userId, type, imageFile);
    } catch (e) {
      print('❌ Error uploading verification image: $e');
      rethrow;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    await _service.signOut();
    _user = null;
    _userRole = null;
    _isCnicVerified = false;
    _isFaceVerified = false;
    _cnicNumber = null;
    notifyListeners();
  }

  // ============================================================
  // LOAD USER PROFILE
  // ============================================================
  Future<void> loadUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      // 1. Try metadata first
      final currentUser = Supabase.instance.client.auth.currentUser;
      String? role = currentUser?.userMetadata?['role'] as String?;
      print('🔍 LoadProfile - Role from metadata: $role');

      // 2. Try database
      final dbRole = await _service.getUserRole(userId);
      print('🔍 LoadProfile - Role from DB: $dbRole');
      if (dbRole != null) role = dbRole;

      // 3. Load full profile
      _user = await _service.getUserProfile(userId);
      if (_user != null && role == null) {
        role = _user!['role'] as String?;
      }

      _userRole = role ?? 'user';

      if (_user != null) {
        _user!['role'] = _userRole;
      }

      // 4. Load verification status
      await _loadVerificationStatus();

      print('✅ Profile loaded for: ${_user?['full_name'] ?? currentUser?.email}');
      print('✅ Final user role: $_userRole');
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // GET USER FULL NAME
  // ============================================================
  String getFullName() {
    return _user?['full_name'] ?? 'User';
  }

  // ============================================================
  // IS VERIFIED
  // ============================================================
  bool get isFullyVerified {
    return _isCnicVerified && _isFaceVerified;
  }
}