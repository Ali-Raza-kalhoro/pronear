// lib/features/auth/register_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../widgets/loading_button.dart';
import '../provider/auth_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/global_error_handler.dart'; // ✅ Added Global Error Handler
import 'face_recoganization.dart';
import 'ocr_service.dart';

enum RegisterStep {
  emailVerification,
  cnicUpload,
  cnicVerification,
  facialVerification,
  personalInfo,
  completion,
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

  // Email OTP verification state
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isOtpVerifying = false;
  bool _isSendingOtp = false;
  bool _emailOtpVerified = false;
  String? _otpVerifiedEmail;
  Timer? _otpResendTimer;
  int _otpResendCountdown = 0;

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
  bool _acceptedLegal = false; // ✅ must accept Privacy Policy + Terms
  RegisterStep _currentRegisterStep = RegisterStep.emailVerification;
  String? _errorMessage;
  double _progressValue = 0.0;

  bool get _isProvider => widget.role == 'provider' || widget.role == 'business';
  bool get _isCustomer => widget.role == 'user';
  String get _actualRole => widget.role ?? 'user';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _currentRegisterStep = RegisterStep.emailVerification;
    _progressValue = 0.05;
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
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _otpResendTimer?.cancel();
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
                  final opacity = 0.15 +
                      (0.08 *
                          (1 +
                              math.sin(_pulseController.value * math.pi * 2)) /
                          2);
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
                final value = math.sin(_floatingController.value * math.pi * 2);
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
  // EMAIL OTP VERIFICATION
  // ============================================================
  void _startOtpResendTimer() {
    _otpResendTimer?.cancel();
    setState(() => _otpResendCountdown = 60);
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpResendCountdown <= 1) {
        timer.cancel();
        setState(() => _otpResendCountdown = 0);
      } else {
        setState(() => _otpResendCountdown--);
      }
    });
  }

  Future<void> _sendVerificationOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    final success = await GlobalErrorHandler.run<bool>(
      context: context,
      action: () async {
        await Supabase.instance.client.auth.signInWithOtp(
          email: email,
          shouldCreateUser: true,
        );
        return true;
      },
    );
    if (success == true && mounted) {
      setState(() {
        _otpVerifiedEmail = email;
        _isSendingOtp = false;
      });
      _startOtpResendTimer();

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } else {
      setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyEmailOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the full 6-digit OTP');
      return;
    }

    setState(() {
      _isOtpVerifying = true;
      _errorMessage = null;
    });

    final response = await GlobalErrorHandler.run<AuthResponse>(
      context: context,
      action: () async {
        return await Supabase.instance.client.auth.verifyOTP(
          email: _otpVerifiedEmail ?? _emailController.text.trim(),
          token: otp,
          type: OtpType.email,
        );
      },
    );

    if (response?.user != null && mounted) {
      setState(() {
        _emailOtpVerified = true;
        _isOtpVerifying = false;
        if (_isProvider) {
          _currentRegisterStep = RegisterStep.cnicUpload;
          _progressValue = 0.2;
        } else {
          _currentRegisterStep = RegisterStep.personalInfo;
          _progressValue = 0.6;
        }
      });
    } else {
      setState(() => _isOtpVerifying = false);
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) _verifyEmailOtp();
  }

  Widget _buildEmailVerification() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 24),
          Text(
            'Verify Your Email',
            style: AppTextStyles.headline2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address. We\'ll send you a 6-digit OTP code to verify it.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: _otpVerifiedEmail == null,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF49e8c3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_otpVerifiedEmail == null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: LoadingButton(
                onPressed: _sendVerificationOtp,
                isLoading: _isSendingOtp,
                label: 'Send OTP',
                backgroundColor: Colors.white,
                textColor: const Color(0xFF38804f),
              ),
            )
          else ...[
            Text(
              'Enter the 6-digit code sent to',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _otpVerifiedEmail!,
              style: const TextStyle(
                color: Color(0xFF49e8c3),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 46,
                  height: 56,
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF49e8c3),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onOtpDigitChanged(index, value),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: LoadingButton(
                onPressed: _verifyEmailOtp,
                isLoading: _isOtpVerifying,
                label: 'Verify Email',
                backgroundColor: const Color(0xFF49e8c3),
                textColor: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: _otpResendCountdown > 0
                  ? Text(
                'Resend in ${_otpResendCountdown}s',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              )
                  : TextButton(
                onPressed: () {
                  setState(() {
                    _otpVerifiedEmail = null;
                    for (final c in _otpControllers) {
                      c.clear();
                    }
                    _errorMessage = null;
                  });
                },
                child: const Text(
                  'Change email / resend',
                  style: TextStyle(
                    color: Color(0xFF49e8c3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Back to Login',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CNIC UPLOAD (With Permissions)
  // ============================================================
  Future<void> _pickCnicImage(String side) async {
    // ✅ Check Permission Before Opening Camera
    final hasPermission = await GlobalErrorHandler.requestCamera(context);
    if (!hasPermission) return;

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
        _isCnicVerified = false;
        _isCnicAlreadyRegistered = false;
        _cnicNumber = null;
        _cnicName = null;
        _existingUser = null;
      });
    }
  }

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

    final cnicData = await GlobalErrorHandler.run<CNICData>(
      context: context,
      action: () async {
        return await _ocrService.extractCNICData(File(_cnicFrontImage!));
      },
    );

    if (cnicData == null || cnicData.cnicNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Could not read CNIC. Please try with a clearer image.';
        _isCnicProcessing = false;
      });
      return;
    }

    final supabase = SupabaseService();
    final existingUser = await GlobalErrorHandler.run<Map<String, dynamic>?>(
      context: context,
      action: () async => await supabase.getUserByCNIC(cnicData.cnicNumber),
    );

    setState(() {
      _cnicNumber = cnicData.cnicNumber;
      _cnicName = cnicData.fullName.isNotEmpty ? cnicData.fullName : null;
      _cnicDob = cnicData.dateOfBirth;
      _isCnicProcessing = false;
      _currentRegisterStep = RegisterStep.cnicVerification;
      _progressValue = 0.35;

      if (existingUser != null) {
        _isCnicAlreadyRegistered = true;
        _existingUser = existingUser;
        _isCnicVerified = false;
      } else {
        _isCnicAlreadyRegistered = false;
        _isCnicVerified = true;
      }
    });
  }

  // ============================================================
  // FACE VERIFICATION (With Permissions)
  // ============================================================
  Future<void> _captureAndVerifyFace() async {
    // ✅ Check Permission Before Opening Camera
    final hasPermission = await GlobalErrorHandler.requestCamera(context);
    if (!hasPermission) return;

    setState(() {
      _isFaceCapturing = true;
      _errorMessage = null;
      _faceVerificationMessage = 'Capturing face...';
    });

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

    final result = await GlobalErrorHandler.run<FaceVerificationResult>(
      context: context,
      action: () async => await _faceService.verifyFace(File(image.path)),
    );

    if (result != null && result.isVerified) {
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
        _faceVerificationMessage = '❌ ${result?.message ?? "Verification failed"}';
        _isFaceCapturing = false;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _faceVerificationMessage = null;
          });
        }
      });
    }
  }

  // ============================================================
  // COMPLETE REGISTRATION (With Global Error Handling)
  // ============================================================
  Future<void> _completeRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedLegal) {
      GlobalErrorHandler.showCustomError(
          'Please accept the Privacy Policy and Terms of Service to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await GlobalErrorHandler.run<bool>(
      context: context,
      action: () async {
        final authProvider = context.read<AuthProvider>();
        final supabase = SupabaseService();

        if (_isProvider) {
          final existingUser = await supabase.getUserByCNIC(_cnicNumber!);
          if (existingUser != null) {
            throw Exception('This CNIC is already registered. Please login.');
          }
        }

        final currentUser = Supabase.instance.client.auth.currentUser;

        if (currentUser != null &&
            (currentUser.email ?? '').toLowerCase() ==
                _emailController.text.trim().toLowerCase()) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              password: _passwordController.text,
              data: {
                'full_name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'role': _actualRole,
              },
            ),
          );

          final userId = currentUser.id;
          final fullName = _nameController.text.trim();

          // ✅ OTP sign-up never inserts into public.users – make sure the
          // row exists (otherwise splash logs the user out on next launch).
          await supabase.ensureUserExists(
            userId,
            email: currentUser.email,
            fullName: fullName,
            role: _actualRole,
          );
          await supabase.updateUserProfile(userId, {
            'full_name': fullName,
            if (_phoneController.text.trim().isNotEmpty)
              'phone': _phoneController.text.trim(),
          });

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

            await supabase.saveUserWithVerification(
              userId: userId,
              cnicNumber: _cnicNumber!,
              cnicFrontImage: frontImageUrl,
              cnicBackImage: backImageUrl,
              faceImage: faceImageUrl,
              faceEmbedding: _faceEmbedding!,
            );
          }
          return true;
        } else {
          final res = await authProvider.register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _actualRole,
          );
          if (!res) throw Exception(authProvider.error ?? 'Registration failed');
          return true;
        }
      },
    );

    if (success == true && mounted) {
      setState(() {
        _currentRegisterStep = RegisterStep.completion;
        _progressValue = 1.0;
        _isLoading = false;
      });

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        if (_isProvider) {
          context.go('/business/type');
        } else {
          context.go('/user/home');
        }
      }
    } else {
      setState(() => _isLoading = false);
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
              subtitle: 'Upload the front side of your CNIC',
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
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    color: isUploaded
                        ? Colors.green
                        : Colors.white.withOpacity(0.3),
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
                  isUploaded
                      ? Icons.check_circle
                      : Icons.cloud_upload_outlined,
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

          if (_isCnicAlreadyRegistered)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentRegisterStep = RegisterStep.cnicUpload;
                    _progressValue = 0.2;
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
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _currentRegisterStep = RegisterStep.cnicUpload;
                _progressValue = 0.2;
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
              label:
              _isFaceVerified ? '✅ Verified' : 'Capture & Verify Face',
              backgroundColor:
              _isFaceVerified ? Colors.green : Colors.white,
              textColor:
              _isFaceVerified ? Colors.white : const Color(0xFF38804f),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _currentRegisterStep = RegisterStep.cnicVerification;
                _progressValue = 0.35;
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

            if (_isProvider) ...[
              _buildReadOnlyField('CNIC Number', _cnicNumber ?? 'N/A'),
              const SizedBox(height: 16),
            ],
            // ✅ Name is asked from everyone (OCR does not read the name, so
            // providers were previously saved as "User").
            ...[
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: Colors.white70),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            _buildReadOnlyField(
              'Verified Email',
              _emailController.text.trim(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Enter your phone number',
                prefixIcon:
                const Icon(Icons.phone_outlined, color: Colors.white70),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.3)),
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
                if (value?.isEmpty ?? true) {
                  return 'Please enter your phone number';
                }
                if (value!.length < 10) {
                  return 'Please enter a valid phone number';
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
                prefixIcon:
                const Icon(Icons.lock_outline, color: Colors.white70),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.3)),
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
                if (value?.isEmpty ?? true) {
                  return 'Please create a password';
                }
                if (value!.length < 6) {
                  return 'Password must be at least 6 characters';
                }
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
                prefixIcon:
                const Icon(Icons.lock_outline, color: Colors.white70),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() =>
                  _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.3)),
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
                if (value?.isEmpty ?? true) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // ✅ Consent: Privacy Policy + Terms (required)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: _acceptedLegal,
                    onChanged: (v) => setState(() => _acceptedLegal = v ?? false),
                    activeColor: const Color(0xFF49e8c3),
                    checkColor: Colors.black,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('I agree to the ',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        GestureDetector(
                          onTap: () => context.push('/legal/privacy'),
                          child: const Text('Privacy Policy',
                              style: TextStyle(
                                  color: Color(0xFF49e8c3),
                                  fontSize: 13,
                                  decoration: TextDecoration.underline)),
                        ),
                        const Text(' and ',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        GestureDetector(
                          onTap: () => context.push('/legal/terms'),
                          child: const Text('Terms of Service',
                              style: TextStyle(
                                  color: Color(0xFF49e8c3),
                                  fontSize: 13,
                                  decoration: TextDecoration.underline)),
                        ),
                        if (_isProvider)
                          const Text(
                              '. I consent to my CNIC and face photos being stored for identity verification.',
                              style: TextStyle(color: Colors.white70, fontSize: 13))
                        else
                          const Text('.',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                  setState(() {
                    _currentRegisterStep = RegisterStep.emailVerification;
                    _progressValue = 0.05;
                  });
                }
              },
              child: Text(
                _isProvider ? 'Back' : 'Back',
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
                context.go('/business/type');
              } else {
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
    final steps = _isProvider
        ? ['Email', 'CNIC', 'Face', 'Info', 'Done']
        : ['Email', 'Info', 'Done'];

    final values = _isProvider
        ? [0.0, 0.2, 0.45, 0.7, 1.0, 1.0]
        : [0.0, 0.5, 1.0, 1.0];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isActive = _progressValue >= values[index + 1];
            return Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color:
                    isActive ? Colors.white : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF38804f)
                            : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[index],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 9,
                    fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
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
                  child:
                  const Icon(Icons.close, color: Colors.red, size: 18),
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
      case RegisterStep.emailVerification:
        return _buildEmailVerification();
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
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildBackground(Size(
                constraints.maxWidth,
                constraints.maxHeight,
              ));
            },
          ),
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