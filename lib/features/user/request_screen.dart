// lib/features/user/request_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/loading_button.dart';
import '../provider/auth_provider.dart';

class RequestScreen extends StatefulWidget {
  final String providerId;

  const RequestScreen({super.key, required this.providerId});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with TickerProviderStateMixin {
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _selectedTime;
  String _urgency = 'medium';
  bool _isLoading = false;
  Map<String, dynamic>? _provider;
  Position? _currentPosition;
  List<Map<String, dynamic>> _portfolio = [];
  bool _isLoadingPortfolio = false;

  // Background Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  final List<Map<String, String>> _urgencyOptions = [
    {'value': 'low', 'label': 'Low', 'icon': '🟢', 'color': '#4CAF50'},
    {'value': 'medium', 'label': 'Medium', 'icon': '🟡', 'color': '#FFC107'},
    {'value': 'high', 'label': 'High', 'icon': '🟠', 'color': '#FF9800'},
    {'value': 'emergency', 'label': 'Emergency', 'icon': '🔴', 'color': '#F44336'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProviderAndLocation();
    _loadPortfolio();

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
    _descriptionController.dispose();
    _budgetController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderAndLocation() async {
    try {
      final provider = await SupabaseService().getProvider(widget.providerId);

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        debugPrint('Location error: $e');
      }

      if (mounted) {
        setState(() {
          _provider = provider;
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _loadPortfolio() async {
    setState(() => _isLoadingPortfolio = true);
    try {
      final portfolio = await SupabaseService().getProviderPortfolio(widget.providerId);
      if (mounted) {
        setState(() {
          _portfolio = portfolio;
          _isLoadingPortfolio = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading portfolio: $e');
      if (mounted) {
        setState(() => _isLoadingPortfolio = false);
      }
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF38804f),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      final now = DateTime.now();
      setState(() {
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please describe your issue'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not logged in');
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

      final aiResult = SupabaseService().classifyRequest(_descriptionController.text);

      final requestData = {
        'user_id': userId,
        'provider_id': widget.providerId,
        'category_id': _provider?['category_id'],
        'description': _descriptionController.text,
        'ai_analysis': aiResult,
        'latitude': latitude,
        'longitude': longitude,
        'preferred_time': _selectedTime?.toIso8601String(),
        'budget': double.tryParse(_budgetController.text),
        'urgency': _urgency,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService().createServiceRequest(requestData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Request sent successfully!'),
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
            content: Text('Error: $e'),
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
        setState(() => _isLoading = false);
      }
    }
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
  // BUILD METHODS
  // ============================================================

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // ✅ TRANSPARENT TEXT FIELD (Matches the product setup / registration style)
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF49e8c3),
              size: 22,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showPortfolioDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6C63FF).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.06),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Work Portfolio',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white.withOpacity(0.7),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _portfolio.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No portfolio items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This provider hasn\'t added any work samples yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _portfolio.length,
                      itemBuilder: (context, index) {
                        final item = _portfolio[index];
                        return GestureDetector(
                          onTap: () => _showPortfolioItemDialog(item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                    child: Stack(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: item['media_url'] ?? '',
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          placeholder: (context, url) => Container(
                                            color: Colors.white.withOpacity(0.05),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF49e8c3),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.white.withOpacity(0.05),
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.white.withOpacity(0.2),
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                        if (item['media_type'] == 'video')
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.7),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Video',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    item['title'] ?? 'Untitled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPortfolioItemDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['media_type'] == 'video')
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: item['media_url'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 300,
                      placeholder: (context, url) => Container(
                        color: Colors.white.withOpacity(0.05),
                        height: 300,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF49e8c3),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white.withOpacity(0.05),
                        height: 300,
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white.withOpacity(0.2),
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item['description'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF49e8c3),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSection() {
    if (_portfolio.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF49e8c3).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF49e8c3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Work Portfolio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _showPortfolioDialog,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF49e8c3),
              ),
              child: Text(
                'View All (${_portfolio.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _portfolio.length > 5 ? 5 : _portfolio.length,
            itemBuilder: (context, index) {
              final item = _portfolio[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => _showPortfolioItemDialog(item),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: item['media_url'] ?? '',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.white.withOpacity(0.05),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF49e8c3),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.white.withOpacity(0.05),
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ),
                          if (item['media_type'] == 'video')
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_provider == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0A2A),
        body: Stack(
          children: [
            _buildBackground(size),
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF49e8c3),
              ),
            ),
          ],
        ),
      );
    }

    final user = _provider!['users'] ?? {};
    final isAvailable = _provider!['is_available'] ?? false;
    final isOnline = user['is_online'] ?? false;
    final rating = _provider!['rating'] ?? 0.0;
    final totalReviews = _provider!['total_reviews'] ?? 0;

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
                      const Expanded(
                        child: Text(
                          'Request Service',
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
                          isAvailable && isOnline ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isAvailable && isOnline ? Colors.black : Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Provider Info Card
                        _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF49e8c3).withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF49e8c3).withOpacity(0.2),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundImage: user['profile_image'] != null && user['profile_image'].toString().isNotEmpty
                                        ? NetworkImage(user['profile_image'])
                                        : null,
                                    child: (user['profile_image'] == null || user['profile_image'].toString().isEmpty)
                                        ? Icon(
                                      Icons.person_rounded,
                                      size: 28,
                                      color: Colors.white.withOpacity(0.6),
                                    )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['full_name'] ?? 'Provider',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _provider!['profession'] ?? 'Service Provider',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '($totalReviews reviews)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withOpacity(0.4),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_provider!['experience'] != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF49e8c3).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.work_outline,
                                                    size: 12,
                                                    color: Color(0xFF49e8c3),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_provider!['experience']}yrs',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF49e8c3),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
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
                        ),

                        // Portfolio
                        if (_isLoadingPortfolio)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF49e8c3),
                                ),
                              ),
                            ),
                          )
                        else
                          _buildPortfolioSection(),

                        const SizedBox(height: 24),

                        // Description
                        _buildInputField(
                          controller: _descriptionController,
                          label: 'Describe Your Issue',
                          hint: 'Describe what service you need...',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),

                        // Budget
                        _buildInputField(
                          controller: _budgetController,
                          label: 'Budget (Optional)',
                          hint: 'Enter your budget in PKR',
                          icon: Icons.currency_rupee_rounded,
                          isNumber: true,
                        ),
                        const SizedBox(height: 16),

                        // Preferred Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferred Time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF49e8c3).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.access_time_rounded,
                                        color: Color(0xFF49e8c3),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedTime != null
                                            ? DateFormat('hh:mm a').format(_selectedTime!)
                                            : 'Select preferred time',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: _selectedTime != null
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white.withOpacity(0.4),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Urgency
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urgency Level',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var option in _urgencyOptions)
                                  FilterChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          option['icon']!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          option['label']!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _urgency == option['value']
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    selected: _urgency == option['value'],
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _urgency = option['value']!);
                                      }
                                    },
                                    selectedColor: Color(
                                      int.parse(option['color']!.replaceAll('#', '0xFF')),
                                    ),
                                    backgroundColor: Colors.white.withOpacity(0.06),
                                    side: BorderSide(
                                      color: _urgency == option['value']
                                          ? Color(int.parse(option['color']!.replaceAll('#', '0xFF')))
                                          : Colors.white.withOpacity(0.1),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: LoadingButton(
                            onPressed: _submitRequest,
                            isLoading: _isLoading,
                            label: 'Send Request',
                            backgroundColor: const Color(0xFF49e8c3),
                            textColor: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
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