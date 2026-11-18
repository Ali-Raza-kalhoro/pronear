// lib/features/provider/cv_creation_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Added for PlatformException
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/global_error_handler.dart';
import 'auth_provider.dart';

class CVCreationScreen extends StatefulWidget {
  const CVCreationScreen({super.key});

  @override
  State<CVCreationScreen> createState() => _CVCreationScreenState();
}

class _CVCreationScreenState extends State<CVCreationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Background Animations
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  // Services List
  final List<Map<String, dynamic>> _allServices = [
    {'name': 'Electrician', 'icon': '⚡', 'category': 'Home & Property'},
    {'name': 'Plumber', 'icon': '🔧', 'category': 'Home & Property'},
    {'name': 'Carpenter', 'icon': '🪚', 'category': 'Home & Property'},
    {'name': 'Mason', 'icon': '🧱', 'category': 'Home & Property'},
    {'name': 'Painter', 'icon': '🎨', 'category': 'Home & Property'},
    {'name': 'Tile Worker', 'icon': '🔲', 'category': 'Home & Property'},
    {'name': 'Gypsum/Ceiling', 'icon': '🏗️', 'category': 'Home & Property'},
    {'name': 'Interior Designer', 'icon': '🛋️', 'category': 'Home & Property'},
    {'name': 'Furniture Assembly', 'icon': '🪑', 'category': 'Home & Property'},
    {'name': 'Handyman', 'icon': '🔨', 'category': 'Home & Property'},
    {'name': 'Locksmith', 'icon': '🔐', 'category': 'Home & Property'},
    {'name': 'Pest Control', 'icon': '🐜', 'category': 'Home & Property'},
    {'name': 'House Cleaner', 'icon': '🧹', 'category': 'Home & Property'},
    {'name': 'Deep Cleaning', 'icon': '🧼', 'category': 'Home & Property'},
    {'name': 'Water Tank Cleaning', 'icon': '💧', 'category': 'Home & Property'},
    {'name': 'Gardener', 'icon': '🌱', 'category': 'Home & Property'},
    {'name': 'Landscaping', 'icon': '🌿', 'category': 'Home & Property'},
    {'name': 'Pool Maintenance', 'icon': '🏊', 'category': 'Home & Property'},
    {'name': 'Car Mechanic', 'icon': '🚗', 'category': 'Automotive'},
    {'name': 'Bike Mechanic', 'icon': '🏍️', 'category': 'Automotive'},
    {'name': 'EV Technician', 'icon': '🔋', 'category': 'Automotive'},
    {'name': 'Battery Replacement', 'icon': '🔌', 'category': 'Automotive'},
    {'name': 'Tire/Puncture', 'icon': '🛞', 'category': 'Automotive'},
    {'name': 'Oil Change', 'icon': '🛢️', 'category': 'Automotive'},
    {'name': 'Car Wash/Detailing', 'icon': '🧽', 'category': 'Automotive'},
    {'name': 'AC Repair', 'icon': '❄️', 'category': 'Automotive'},
    {'name': 'Auto Electrician', 'icon': '🔌', 'category': 'Automotive'},
    {'name': 'Towing', 'icon': '🚚', 'category': 'Automotive'},
    {'name': 'Roadside Assistance', 'icon': '🛣️', 'category': 'Automotive'},
    {'name': 'Vehicle Inspection', 'icon': '🔍', 'category': 'Automotive'},
    {'name': 'Mobile Mechanic', 'icon': '🔧', 'category': 'Automotive'},
    {'name': 'Solar Installation', 'icon': '☀️', 'category': 'Energy & Utilities'},
    {'name': 'Solar Maintenance', 'icon': '🔆', 'category': 'Energy & Utilities'},
    {'name': 'Inverter Technician', 'icon': '⚡', 'category': 'Energy & Utilities'},
    {'name': 'Battery Technician', 'icon': '🔋', 'category': 'Energy & Utilities'},
    {'name': 'Generator Technician', 'icon': '🔄', 'category': 'Energy & Utilities'},
    {'name': 'Electrical Inspection', 'icon': '🔦', 'category': 'Energy & Utilities'},
    {'name': 'Energy Audit', 'icon': '📊', 'category': 'Energy & Utilities'},
    {'name': 'UPS Technician', 'icon': '⚡', 'category': 'Energy & Utilities'},
    {'name': 'Smart Meter Installation', 'icon': '📱', 'category': 'Energy & Utilities'},
    {'name': 'EV Charging Installation', 'icon': '🔌', 'category': 'Energy & Utilities'},
    {'name': 'Mobile Repair', 'icon': '📱', 'category': 'Technology'},
    {'name': 'Laptop Repair', 'icon': '💻', 'category': 'Technology'},
    {'name': 'Computer Repair', 'icon': '🖥️', 'category': 'Technology'},
    {'name': 'Software Installation', 'icon': '💿', 'category': 'Technology'},
    {'name': 'Wi-Fi/Networking', 'icon': '🌐', 'category': 'Technology'},
    {'name': 'CCTV Installation', 'icon': '📹', 'category': 'Technology'},
    {'name': 'Printer Repair', 'icon': '🖨️', 'category': 'Technology'},
    {'name': 'Data Recovery', 'icon': '💾', 'category': 'Technology'},
    {'name': 'Website Development', 'icon': '🌐', 'category': 'Technology'},
    {'name': 'IT Support', 'icon': '🖥️', 'category': 'Technology'},
    {'name': 'Smart Home Installation', 'icon': '🏠', 'category': 'Technology'},
    {'name': 'Cybersecurity Services', 'icon': '🔒', 'category': 'Technology'},
    {'name': 'Office Cleaning', 'icon': '🧹', 'category': 'Business & Office'},
    {'name': 'IT Support', 'icon': '💻', 'category': 'Business & Office'},
    {'name': 'HVAC Maintenance', 'icon': '❄️', 'category': 'Business & Office'},
    {'name': 'Electrical Maintenance', 'icon': '⚡', 'category': 'Business & Office'},
    {'name': 'Security Systems', 'icon': '🔐', 'category': 'Business & Office'},
    {'name': 'Office Moving', 'icon': '📦', 'category': 'Business & Office'},
    {'name': 'Furniture Installation', 'icon': '🪑', 'category': 'Business & Office'},
    {'name': 'Facility Management', 'icon': '🏢', 'category': 'Business & Office'},
    {'name': 'Equipment Maintenance', 'icon': '⚙️', 'category': 'Business & Office'},
    {'name': 'Event Support', 'icon': '🎪', 'category': 'Business & Office'},
    {'name': 'Local Delivery', 'icon': '📦', 'category': 'Delivery & Logistics'},
    {'name': 'Furniture Transport', 'icon': '🛋️', 'category': 'Delivery & Logistics'},
    {'name': 'Moving Services', 'icon': '🚚', 'category': 'Delivery & Logistics'},
    {'name': 'Courier', 'icon': '📨', 'category': 'Delivery & Logistics'},
    {'name': 'Pickup/Drop-off', 'icon': '📍', 'category': 'Delivery & Logistics'},
    {'name': 'Truck/Van Rental', 'icon': '🚐', 'category': 'Delivery & Logistics'},
    {'name': 'Driver Services', 'icon': '🚗', 'category': 'Delivery & Logistics'},
    {'name': 'Warehouse Services', 'icon': '🏠', 'category': 'Delivery & Logistics'},
    {'name': 'Barber', 'icon': '✂️', 'category': 'Personal Services'},
    {'name': 'Makeup Artist', 'icon': '💄', 'category': 'Personal Services'},
    {'name': 'Beautician', 'icon': '✨', 'category': 'Personal Services'},
    {'name': 'Salon at Home', 'icon': '💇', 'category': 'Personal Services'},
    {'name': 'Tailor', 'icon': '🧵', 'category': 'Personal Services'},
    {'name': 'Laundry', 'icon': '👔', 'category': 'Personal Services'},
    {'name': 'Personal Trainer', 'icon': '💪', 'category': 'Personal Services'},
    {'name': 'Photographer', 'icon': '📸', 'category': 'Personal Services'},
    {'name': 'Event Services', 'icon': '🎉', 'category': 'Personal Services'},
    {'name': 'Home Tutor', 'icon': '📚', 'category': 'Education'},
    {'name': 'Online Tutor', 'icon': '💻', 'category': 'Education'},
    {'name': 'Language Teacher', 'icon': '🗣️', 'category': 'Education'},
    {'name': 'Coding Teacher', 'icon': '💻', 'category': 'Education'},
    {'name': 'Music Teacher', 'icon': '🎵', 'category': 'Education'},
    {'name': 'Exam Preparation', 'icon': '📝', 'category': 'Education'},
    {'name': 'Assignment Assistance', 'icon': '📄', 'category': 'Education'},
    {'name': 'Professional Training', 'icon': '🎓', 'category': 'Education'},
    {'name': 'Photographer', 'icon': '📸', 'category': 'Events'},
    {'name': 'Videographer', 'icon': '🎥', 'category': 'Events'},
    {'name': 'Decorator', 'icon': '🎨', 'category': 'Events'},
    {'name': 'Caterer', 'icon': '🍽️', 'category': 'Events'},
    {'name': 'DJ', 'icon': '🎧', 'category': 'Events'},
    {'name': 'Makeup Artist', 'icon': '💄', 'category': 'Events'},
    {'name': 'Event Planner', 'icon': '📋', 'category': 'Events'},
    {'name': 'Wedding Services', 'icon': '💍', 'category': 'Events'},
    {'name': 'Sound/Light Rental', 'icon': '🔊', 'category': 'Events'},
    {'name': 'Furniture/Tent Rental', 'icon': '⛺', 'category': 'Events'},
    {'name': 'Farm Equipment Repair', 'icon': '🚜', 'category': 'Agriculture'},
    {'name': 'Tractor Mechanic', 'icon': '🔧', 'category': 'Agriculture'},
    {'name': 'Irrigation Technician', 'icon': '💧', 'category': 'Agriculture'},
    {'name': 'Solar Pump Technician', 'icon': '☀️', 'category': 'Agriculture'},
    {'name': 'Agricultural Machinery', 'icon': '🌾', 'category': 'Agriculture'},
    {'name': 'Pest Control', 'icon': '🐛', 'category': 'Agriculture'},
    {'name': 'Tree Services', 'icon': '🌳', 'category': 'Agriculture'},
    {'name': 'Water Pump Repair', 'icon': '💧', 'category': 'Agriculture'},
    {'name': 'Farm Labor', 'icon': '👨‍🌾', 'category': 'Agriculture'},
    {'name': 'Livestock Services', 'icon': '🐄', 'category': 'Agriculture'},
    {'name': 'Industrial Electrician', 'icon': '⚡', 'category': 'Industrial'},
    {'name': 'Welding', 'icon': '🔥', 'category': 'Industrial'},
    {'name': 'Machine Repair', 'icon': '⚙️', 'category': 'Industrial'},
    {'name': 'Generator Maintenance', 'icon': '🔄', 'category': 'Industrial'},
    {'name': 'HVAC', 'icon': '❄️', 'category': 'Industrial'},
    {'name': 'Fabrication', 'icon': '🔩', 'category': 'Industrial'},
    {'name': 'Mechanical Maintenance', 'icon': '🔧', 'category': 'Industrial'},
    {'name': 'Industrial Plumbing', 'icon': '🔧', 'category': 'Industrial'},
    {'name': 'Safety Inspection', 'icon': '🛡️', 'category': 'Industrial'},
    {'name': 'Equipment Technicians', 'icon': '🔬', 'category': 'Industrial'},
    {'name': 'Gardener', 'icon': '🌱', 'category': 'Outdoor'},
    {'name': 'Landscaping', 'icon': '🌿', 'category': 'Outdoor'},
    {'name': 'Tree Services', 'icon': '🌳', 'category': 'Outdoor'},
    {'name': 'Pest Control', 'icon': '🐜', 'category': 'Outdoor'},
    {'name': 'Pool Maintenance', 'icon': '🏊', 'category': 'Outdoor'},
    {'name': 'Security Guard', 'icon': '🛡️', 'category': 'Security'},
    {'name': 'CCTV Installation', 'icon': '📹', 'category': 'Security'},
    {'name': 'Security Systems', 'icon': '🔐', 'category': 'Security'},
    {'name': 'Locksmith', 'icon': '🔑', 'category': 'Security'},
    {'name': 'Emergency Electrician', 'icon': '⚡', 'category': 'Emergency'},
    {'name': 'Emergency Plumber', 'icon': '🔧', 'category': 'Emergency'},
    {'name': '24/7 Locksmith', 'icon': '🔐', 'category': 'Emergency'},
    {'name': 'Roadside Assistance', 'icon': '🛣️', 'category': 'Emergency'},
    {'name': 'Emergency Towing', 'icon': '🚚', 'category': 'Emergency'},
  ];

  final List<String> _selectedServices = [];
  final List<Map<String, String>> _certificates = [];
  final TextEditingController _certNameController = TextEditingController();
  final TextEditingController _certIssuerController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLiveLocation = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  bool _showAllServices = false;
  List<Map<String, dynamic>> _filteredServices = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _floatingController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _getCurrentLocation();
    _loadUserData();
    _filteredServices = _allServices;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatingController.dispose();
    _fullNameController.dispose();
    _professionController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _searchController.dispose();
    _certNameController.dispose();
    _certIssuerController.dispose();
    super.dispose();
  }

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
                  final opacity = 0.15 + (0.08 * (1 + math.sin(_pulseController.value * math.pi * 2)) / 2);
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
                final value = math.sin(_floatingController.value * math.pi * 2);
                return Positioned(
                  top: 140 + value * 15,
                  right: 30,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.5),
                    ),
                  ),
                );
              },
            ),
            Positioned(top: 80, right: 20, child: _buildDotPattern(rows: 4, columns: 4, spacing: 18)),
            Positioned(bottom: 100, left: 16, child: _buildDotPattern(rows: 4, columns: 4, spacing: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildDotPattern({required int rows, required int columns, required double spacing}) {
    return SizedBox(
      width: columns * spacing,
      height: rows * spacing,
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(columns, (column) {
              final isEven = (row + column) % 2 == 0;
              return Container(
                width: isEven ? 4 : 2.5,
                height: isEven ? 4 : 2.5,
                margin: EdgeInsets.only(right: spacing - 4, bottom: spacing - 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(isEven ? 0.10 : 0.055),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      _fullNameController.text = user['full_name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _profileImageUrl = user['profile_image'];
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      setState(() {
        _latitude = 0.0;
        _longitude = 0.0;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final bytes = await image.readAsBytes();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${Supabase.instance.client.auth.currentUser!.id}/$fileName'; // ✅ owner folder

      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final String url = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(filePath);

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'profile_image': url})
            .eq('id', userId);
      }

      setState(() {
        _profileImageUrl = url;
        _isLoading = false;
      });

      GlobalErrorHandler.showCustomSuccess('Profile image uploaded successfully');

    } on PlatformException catch (e) {
      setState(() => _isLoading = false);

      if (e.code == 'photo_access_denied') {
        if (mounted) {
          GlobalErrorHandler.showGallerySettingsDialog(context);
        }
      } else {
        GlobalErrorHandler.showCustomError('Failed to pick image. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      GlobalErrorHandler.showCustomError('Failed to upload image. Please try again.');
    }
  }

  void _toggleService(String serviceName) {
    setState(() {
      if (_selectedServices.contains(serviceName)) {
        _selectedServices.remove(serviceName);
      } else {
        _selectedServices.add(serviceName);
      }
    });
  }

  void _addCertificate() {
    final name = _certNameController.text.trim();
    if (name.isEmpty) {
      GlobalErrorHandler.showCustomError('Please enter certificate name');
      return;
    }

    setState(() {
      _certificates.add({
        'name': name,
        'issuer': _certIssuerController.text.trim(),
      });
      _certNameController.clear();
      _certIssuerController.clear();
    });
  }

  void _removeCertificate(int index) {
    setState(() => _certificates.removeAt(index));
  }

  void _filterServices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredServices = _allServices;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredServices = _allServices.where((service) {
          final name = service['name'].toString().toLowerCase();
          final category = service['category'].toString().toLowerCase();
          return name.contains(lowerQuery) || category.contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _saveCV() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedServices.isEmpty) {
      GlobalErrorHandler.showCustomError('Please select at least one service');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) {
      setState(() => _errorMessage = 'Please login again');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await GlobalErrorHandler.run<bool>(
      context: context,
      action: () async {
        final existingUser = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
          await Supabase.instance.client
              .from('users')
              .update({'profile_image': _profileImageUrl})
              .eq('id', userId);
        }

        if (existingUser == null) {
          final user = Supabase.instance.client.auth.currentUser;
          final fullName = authProvider.user?['full_name'] ?? user?.email?.split('@').first ?? 'User';
          final email = authProvider.user?['email'] ?? user?.email ?? 'unknown@email.com';

          await Supabase.instance.client.from('users').insert({
            'id': userId,
            'email': email,
            'full_name': fullName,
            'role': 'provider',
            'is_online': true,
            'profile_image': _profileImageUrl,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          if (existingUser['role'] != 'provider') {
            await Supabase.instance.client
                .from('users')
                .update({'role': 'provider'})
                .eq('id', userId);
          }
        }

        final providerData = {
          'user_id': userId,
          'profession': _professionController.text.trim(),
          'about': _aboutController.text.trim(),
          'phone': _phoneController.text.trim(),
          'permanent_address': _addressController.text.trim(),
          'latitude': _latitude ?? 0.0,
          'longitude': _longitude ?? 0.0,
          'is_live_location': _isLiveLocation,
          'experience': _experienceController.text.trim(),
          'is_available': true,
          'email': _emailController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await SupabaseService().createProviderProfile(providerData);

        final providers = await Supabase.instance.client
            .from('providers')
            .select('id')
            .eq('user_id', userId)
            .limit(1);

        if (providers.isEmpty) {
          throw Exception('Provider not created');
        }

        final providerId = providers.first['id'];

        for (final serviceName in _selectedServices) {
          await SupabaseService().addProviderService({
            'provider_id': providerId,
            'category_id': serviceName.toLowerCase().replaceAll(' ', '_'),
            'service_name': serviceName,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        for (final cert in _certificates) {
          await Supabase.instance.client
              .from('provider_certificates')
              .insert({
            'provider_id': providerId,
            'name': cert['name'],
            'issuing_authority': cert['issuer'],
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        return true;
      },
    );

    if (success == true && mounted) {
      GlobalErrorHandler.showCustomSuccess('CV created successfully!');
      context.go('/provider/dashboard');
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => context.go('/business/type'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 22),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Title
                    const Text(
                      'Create Professional CV',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set up your profile to start getting requests',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null) _buildErrorWidget(),

                    // ✅ Centered Profile Header
                    Center(
                      child: _buildProfileHeader(),
                    ),
                    const SizedBox(height: 16),

                    // Personal Info Card
                    _buildModernCard(
                      title: 'Personal Information',
                      icon: Icons.person_outline,
                      children: [
                        _buildTextField(_fullNameController, 'Full Name *', Icons.person_outline),
                        const SizedBox(height: 12),
                        _buildTextField(_professionController, 'Profession *', Icons.work_outline),
                        const SizedBox(height: 12),
                        _buildTextField(_aboutController, 'About Me', Icons.info_outline, maxLines: 3),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact Info Card
                    _buildModernCard(
                      title: 'Contact Information',
                      icon: Icons.contact_phone,
                      children: [
                        _buildTextField(_phoneController, 'Phone Number *', Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildTextField(_emailController, 'Email Address', Icons.email_outlined),
                        const SizedBox(height: 12),
                        _buildTextField(_addressController, 'Address *', Icons.location_on_outlined, maxLines: 2),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Experience & Location Card
                    _buildModernCard(
                      title: 'Experience & Location',
                      icon: Icons.location_on,
                      children: [
                        _buildTextField(_experienceController, 'Years of Experience', Icons.history_outlined, keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _buildLocationWidget(),
                        const SizedBox(height: 12),
                        _buildLiveLocationSwitch(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Services Card
                    _buildServicesCard(),
                    const SizedBox(height: 16),

                    // Certificates Card
                    _buildModernCard(
                      title: 'Certificates',
                      icon: Icons.verified_outlined,
                      children: [
                        _buildCertificatesWidget(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    final displayedServices = _showAllServices ? _filteredServices : _filteredServices.take(8).toList();

    return _buildModernCard(
      title: 'Services',
      icon: Icons.build_circle_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_selectedServices.length} selected',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterServices,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    _filterServices('');
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayedServices.map((service) {
            final isSelected = _selectedServices.contains(service['name']);
            final icon = service['icon'] ?? '📌';
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    service['name'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => _toggleService(service['name']),
              selectedColor: const Color(0xFF49e8c3),
              backgroundColor: Colors.white.withOpacity(0.05),
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
              side: BorderSide(color: isSelected ? const Color(0xFF49e8c3) : Colors.white.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }).toList(),
        ),
        if (_allServices.length > 8)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllServices = !_showAllServices;
                      if (_showAllServices) {
                        _filteredServices = _allServices;
                      } else {
                        _filterServices(_searchController.text);
                      }
                    });
                  },
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF49e8c3)),
                  child: Text(
                    _showAllServices ? 'Show Less' : 'View All Services',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        if (_selectedServices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF49e8c3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF49e8c3).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Services (${_selectedServices.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF49e8c3)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _selectedServices.map((service) {
                      final icon = _allServices.firstWhere((s) => s['name'] == service, orElse: () => {})['icon'] ?? '📌';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF49e8c3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$icon $service',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ✅ Centered Profile Header
  Widget _buildProfileHeader() {
    return Container(
      width: 300, // ✅ Fixed width to center
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF49e8c3), Color(0xFF38804f)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF49e8c3).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                  child: _profileImageUrl == null ? const Icon(Icons.person, size: 45, color: Colors.white) : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF38804f), size: 18),
                    onPressed: _pickProfileImage,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _fullNameController.text.isNotEmpty ? _fullNameController.text : 'Add Your Photo',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          const Text(
            'Tap camera icon to upload',
            style: TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
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
                child: Icon(icon, color: const Color(0xFF49e8c3), size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType? keyboardType,
        bool enabled = true,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF49e8c3), size: 22),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF49e8c3), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (label.contains('*') && (value == null || value.trim().isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildLocationWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF49e8c3).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: Color(0xFF49e8c3), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _latitude != null && _latitude != 0.0
                  ? '📍 ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                  : 'Getting location...',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70),
            ),
          ),
          GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF49e8c3).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Color(0xFF49e8c3), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveLocationSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Live Location Sharing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
        subtitle: Text('Share real-time location', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
        value: _isLiveLocation,
        onChanged: (value) {
          setState(() => _isLiveLocation = value);
          if (value) _getCurrentLocation();
        },
        activeColor: const Color(0xFF49e8c3),
        activeTrackColor: const Color(0xFF49e8c3).withOpacity(0.3),
        inactiveThumbColor: Colors.white54,
        secondary: Icon(
          _isLiveLocation ? Icons.location_on : Icons.location_off,
          color: _isLiveLocation ? const Color(0xFF49e8c3) : Colors.white54,
        ),
      ),
    );
  }

  Widget _buildCertificatesWidget() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTextField(_certNameController, 'Certificate Name', Icons.description_outlined)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(_certIssuerController, 'Issuer', Icons.business_outlined)),
            const SizedBox(width: 8),
            Container(
              height: 50,
              decoration: BoxDecoration(color: const Color(0xFF49e8c3), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                onPressed: _addCertificate,
                icon: const Icon(Icons.add, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_certificates.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.verified_outlined, color: Colors.white.withOpacity(0.3), size: 32),
                  const SizedBox(height: 4),
                  Text('No certificates added yet', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                ],
              ),
            ),
          ),
        ..._certificates.asMap().entries.map((entry) {
          final index = entry.key;
          final cert = entry.value;
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF49e8c3).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF49e8c3).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified, color: Color(0xFF49e8c3), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cert['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                      if (cert['issuer']?.isNotEmpty ?? false)
                        Text(cert['issuer'] ?? '', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeCertificate(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close, color: Colors.red, size: 16),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCV,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF49e8c3),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 22),
            SizedBox(width: 10),
            Text('Save CV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}