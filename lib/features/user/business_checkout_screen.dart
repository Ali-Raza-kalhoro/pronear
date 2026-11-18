// lib/features/user/business_checkout_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/loading_button.dart';
import '../provider/auth_provider.dart';

class BusinessCheckoutScreen extends StatefulWidget {
  final String providerId;

  const BusinessCheckoutScreen({super.key, required this.providerId});

  @override
  State<BusinessCheckoutScreen> createState() => _BusinessCheckoutScreenState();
}

class _BusinessCheckoutScreenState extends State<BusinessCheckoutScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _products = [];
  Map<String, int> _cart = {};
  double _total = 0;
  Map<String, dynamic>? _provider;
  bool _isSubmitting = false;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _deliveryTime = 'As soon as possible';
  final List<String> _deliveryTimes = [
    'As soon as possible',
    'Within 1 hour',
    'Within 2 hours',
    'Within 4 hours',
    'Tomorrow morning',
    'Tomorrow afternoon',
  ];

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _loadDataFromArguments();

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

  void _loadDataFromArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _products = args['products'] ?? [];
      _cart = args['cart'] ?? {};
      _total = args['total'] ?? 0;
      _provider = args['provider'];
    }
  }

  Future<void> _placeOrder() async {
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
      orderDescription += '\n⏰ Delivery Time: $_deliveryTime';
      if (_notesController.text.trim().isNotEmpty) {
        orderDescription += '\n📝 Notes: ${_notesController.text.trim()}';
      }
      orderDescription += '\n\n💰 Total: ₨ ${_total.toStringAsFixed(0)}';

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
        'budget': _total,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'delivery_address': _addressController.text.trim(),
        'delivery_time': _deliveryTime,
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
    final itemCount = _cart.values.fold(0, (sum, qty) => sum + qty);

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
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${itemCount} items',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B6B).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: Color(0xFFFF6B6B),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._cart.entries.map((entry) {
                                final product = _products.firstWhere((p) => p['id'] == entry.key);
                                final price = (product['price'] ?? 0).toDouble();
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${product['name']} x ${entry.value}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₨ ${(price * entry.value).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF49e8c3),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              Divider(
                                color: Colors.white.withOpacity(0.06),
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total (${itemCount} items)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF49e8c3), Color(0xFF31b999)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '₨ ${_total.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Delivery Details
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4D96FF).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.delivery_dining_rounded,
                                      color: Color(0xFF4D96FF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Delivery Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Address
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
                                    labelText: 'Delivery Address *',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    hintText: 'Enter your full delivery address',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                      color: const Color(0xFF49e8c3),
                                      size: 20,
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Delivery Time Dropdown
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _deliveryTime,
                                  decoration: InputDecoration(
                                    labelText: 'Preferred Delivery Time',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.access_time_rounded,
                                      color: const Color(0xFF49e8c3),
                                      size: 20,
                                    ),
                                  ),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontSize: 14,
                                  ),
                                  items: _deliveryTimes.map((time) {
                                    return DropdownMenuItem(
                                      value: time,
                                      child: Text(time),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _deliveryTime = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Notes
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
                                    labelText: 'Additional Notes',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    hintText: 'Any special instructions for delivery',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.note_outlined,
                                      color: const Color(0xFF49e8c3),
                                      size: 20,
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Place Order Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: LoadingButton(
                            onPressed: _placeOrder,
                            isLoading: _isSubmitting,
                            label: 'Place Order - ₨ ${_total.toStringAsFixed(0)}',
                            backgroundColor: const Color(0xFF49e8c3),
                            textColor: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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