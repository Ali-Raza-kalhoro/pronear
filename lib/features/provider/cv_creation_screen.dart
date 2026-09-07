import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../widgets/loading_button.dart';
import 'auth_provider.dart';

class CVCreationScreen extends StatefulWidget {
  const CVCreationScreen({super.key});

  @override
  State<CVCreationScreen> createState() => _CVCreationScreenState();
}

class _CVCreationScreenState extends State<CVCreationScreen> {
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

  // Services - All Categories from the new list
  final List<Map<String, dynamic>> _allServices = [
    // 🏠 Home & Property
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

    // 🚗 Automotive
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

    // ⚡ Energy & Utilities
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

    // 💻 Technology
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

    // 🏢 Business & Office
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

    // 🚚 Delivery & Logistics
    {'name': 'Local Delivery', 'icon': '📦', 'category': 'Delivery & Logistics'},
    {'name': 'Furniture Transport', 'icon': '🛋️', 'category': 'Delivery & Logistics'},
    {'name': 'Moving Services', 'icon': '🚚', 'category': 'Delivery & Logistics'},
    {'name': 'Courier', 'icon': '📨', 'category': 'Delivery & Logistics'},
    {'name': 'Pickup/Drop-off', 'icon': '📍', 'category': 'Delivery & Logistics'},
    {'name': 'Truck/Van Rental', 'icon': '🚐', 'category': 'Delivery & Logistics'},
    {'name': 'Driver Services', 'icon': '🚗', 'category': 'Delivery & Logistics'},
    {'name': 'Warehouse Services', 'icon': '🏠', 'category': 'Delivery & Logistics'},

    // 👤 Personal Services
    {'name': 'Barber', 'icon': '✂️', 'category': 'Personal Services'},
    {'name': 'Makeup Artist', 'icon': '💄', 'category': 'Personal Services'},
    {'name': 'Beautician', 'icon': '✨', 'category': 'Personal Services'},
    {'name': 'Salon at Home', 'icon': '💇', 'category': 'Personal Services'},
    {'name': 'Tailor', 'icon': '🧵', 'category': 'Personal Services'},
    {'name': 'Laundry', 'icon': '👔', 'category': 'Personal Services'},
    {'name': 'Personal Trainer', 'icon': '💪', 'category': 'Personal Services'},
    {'name': 'Photographer', 'icon': '📸', 'category': 'Personal Services'},
    {'name': 'Event Services', 'icon': '🎉', 'category': 'Personal Services'},

    // 🎓 Education
    {'name': 'Home Tutor', 'icon': '📚', 'category': 'Education'},
    {'name': 'Online Tutor', 'icon': '💻', 'category': 'Education'},
    {'name': 'Language Teacher', 'icon': '🗣️', 'category': 'Education'},
    {'name': 'Coding Teacher', 'icon': '💻', 'category': 'Education'},
    {'name': 'Music Teacher', 'icon': '🎵', 'category': 'Education'},
    {'name': 'Exam Preparation', 'icon': '📝', 'category': 'Education'},
    {'name': 'Assignment Assistance', 'icon': '📄', 'category': 'Education'},
    {'name': 'Professional Training', 'icon': '🎓', 'category': 'Education'},

    // 📸 Events
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

    // 🌱 Agriculture & Rural
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

    // 🏭 Industrial
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

    // 🌳 Outdoor
    {'name': 'Gardener', 'icon': '🌱', 'category': 'Outdoor'},
    {'name': 'Landscaping', 'icon': '🌿', 'category': 'Outdoor'},
    {'name': 'Tree Services', 'icon': '🌳', 'category': 'Outdoor'},
    {'name': 'Pest Control', 'icon': '🐜', 'category': 'Outdoor'},
    {'name': 'Pool Maintenance', 'icon': '🏊', 'category': 'Outdoor'},

    // 🔐 Security
    {'name': 'Security Guard', 'icon': '🛡️', 'category': 'Security'},
    {'name': 'CCTV Installation', 'icon': '📹', 'category': 'Security'},
    {'name': 'Security Systems', 'icon': '🔐', 'category': 'Security'},
    {'name': 'Locksmith', 'icon': '🔑', 'category': 'Security'},

    // 🔧 Emergency
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

  // Location
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
    _getCurrentLocation();
    _loadUserData();
    _filteredServices = _allServices;
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
      final filePath = 'public/$fileName';

      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final String url = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(filePath);

      print('✅ Image uploaded: $url');

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'profile_image': url})
            .eq('id', userId);
        print('✅ Profile image URL saved to users table');
      }

      setState(() {
        _profileImageUrl = url;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image uploaded successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter certificate name')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
      );
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

    try {
      print('🔍 Checking if user exists: $userId');

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
        print('✅ Profile image URL saved during CV creation');
      }

      if (existingUser == null) {
        print('⚠️ User not found in users table, creating...');

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
        print('✅ User created in users table: $userId');
      } else {
        print('✅ User found in users table');

        if (existingUser['role'] != 'provider') {
          await Supabase.instance.client
              .from('users')
              .update({'role': 'provider'})
              .eq('id', userId);
          print('✅ User role updated to provider');
        }
      }

      // Create provider profile
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
      print('✅ Provider profile created');

      // Get provider ID
      final providers = await Supabase.instance.client
          .from('providers')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if (providers.isEmpty) {
        throw Exception('Provider not created');
      }

      final providerId = providers.first['id'];
      print('✅ Provider ID: $providerId');

      // Add all selected services
      for (final serviceName in _selectedServices) {
        await SupabaseService().addProviderService({
          'provider_id': providerId,
          'category_id': serviceName.toLowerCase().replaceAll(' ', '_'),
          'service_name': serviceName,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ Added service: $serviceName');
      }

      // Add certificates
      for (final cert in _certificates) {
        await Supabase.instance.client
            .from('provider_certificates')
            .insert({
          'provider_id': providerId,
          'name': cert['name'],
          'issuing_authority': cert['issuer'],
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ Added certificate: ${cert['name']}');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV created successfully!')),
      );
      context.go('/provider/dashboard');

    } catch (e) {
      print('❌ Error saving CV: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_errorMessage != null) _buildErrorWidget(),
                _buildProfileHeader(),
                const SizedBox(height: 20),

                // Personal Info Card
                _buildModernCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  children: [
                    _buildModernTextField(
                      _fullNameController,
                      'Full Name *',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    _buildModernTextField(
                      _professionController,
                      'Profession *',
                      Icons.work_outline,
                    ),
                    const SizedBox(height: 14),
                    _buildModernTextField(
                      _aboutController,
                      'About Me',
                      Icons.info_outline,
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact Info Card
                _buildModernCard(
                  title: 'Contact Information',
                  icon: Icons.contact_phone,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  ),
                  children: [
                    _buildModernTextField(
                      _phoneController,
                      'Phone Number *',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _buildModernTextField(
                      _emailController,
                      'Email Address',
                      Icons.email_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildModernTextField(
                      _addressController,
                      'Address *',
                      Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Experience & Location Card
                _buildModernCard(
                  title: 'Experience & Location',
                  icon: Icons.location_on,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  ),
                  children: [
                    _buildModernTextField(
                      _experienceController,
                      'Years of Experience',
                      Icons.history_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _buildLocationWidget(),
                    const SizedBox(height: 14),
                    _buildLiveLocationSwitch(),
                  ],
                ),
                const SizedBox(height: 16),

                // Services Card - Enhanced with Search and Unlimited Selection
                _buildServicesCard(),

                const SizedBox(height: 16),

                // Certificates Card
                _buildModernCard(
                  title: 'Certificates',
                  icon: Icons.verified_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
                  ),
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
    );
  }

  // ============ SERVICES CARD ============
  Widget _buildServicesCard() {
    final displayedServices = _showAllServices ? _filteredServices : _filteredServices.take(8).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_circle_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedServices.length} selected',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF667EEA), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterServices,
                          decoration: const InputDecoration(
                            hintText: 'Search services...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filterServices('');
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Services Grid
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
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) => _toggleService(service['name']),
                      selectedColor: const Color(0xFF667EEA),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),

                // View All Button
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
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF667EEA),
                          ),
                          child: Text(
                            _showAllServices ? 'Show Less' : 'View All Services',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Selected Services Count
                if (_selectedServices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Services (${_selectedServices.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _selectedServices.map((service) {
                              final icon = _allServices.firstWhere(
                                    (s) => s['name'] == service,
                                orElse: () => {},
                              )['icon'] ?? '📌';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF667EEA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$icon $service',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
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

  // ============ APP BAR ============
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Create Professional CV',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          // Navigate back to Business Type Selection
          context.go('/business/type');
        },
        tooltip: 'Back',
      ),

      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
      ),
    );
  }

  // ============ ERROR WIDGET ============
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ============ PROFILE HEADER ============
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF667EEA),
                      size: 20,
                    ),
                    onPressed: _pickProfileImage,
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _fullNameController.text.isNotEmpty
                ? _fullNameController.text
                : 'Add Your Photo',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap camera icon to upload photo',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ============ MODERN CARD ============
  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Optional',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ============ MODERN TEXT FIELD ============
  Widget _buildModernTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType? keyboardType,
        bool enabled = true,
      }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? Colors.grey.shade200 : Colors.grey.shade100,
        ),
        color: enabled ? Colors.white : Colors.grey.shade50,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        style: const TextStyle(
          fontSize: 17,
          color:Colors.teal,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.deepPurple,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF667EEA), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          isDense: true,
        ),
        validator: (value) {
          if (label.contains('*') && (value == null || value.trim().isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }

  // ============ LOCATION WIDGET ============
  Widget _buildLocationWidget() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE8EEFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF667EEA),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _latitude != null && _latitude != 0.0
                  ? '📍 ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                  : 'Getting location...',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ LIVE LOCATION SWITCH ============
  Widget _buildLiveLocationSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8FAFF),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Live Location Sharing',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: const Text(
          'Share real-time location with customers',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        value: _isLiveLocation,
        onChanged: (value) {
          setState(() => _isLiveLocation = value);
          if (value) _getCurrentLocation();
        },
        activeColor: const Color(0xFF667EEA),
        inactiveThumbColor: Colors.grey.shade400,
        activeTrackColor: const Color(0xFF667EEA).withOpacity(0.3),
        secondary: _isLiveLocation
            ? const Icon(Icons.location_on, color: Color(0xFF667EEA))
            : const Icon(Icons.location_off, color: Colors.grey),
      ),
    );
  }

  // ============ CERTIFICATES WIDGET ============
  Widget _buildCertificatesWidget() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                _certNameController,
                'Certificate Name',
                Icons.description_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModernTextField(
                _certIssuerController,
                'Issuing Authority',
                Icons.business_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _addCertificate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_certificates.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.grey.shade50,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.verified_outlined, color: Colors.grey.shade400, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'No certificates added yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.08),
                  const Color(0xFF764BA2).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (cert['issuer']?.isNotEmpty ?? false)
                        Text(
                          cert['issuer'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeCertificate(index),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ============ SUBMIT BUTTON ============
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCV,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_outline, size: 22),
            SizedBox(width: 10),
            Text(
              'Save CV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}