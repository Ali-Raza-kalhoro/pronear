// lib/features/user/business_request_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/loading_button.dart';
import '../provider/auth_provider.dart';

class BusinessRequestScreen extends StatefulWidget {
  final String providerId;

  const BusinessRequestScreen({super.key, required this.providerId});

  @override
  State<BusinessRequestScreen> createState() => _BusinessRequestScreenState();
}

class _BusinessRequestScreenState extends State<BusinessRequestScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _products = [];
  Map<String, int> _cart = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _provider;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _loadData();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  // ============================================================
  // BACKGROUND
  // ============================================================
  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF38804f),
                    Color(0xFF1d3b27),
                    Color(0xFF1d3b27),
                    Color(0xFF38804f),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
            Positioned(
              top: -120,
              right: -100,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final opacity = 0.15 + (0.08 * (1 + math.sin(
                    _pulseController.value * math.pi * 2,
                  )) / 2);
                  return Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -150,
              left: -120,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4D96FF).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(
                  _floatingController.value * math.pi * 2,
                );
                return Positioned(
                  top: 140 + value * 15,
                  right: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.sin(
                  _floatingController.value * math.pi * 2,
                );
                return Positioned(
                  bottom: 50 + value * 15,
                  left: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final value = math.cos(
                  _floatingController.value * math.pi * 2 + 1.5,
                );
                return Positioned(
                  bottom: 120 + value * 12,
                  left: 20,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 80,
              right: 20,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),
            Positioned(
              bottom: 100,
              right: 16,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),
            Positioned(
              bottom: 100,
              left: 16,
              child: _buildDotPattern(
                rows: 4,
                columns: 4,
                spacing: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotPattern({
    required int rows,
    required int columns,
    required double spacing,
  }) {
    return SizedBox(
      width: columns * spacing,
      height: rows * spacing,
      child: Column(
        children: List.generate(
          rows,
              (row) {
            return Row(
              children: List.generate(
                columns,
                    (column) {
                  final isEven = (row + column) % 2 == 0;
                  return Container(
                    width: isEven ? 4 : 2.5,
                    height: isEven ? 4 : 2.5,
                    margin: EdgeInsets.only(
                      right: spacing - 4,
                      bottom: spacing - 4,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(
                        isEven ? 0.35 : 0.055,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // LOGIC METHODS
  // ============================================================

  Future<void> _loadData() async {
    try {
      final provider = await SupabaseService().getProvider(widget.providerId);
      if (provider != null) {
        _provider = provider;
      }

      final products = await Supabase.instance.client
          .from('business_products')
          .select()
          .eq('provider_id', widget.providerId)
          .eq('is_available', true)
          .order('created_at', ascending: false);

      setState(() {
        _products = List<Map<String, dynamic>>.from(products);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final id = product['id'];
      _cart[id] = (_cart[id] ?? 0) + 1;
    });
  }

  void _removeFromCart(Map<String, dynamic> product) {
    setState(() {
      final id = product['id'];
      if (_cart.containsKey(id)) {
        if (_cart[id]! > 1) {
          _cart[id] = _cart[id]! - 1;
        } else {
          _cart.remove(id);
        }
      }
    });
  }

  double _getTotalPrice() {
    double total = 0;
    for (var entry in _cart.entries) {
      final product = _products.firstWhere((p) => p['id'] == entry.key);
      final price = (product['price'] ?? 0).toDouble();
      total += price * entry.value;
    }
    return total;
  }

  Future<void> _submitRequest() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to your order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      String orderDescription = '🛒 Order Details:\n\n';
      for (var entry in _cart.entries) {
        final product = _products.firstWhere((p) => p['id'] == entry.key);
        final quantity = entry.value;
        final price = (product['price'] ?? 0).toDouble();
        orderDescription += '• ${product['name']} x $quantity = ₨ ${(price * quantity).toStringAsFixed(0)}\n';
      }
      orderDescription += '\n📦 Delivery Address: ${_addressController.text.trim()}';
      if (_notesController.text.trim().isNotEmpty) {
        orderDescription += '\n📝 Notes: ${_notesController.text.trim()}';
      }
      orderDescription += '\n\n💰 Total: ₨ ${_getTotalPrice().toStringAsFixed(0)}';

      final Map<String, dynamic> itemsMap = {};
      for (var entry in _cart.entries) {
        final product = _products.firstWhere((p) => p['id'] == entry.key);
        itemsMap[entry.key] = {
          'product_id': entry.key,
          'name': product['name'] ?? '',
          'quantity': entry.value,
          'price': product['price'] ?? 0,
          'total': (product['price'] ?? 0) * entry.value,
        };
      }

      double latitude = 0.0;
      double longitude = 0.0;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (e) {
        debugPrint('⚠️ Could not get location: $e');
      }

      final requestData = {
        'user_id': userId,
        'provider_id': widget.providerId,
        'category_id': _provider?['category_id'],
        'is_business': true,
        'business_category_id': _provider?['category_id'],
        'description': orderDescription,
        'budget': _getTotalPrice(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'delivery_address': _addressController.text.trim(),
        'items': itemsMap,
        'latitude': latitude,
        'longitude': longitude,
      };

      await SupabaseService().createServiceRequest(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Order placed successfully!'),
            backgroundColor: const Color(0xFF49e8c3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalItems = _cart.values.fold(0, (sum, qty) => sum + qty);
    final totalPrice = _getTotalPrice();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _provider?['business_name'] ?? 'Order Products',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Select items to order',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (totalItems > 0)
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white.withOpacity(0.8),
                                size: 22,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  totalItems > 99 ? '99+' : totalItems.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Products List
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF49e8c3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading products...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                      : _products.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.inventory_outlined,
                            size: 50,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No products available',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This business hasn\'t added any products yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final quantity = _cart[product['id']] ?? 0;
                      final images = product['images'] as List?;
                      final imageUrl = images != null && images.isNotEmpty ? images[0] : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.white.withOpacity(0.05),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF49e8c3),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.white.withOpacity(0.05),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              )
                                  : Container(
                                width: 70,
                                height: 70,
                                color: Colors.white.withOpacity(0.05),
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '₨ ${product['price']?.toString() ?? '0'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (product['quantity_options'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Multiple sizes available',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                      color: quantity > 0
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                    onPressed: quantity > 0
                                        ? () => _removeFromCart(product)
                                        : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      quantity.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _addToCart(product),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Checkout Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF49e8c3).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: const Color(0xFF49e8c3),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _addressController,
                          style: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your delivery address',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _notesController,
                          style: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Additional notes (optional)',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Total Items: $totalItems',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  'Total: ₨ ${totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF49e8c3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 48,
                            width: 130,
                            child: LoadingButton(
                              onPressed: totalItems > 0 ? _submitRequest : null,
                              isLoading: _isSubmitting,
                              label: 'Place Order',
                              backgroundColor: totalItems > 0
                                  ? const Color(0xFF49e8c3)
                                  : Colors.grey.shade600,
                              textColor: totalItems > 0 ? Colors.black : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}