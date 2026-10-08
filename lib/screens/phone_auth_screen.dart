import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/phone_helper.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'language_selection_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isCodeSent = false;
  bool _isLoading = false;
  String _errorMessage = '';
  int _resendCountdown = 45;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 45);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.trim();
    final normalized = PhoneHelper.normalize(rawPhone);

    if (normalized.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-11 digit mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final provider = Provider.of<AppStateProvider>(context, listen: false);

    await provider.authService.sendOtp(
      phoneNumber: normalized,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _isCodeSent = true;
            _isLoading = false;
          });
          _startCountdown();
          _otpFocusNodes[0].requestFocus();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        }
      },
      onAutoVerified: () async {
        await provider.onPhoneLoginSuccess(normalized);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      },
    );
  }

  Future<void> _handleVerifyOtp() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final normalized = PhoneHelper.normalize(_phoneController.text);

    final isSuccess = await provider.authService.verifyOtp(
      smsCode: otpCode,
      phoneNumber: normalized,
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        }
      },
    );

    if (isSuccess) {
      await provider.onPhoneLoginSuccess(normalized);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueOffline() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isNotEmpty) {
      final normalized = PhoneHelper.normalize(rawPhone);
      await provider.authService.loginDirectly(normalized);
      await provider.onPhoneLoginSuccess(normalized);
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = provider.isDarkMode;
    final isUrdu = provider.language == AppLanguage.urdu;
    final isRoman = provider.language == AppLanguage.romanUrdu;

    String titleText = 'Welcome to Easy Manage';
    String subtitleText = 'Manage your Khata & connect with your shopkeepers in real time';
    String phoneLabel = 'Mobile Phone Number';
    String getOtpBtnText = 'Get OTP Verification Code';
    String quickLoginText = 'Quick Dev / Direct Login';

    if (isUrdu) {
      titleText = 'ایزی مینیج میں خوش آمدید';
      subtitleText = 'اپنا کھاتہ سنبھالیں اور دکانداروں سے لائیو منسلک رہیں';
      phoneLabel = 'موبائل فون نمبر درج کریں';
      getOtpBtnText = 'او ٹی پی کوڈ حاصل کریں';
      quickLoginText = 'فوری لاگ ان / بغیر ایس ایم ایس';
    } else if (isRoman) {
      titleText = 'Easy Manage me Khushamdeed';
      subtitleText = 'Apna Khata sambhalein aur live hisab kitab dekhein';
      phoneLabel = 'Mobile Phone Number';
      getOtpBtnText = 'OTP Code Hasil Karein';
      quickLoginText = 'Direct / Quick Login';
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar: Language & Dark mode buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_done_rounded, color: AppTheme.primaryGreen, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Live Cloud Sync',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Language Selector Button
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LanguageSelectionScreen(isFirstTime: false),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.translate_rounded, size: 14, color: AppTheme.primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                isUrdu ? 'اردو' : (isRoman ? 'Hinglish' : 'EN'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dark Mode Button
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? AppTheme.accentGold : AppTheme.lightTextSecondary,
                          size: 20,
                        ),
                        onPressed: () => provider.toggleDarkMode(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // App Logo
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 18),
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isCodeSent
                    ? 'Enter the 6-digit code sent to ${PhoneHelper.formatForDisplay(_phoneController.text)}'
                    : subtitleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Main Auth Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isCodeSent) ...[
                      // Phone Number Input Form
                      Text(
                        phoneLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCardElevated : AppTheme.lightCardElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                            ),
                            child: const Row(
                              children: [
                                Text('🇵🇰', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 6),
                                Text(
                                  '+92',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              autofocus: true,
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: '300 1234567',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _handleSendOtp,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    getOtpBtnText,
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ] else ...[
                      // 6-Digit OTP Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Enter 6-Digit OTP',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => setState(() => _isCodeSent = false),
                            child: const Text('Edit Phone'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 44,
                            height: 52,
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: (val) {
                                if (val.isNotEmpty && index < 5) {
                                  _otpFocusNodes[index + 1].requestFocus();
                                } else if (val.isEmpty && index > 0) {
                                  _otpFocusNodes[index - 1].requestFocus();
                                }
                                if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                                  _handleVerifyOtp();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _handleVerifyOtp,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Verify & Continue',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: _resendCountdown > 0
                            ? Text(
                                'Resend OTP in $_resendCountdown seconds',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                              )
                            : TextButton(
                                onPressed: _handleSendOtp,
                                child: const Text('Resend OTP Code'),
                              ),
                      ),
                    ],

                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.debitRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.debitRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.debitRed, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: GoogleFonts.inter(color: AppTheme.debitRed, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Dev / Direct Login Button
              TextButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 18, color: AppTheme.primaryGreen),
                label: Text(
                  quickLoginText,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                ),
                onPressed: _continueOffline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
