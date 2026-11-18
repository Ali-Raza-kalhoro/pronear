import 'package:flutter/material.dart';

import '../../core/services/supabase_service.dart';

class ProviderProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _businessProviders = [];
  Map<String, dynamic>? _selectedProvider;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get providers => _providers;
  List<Map<String, dynamic>> get businessProviders => _businessProviders;
  Map<String, dynamic>? get selectedProvider => _selectedProvider;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get combined providers (business + individual)
  List<Map<String, dynamic>> get combinedProviders {
    final combined = List<Map<String, dynamic>>.from(_providers);
    // Sort: business providers first
    combined.sort((a, b) {
      final aIsBusiness = a['is_business'] ?? false;
      final bIsBusiness = b['is_business'] ?? false;
      if (aIsBusiness && !bIsBusiness) return -1;
      if (!aIsBusiness && bIsBusiness) return 1;
      return 0;
    });
    return combined;
  }

  /// Set providers list from outside (used for fallback)
  void setProviders(List<Map<String, dynamic>> newProviders) {
    _providers = newProviders;
    // Separate business providers
    _businessProviders = newProviders.where((p) => p['is_business'] ?? false).toList();
    notifyListeners();
  }

  /// Set loading state from outside
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message from outside
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _providers = [];
    _businessProviders = [];
    _selectedProvider = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // In provider_provider.dart

  Future<void> loadNearbyProviders({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    String? categoryId,
    String? searchQuery,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 ProviderProvider: Loading providers...');

      // Try to get providers with location
      var result = await _service.getNearbyProviders(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );

      // If no providers found, try getting all providers
      if (result.isEmpty) {
        debugPrint('⚠️ No providers with location, loading all...');
        result = await _service.getAllProviders();
      }

      _providers = result;
      debugPrint('✅ ProviderProvider: Loaded ${_providers.length} providers');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ ProviderProvider Error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> loadProvider(String providerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProvider = await _service.getProvider(providerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvailability(bool isAvailable) async {
    final providerId = _selectedProvider?['id'];
    if (providerId != null) {
      await _service.updateProviderProfile(providerId, {
        'is_available': isAvailable,
      });
      if (_selectedProvider != null) {
        _selectedProvider!['is_available'] = isAvailable;
        notifyListeners();
      }
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    final providerId = _selectedProvider?['id'];
    if (providerId != null) {
      await _service.updateProviderLocation(providerId, latitude, longitude);
    }
  }

  Future<void> toggleFavorite(String providerId) async {
    final userId = _service.userId;
    if (userId != null) {
      await _service.toggleFavorite(userId, providerId);
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final userId = _service.userId;
    if (userId != null) {
      return await _service.getFavorites(userId);
    }
    return [];
  }
}