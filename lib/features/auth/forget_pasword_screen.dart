// lib/features/auth/forgot_password_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../widgets/loading_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // OTP controllers - 6 boxes
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // Step: 0 = enter email, 1 = enter OTP, 2 = set new password
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _userEmail;

  // Timer for resend cooldown
  Timer? _resendTimer;
  int _resendCountdown = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
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
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _pulseController.dispose();
    _floatingController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BACKGROUND
  // ============================================================
  Widget _buildBackground(Size size) {
    return IgnorePointer(
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
        ],
      ),
    );
  }

  // ============================================================
  // ERROR TRANSLATOR
  // ============================================================
  String _translateError(String error) {
    final msg = error.toLowerCase();

    if (msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('network') ||
        msg.contains('host lookup') ||
        msg.contains('connection') ||
        msg.contains('failed to fetch')) {
      return 'Please connect to the internet. Check your network.';
    }

    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    } else if (msg.contains('email not confirmed')) {
      return 'Please verify your email address first.';
    } else if (msg.contains('user not found')) {
      return 'No account found with this email.';
    } else if (msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a minute.';
    } else if (msg.contains('invalid otp') || msg.contains('invalid token')) {
      return 'The OTP code is incorrect. Please try again.';
    } else if (msg.contains('expired')) {
      return 'The code has expired. Please request a new one.';
    } else if (msg.contains('password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }

    return 'Something went wrong. Please try again.';
  }

  // ============================================================
  // STEP 1: Send OTP to email
  // ============================================================
  Future<void> _sendOtp() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      setState(() {
        _userEmail = email;
        _currentStep = 1;
        _isLoading = false;
        _successMessage = 'OTP sent to $email. Check your inbox.';
      });

      _startResendTimer();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      setState(() {
        _errorMessage = _translateError(e.toString());
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // STEP 2: Verify OTP
  // ============================================================
  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _userEmail!,
        token: otp,
        type: OtpType.recovery,
      );

      if (response.user != null) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
          _successMessage = 'OTP verified! Set your new password.';
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid OTP. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _translateError(e.toString());
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // STEP 3: Update password
  // ============================================================
  Future<void> _updatePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      setState(() {
        _isLoading = false;
        _successMessage = 'Password updated successfully! Please login.';
      });

      await Supabase.instance.client.auth.signOut();

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _translateError(e.toString());
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // Resend timer
  // ============================================================
  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_userEmail!);
      setState(() {
        _isLoading = false;
        _successMessage = 'New OTP sent to $_userEmail';
      });
      _startResendTimer();
    } catch (e) {
      setState(() {
        _errorMessage = _translateError(e.toString());
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // OTP input handling
  // ============================================================
  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      _verifyOtp();
    }
  }

  // ============================================================
  // BUILD STEP CONTENT
  // ============================================================
  Widget _buildStepIndicator() {
    final steps = ['Email', 'OTP', 'New Password'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        final isActive = i <= _currentStep;
        final isCurrent = i == _currentStep;
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF49e8c3)
                        : Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(
                      color: Colors.white,
                      width: 2,
                    )
                        : null,
                  ),
                  child: Center(
                    child: i < _currentStep
                        ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.black,
                    )
                        : Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1)
              Container(
                width: 50,
                height: 2,
                margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                color: i < _currentStep
                    ? const Color(0xFF49e8c3)
                    : Colors.white.withOpacity(0.15),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forgot Password?',
            style: AppTextStyles.headline2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address and we\'ll send you a 6-digit OTP code.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your registered email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter your email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: LoadingButton(
              onPressed: _sendOtp,
              isLoading: _isLoading,
              label: 'Send OTP',
              backgroundColor: const Color(0xFF49e8c3),
              textColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter OTP',
          style: AppTextStyles.headline2.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _userEmail ?? '',
                style: const TextStyle(
                  color: Color(0xFF49e8c3),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 58,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
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
          height: 56,
          child: LoadingButton(
            onPressed: _verifyOtp,
            isLoading: _isLoading,
            label: 'Verify OTP',
            backgroundColor: const Color(0xFF49e8c3),
            textColor: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: _resendCountdown > 0
              ? Text(
            'Resend OTP in ${_resendCountdown}s',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          )
              : TextButton(
            onPressed: _resendOtp,
            child: const Text(
              'Resend OTP',
              style: TextStyle(
                color: Color(0xFF49e8c3),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _currentStep = 0;
                for (final c in _otpControllers) {
                  c.clear();
                }
                _errorMessage = null;
                _successMessage = null;
              });
            },
            child: const Text(
              'Change email',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set New Password',
            style: AppTextStyles.headline2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a strong new password for your account.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _newPasswordController,
            label: 'New Password',
            hint: 'Enter new password',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter a new password';
              if (value!.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter new password',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please confirm your password';
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: LoadingButton(
              onPressed: _updatePassword,
              isLoading: _isLoading,
              label: 'Update Password',
              backgroundColor: const Color(0xFF49e8c3),
              textColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ TRANSPARENT TEXT FIELD (Matches product setup)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white70,
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
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A2A),
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildBackground(size),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_currentStep > 0) {
                            setState(() {
                              _currentStep--;
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          } else {
                            context.pop();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF49e8c3).withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF49e8c3).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _currentStep == 0
                                ? Icons.lock_reset
                                : _currentStep == 1
                                ? Icons.pin_outlined
                                : Icons.password,
                            color: const Color(0xFF49e8c3),
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildStepIndicator(),
                      const SizedBox(height: 28),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _errorMessage = null),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_currentStep == 0)
                        _buildEmailStep()
                      else if (_currentStep == 1)
                        _buildOtpStep()
                      else
                        _buildPasswordStep(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}