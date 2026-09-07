import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';

class RequestProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> _requests = [];
  Map<String, dynamic>? _selectedRequest;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get requests => _requests;
  Map<String, dynamic>? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserRequests(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _requests = await _service.getUserRequests(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProviderRequests(String providerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _requests = await _service.getProviderRequests(providerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createRequest(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = await _service.createServiceRequest(data);
      _isLoading = false;
      notifyListeners();
      return request;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateRequest(String requestId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateServiceRequest(requestId, data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    return await updateRequest(requestId, {
      'status': 'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> rejectRequest(String requestId) async {
    return await updateRequest(requestId, {
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> completeRequest(String requestId) async {
    return await updateRequest(requestId, {
      'status': 'completed',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  void selectRequest(Map<String, dynamic> request) {
    _selectedRequest = request;
    notifyListeners();
  }
}