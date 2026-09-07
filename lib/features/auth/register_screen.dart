// lib/features/auth/register_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../widgets/loading_button.dart';
import '../provider/auth_provider.dart';
import '../../core/services/supabase_service.dart';
import 'face_recoganization.dart';
import 'ocr_service.dart';

enum RegisterStep {
  cnicUpload,
  cnicVerification,
  facialVerification,
  personalInfo,
  completion
}

class RegisterScreen extends StatefulWidget {
  final String? role;
  const RegisterScreen({super.key, this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final OCRService _ocrService = OCRService();
  final FaceRecognitionService _faceService = FaceRecognitionService();

  // Animation Controllers
  late final AnimationController _pulseController;
  late final AnimationController _floatingController;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // CNIC Data
  String? _cnicNumber;
  String? _cnicName;
  String? _cnicDob;
  String? _cnicFrontImage;
  String? _cnicBackImage;
  bool _isCnicProcessing = false;
  bool _isCnicVerified = false;
  bool _isCnicAlreadyRegistered = false;
  Map<String, dynamic>? _existingUser;

  // Face Recognition
  bool _isFaceVerified = false;
  bool _isFaceCapturing = false;
  String? _faceImage;
  String? _faceEmbedding;
  String? _faceVerificationMessage;

  // UI State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  RegisterStep _currentRegisterStep = RegisterStep.cnicUpload;
  String? _errorMessage;
  double _progressValue = 0.0;

  // ✅ Track if user is provider or business (both need verification)
  bool get _isProvider => widget.role == 'provider' || widget.role == 'business';
  bool get _isCustomer => widget.role == 'user';

  // ✅ Get the actual role for navigation
  String get _actualRole => widget.role ?? 'user';

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _progressValue = 0.1;

    // ✅ If customer, skip CNIC and face verification
    if (_isCustomer) {
      _currentRegisterStep = RegisterStep.personalInfo;
      _progressValue = 0.3;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatingController.dispose();
    _ocrService.dispose();
    _faceService.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // BACKGROUND WIDGET
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
    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(columns, (col) {
            return Container(
              width: 3,
              height: 3,
              margin: EdgeInsets.all(spacing / 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            );
          }),
        );
      }),
    );
  }

  // ============================================================
  // CNIC UPLOAD (Only for Providers/Business)
  // ============================================================
  Future<void> _pickCnicImage(String side) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        if (side == 'front') {
          _cnicFrontImage = image.path;
        } else {
          _cnicBackImage = image.path;
        }
        // Reset verification status when new image is uploaded
        _isCnicVerified = false;
        _isCnicAlreadyRegistered = false;
        _cnicNumber = null;
        _cnicName = null;
        _existingUser = null;
      });
    }
  }

  // ============================================================
  // CNIC VERIFICATION (OCR) - Only for Providers/Business
  // ============================================================
  Future<void> _processCnicImages() async {
    if (_cnicFrontImage == null || _cnicBackImage == null) {
      setState(() {
        _errorMessage = 'Please upload both sides of your CNIC';
      });
      return;
    }

    setState(() {
      _isCnicProcessing = true;
      _errorMessage = null;
      _isCnicAlreadyRegistered = false;
      _existingUser = null;
    });

    try {
      // Extract CNIC data using OCR
      final cnicData = await _ocrService.extractCNICData(
        File(_cnicFrontImage!),
      );

      if (cnicData.cnicNumber.isEmpty) {
        setState(() {
          _errorMessage = 'Could not read CNIC. Please try with a clearer image.';
          _isCnicProcessing = false;
        });
        return;
      }

      // Check if CNIC already registered
      final supabase = SupabaseService();
      final existingUser = await supabase.getUserByCNIC(cnicData.cnicNumber);

      if (existingUser != null) {
        // CNIC is already registered
        setState(() {
          _isCnicAlreadyRegistered = true;
          _existingUser = existingUser;
          _cnicNumber = cnicData.cnicNumber;
          _cnicName = cnicData.fullName.isNotEmpty ? cnicData.fullName : 'User';
          _cnicDob = cnicData.dateOfBirth;
          _isCnicProcessing = false;
          _isCnicVerified = false;
          _currentRegisterStep = RegisterStep.cnicVerification;
          _progressValue = 0.3;
        });
        return;
      }

      // CNIC is not registered, proceed with verification
      setState(() {
        _cnicNumber = cnicData.cnicNumber;
        _cnicName = cnicData.fullName.isNotEmpty ? cnicData.fullName : 'User';
        _cnicDob = cnicData.dateOfBirth;
        _isCnicVerified = true;
        _isCnicAlreadyRegistered = false;
        _isCnicProcessing = false;
        _currentRegisterStep = RegisterStep.cnicVerification;
        _progressValue = 0.3;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify CNIC: $e';
        _isCnicProcessing = false;
      });
    }
  }

  // ============================================================
  // FACIAL VERIFICATION (Only for Providers/Business)
  // ============================================================
  Future<void> _captureAndVerifyFace() async {
    setState(() {
      _isFaceCapturing = true;
      _errorMessage = null;
      _faceVerificationMessage = 'Capturing face...';
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 70,
      );

      if (image == null) {
        setState(() {
          _isFaceCapturing = false;
          _faceVerificationMessage = null;
        });
        return;
      }

      setState(() {
        _faceImage = image.path;
        _faceVerificationMessage = 'Verifying face...';
      });

      // Verify face
      final result = await _faceService.verifyFace(File(image.path));

      if (result.isVerified) {
        setState(() {
          _isFaceVerified = true;
          _faceEmbedding = result.faceEmbedding;
          _faceVerificationMessage = '✅ ${result.message}';
          _isFaceCapturing = false;
          _currentRegisterStep = RegisterStep.personalInfo;
          _progressValue = 0.7;
        });
      } else {
        setState(() {
          _faceVerificationMessage = '❌ ${result.message}';
          _isFaceCapturing = false;
        });
        // Allow retry
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _faceVerificationMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify face: $e';
        _isFaceCapturing = false;
        _faceVerificationMessage = null;
      });
    }
  }

  // ============================================================
  // COMPLETE REGISTRATION
  // ============================================================
  Future<void> _completeRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final supabase = SupabaseService();

      // ✅ For providers/business: Check CNIC is not already registered
      if (_isProvider) {
        final existingUser = await supabase.getUserByCNIC(_cnicNumber!);
        if (existingUser != null) {
          setState(() {
            _errorMessage = 'This CNIC is already registered. Please login.';
            _isLoading = false;
            _isCnicAlreadyRegistered = true;
            _existingUser = existingUser;
            _currentRegisterStep = RegisterStep.cnicVerification;
          });
          return;
        }
      }

      // Register user with Supabase Auth
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _isProvider
            ? (_cnicName ?? _nameController.text.trim())
            : _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _actualRole, // ✅ Use the actual role
      );

      if (success && mounted) {
        final userId = authProvider.userId;
        if (userId != null) {
          // ✅ For providers/business: Upload verification images and save data
          if (_isProvider) {
            final frontImageUrl = await supabase.uploadVerificationImage(
              userId,
              'cnic_front',
              File(_cnicFrontImage!),
            );

            final backImageUrl = await supabase.uploadVerificationImage(
              userId,
              'cnic_back',
              File(_cnicBackImage!),
            );

            final faceImageUrl = await supabase.uploadVerificationImage(
              userId,
              'face',
              File(_faceImage!),
            );

            // Save verification data
            await supabase.saveUserWithVerification(
              userId: userId,
              cnicNumber: _cnicNumber!,
              cnicFrontImage: frontImageUrl,
              cnicBackImage: backImageUrl,
              faceImage: faceImageUrl,
              faceEmbedding: _faceEmbedding!,
            );
          }
        }

        setState(() {
          _currentRegisterStep = RegisterStep.completion;
          _progressValue = 1.0;
          _isLoading = false;
        });

        // ✅ Navigate based on role
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          if (_isProvider) {
            // ✅ For both 'provider' and 'business' roles, go to business setup
            context.go('/business/type');
          } else {
            // ✅ For 'user' role, go to user home
            context.go('/user/home');
          }
        }
      } else {
        setState(() {
          _errorMessage = authProvider.error ?? 'Registration failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // BUILD METHODS
  // ============================================================
  Widget _buildCnicUpload() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 24),
          Text(
            'CNIC Verification',
            style: AppTextStyles.headline2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your CNIC front and back for verification',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),

          if (_isCnicProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing CNIC...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildCnicUploadCard(
              title: 'CNIC Front',
              subtitle: 'Upload the f]ront side of your CNIC',
              imagePath: _cnicFrontImage,
              onTap: () => _pickCnicImage('front'),
              isUploaded: _cnicFrontImage != null,
            ),
            const SizedBox(height: 16),
            _buildCnicUploadCard(
              title: 'CNIC Back',
              subtitle: 'Upload the back side of your CNIC',
              imagePath: _cnicBackImage,
              onTap: () => _pickCnicImage('back'),
              isUploaded: _cnicBackImage != null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_cnicFrontImage != null && _cnicBackImage != null)
                    ? _processCnicImages
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF38804f),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Verify CNIC',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.pop();
            },
            child: const Text(
              'Back',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCnicUploadCard({
    required String title,
    required String subtitle,
    required String? imagePath,
    required VoidCallback onTap,
    required bool isUploaded,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white.withOpacity(0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isUploaded
                      ? Colors.green.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUploaded ? Colors.green : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: isUploaded && imagePath != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                )
                    : Icon(
                  isUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
                  color: isUploaded ? Colors.green : Colors.white70,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUploaded ? 'Uploaded ✓' : subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isUploaded ? Colors.green : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isUploaded ? Icons.check_circle : Icons.arrow_forward_ios,
                color: isUploaded ? Colors.green : Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCnicVerification() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 24),

          // Show success or error based on verification status
          Row(
            children: [
              Icon(
                _isCnicVerified && !_isCnicAlreadyRegistered
                    ? Icons.verified
                    : _isCnicAlreadyRegistered
                    ? Icons.error
                    : Icons.warning,
                color: _isCnicVerified && !_isCnicAlreadyRegistered
                    ? Colors.green
                    : _isCnicAlreadyRegistered
                    ? Colors.red
                    : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isCnicVerified && !_isCnicAlreadyRegistered
                      ? 'CNIC Verified Successfully'
                      : _isCnicAlreadyRegistered
                      ? 'CNIC Already Registered'
                      : 'CNIC Verification Failed',
                  style: AppTextStyles.headline2.copyWith(
                    color: _isCnicVerified && !_isCnicAlreadyRegistered
                        ? Colors.green
                        : _isCnicAlreadyRegistered
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Show warning if CNIC is already registered
          if (_isCnicAlreadyRegistered && _existingUser != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This CNIC is already registered!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('CNIC Number', _cnicNumber ?? 'N/A'),
                  _buildInfoRow('Full Name', _cnicName ?? 'N/A'),
                  _buildInfoRow('Email', _existingUser?['email'] ?? 'N/A'),
                  _buildInfoRow('Role', _existingUser?['role'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/login', extra: _actualRole);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF38804f),
                      ),
                      child: const Text('Login Instead'),
                    ),
                  ),
                ],
              ),
            ),

          // Show CNIC info if verified
          if (_isCnicVerified && !_isCnicAlreadyRegistered)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CNIC Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('CNIC Number', _cnicNumber ?? 'N/A'),

                    _buildInfoRow('Status', 'Verified ✓'),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Show appropriate button
          if (_isCnicAlreadyRegistered)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentRegisterStep = RegisterStep.cnicUpload;
                    _progressValue = 0.1;
                    _cnicNumber = null;
                    _cnicName = null;
                    _cnicDob = null;
                    _cnicFrontImage = null;
                    _cnicBackImage = null;
                    _isCnicVerified = false;
                    _isCnicAlreadyRegistered = false;
                    _existingUser = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Try Another CNIC',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (_isCnicVerified)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentRegisterStep = RegisterStep.facialVerification;
                    _progressValue = 0.5;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF38804f),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue to Face Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _currentRegisterStep = RegisterStep.cnicUpload;
                _progressValue = 0.1;
                _isCnicVerified = false;
                _isCnicAlreadyRegistered = false;
              });
            },
            child: const Text(
              'Back',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacialVerification() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 24),
          Text(
            'Facial Verification',
            style: AppTextStyles.headline2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Please position your face in the frame and follow the instructions',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _faceImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_faceImage!),
                fit: BoxFit.cover,
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 60,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Position your face in the frame',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_faceVerificationMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _faceVerificationMessage!.contains('✅')
                    ? Colors.green.withOpacity(0.2)
                    : _faceVerificationMessage!.contains('❌')
                    ? Colors.red.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _faceVerificationMessage!.contains('✅')
                      ? Colors.green.withOpacity(0.3)
                      : _faceVerificationMessage!.contains('❌')
                      ? Colors.red.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _faceVerificationMessage!.contains('✅')
                        ? Icons.check_circle
                        : _faceVerificationMessage!.contains('❌')
                        ? Icons.error_outline
                        : Icons.info_outline,
                    color: _faceVerificationMessage!.contains('✅')
                        ? Colors.green
                        : _faceVerificationMessage!.contains('❌')
                        ? Colors.red
                        : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _faceVerificationMessage!,
                      style: TextStyle(
                        color: _faceVerificationMessage!.contains('✅')
                            ? Colors.green.shade200
                            : _faceVerificationMessage!.contains('❌')
                            ? Colors.red.shade200
                            : Colors.blue.shade200,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: LoadingButton(
              onPressed: _isFaceVerified
                  ? null
                  : () {
                _captureAndVerifyFace();
              },
              isLoading: _isFaceCapturing,
              label: _isFaceVerified ? '✅ Verified' : 'Capture & Verify Face',
              backgroundColor: _isFaceVerified ? Colors.green : Colors.white,
              textColor: _isFaceVerified ? Colors.white : const Color(0xFF38804f),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _currentRegisterStep = RegisterStep.cnicVerification;
                _progressValue = 0.3;
              });
            },
            child: const Text(
              'Back',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressBar(),
            const SizedBox(height: 24),
            Text(
              _isProvider ? 'Personal Information' : 'Create Account',
              style: AppTextStyles.headline2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _isProvider
                  ? 'Enter your details to complete registration'
                  : 'Enter your details to create your account',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),

            // ✅ Show CNIC info only for providers/business
            if (_isProvider) ...[
              _buildReadOnlyField('CNIC Number', _cnicNumber ?? 'N/A'),
              const SizedBox(height: 16),

            ] else ...[
              // ✅ For customers, they need to enter name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter your full name';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white70),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter your phone number';
                if (value!.length < 10) return 'Please enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email *',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password *',
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please create a password';
                if (value!.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Confirm your password',
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please confirm your password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _completeRegistration,
              isLoading: _isLoading,
              label: _isProvider ? 'Complete Registration' : 'Create Account',
              backgroundColor: Colors.white,
              textColor: const Color(0xFF38804f),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                if (_isProvider) {
                  setState(() {
                    _currentRegisterStep = RegisterStep.facialVerification;
                    _progressValue = 0.5;
                  });
                } else {
                  context.pop();
                }
              },
              child: Text(
                _isProvider ? 'Back' : 'Back to Login',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified,
            color: Colors.green,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isProvider ? 'Registration Complete! 🎉' : 'Account Created! 🎉',
          style: AppTextStyles.headline1.copyWith(color: Colors.green),
        ),
        const SizedBox(height: 8),
        Text(
          _isProvider
              ? 'Your ${_actualRole == 'business' ? 'business' : 'provider'} account has been created successfully'
              : 'Your account has been created successfully',
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        if (_isProvider) ...[
          const SizedBox(height: 8),
          Text(
            'CNIC: ${_cnicNumber ?? "N/A"}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_isProvider) {
                // ✅ Both 'provider' and 'business' go to business setup
                context.go('/business/type');
              } else {
                // ✅ 'user' goes to user home
                context.go('/user/home');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF38804f),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isProvider ? 'Continue to Setup' : 'Go to Home',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROGRESS BAR
  // ============================================================
  Widget _buildProgressBar() {
    final steps = _isProvider ? ['CNIC', 'Face', 'Info', 'Done'] : ['Info', 'Done'];
    final values = _isProvider ? [0.0, 0.25, 0.5, 0.75, 1.0] : [0.0, 0.5, 1.0];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isActive = _progressValue >= values[index + 1];
            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF38804f) : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[index],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _progressValue,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    if (_errorMessage != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _errorMessage = null),
                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                ),
              ],
            ),
          ),
          Expanded(child: _buildStepContent()),
        ],
      );
    }
    return _buildStepContent();
  }

  Widget _buildStepContent() {
    switch (_currentRegisterStep) {
      case RegisterStep.cnicUpload:
        return _buildCnicUpload();
      case RegisterStep.cnicVerification:
        return _buildCnicVerification();
      case RegisterStep.facialVerification:
        return _buildFacialVerification();
      case RegisterStep.personalInfo:
        return _buildPersonalInfo();
      case RegisterStep.completion:
        return _buildCompletion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with animations
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildBackground(Size(
                constraints.maxWidth,
                constraints.maxHeight,
              ));
            },
          ),
          // Content on top of background
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }
}