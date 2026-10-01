import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  bool _hasError = false;

  void _onKeyPress(String val) {
    HapticFeedback.selectionClick();
    if (_enteredPin.length < 4) {
      final newPin = _enteredPin + val;
      setState(() {
        _enteredPin = newPin;
        _hasError = false;
      });

      // Auto-check immediately on 4th digit
      if (newPin.length == 4) {
        Future.microtask(() => _validatePin());
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  void _onClearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = '';
      _hasError = false;
    });
  }

  void _validatePin() {
    if (_enteredPin.isEmpty) return;
    final provider = context.read<AppStateProvider>();
    final success = provider.unlockWithPin(_enteredPin);

    if (success) {
      HapticFeedback.mediumImpact();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (_, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _enteredPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Incorrect PIN. Please try again.'),
            ],
          ),
          backgroundColor: AppTheme.debitRed,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _unlockBiometric() {
    HapticFeedback.selectionClick();
    final provider = context.read<AppStateProvider>();
    provider.unlockWithBiometric();
    if (provider.isAppUnlocked) {
      HapticFeedback.mediumImpact();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (_, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final isDark = provider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Icon
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 42, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 16),
                Text(
                  'EasyManage Locked',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your 4-digit PIN to access your ledgers',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // PIN dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: isFilled ? 20 : 16,
                      height: isFilled ? 20 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError
                            ? AppTheme.debitRed
                            : (isFilled ? AppTheme.primaryGreen : Colors.transparent),
                        border: Border.all(
                          color: _hasError
                              ? AppTheme.debitRed
                              : (isFilled ? AppTheme.primaryGreen : Colors.grey.shade400),
                          width: 2,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Numeric Keypad
                Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    children: [
                      _buildKeypadRow(['1', '2', '3'], isDark),
                      const SizedBox(height: 14),
                      _buildKeypadRow(['4', '5', '6'], isDark),
                      const SizedBox(height: 14),
                      _buildKeypadRow(['7', '8', '9'], isDark),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Biometric / Clear Button
                          if (provider.isBiometricEnabled)
                            _buildActionButton(
                              icon: Icons.fingerprint_rounded,
                              onTap: _unlockBiometric,
                              isDark: isDark,
                              color: AppTheme.primaryGreen,
                            )
                          else
                            _buildActionButton(
                              icon: Icons.clear_rounded,
                              onTap: _onClearAll,
                              isDark: isDark,
                              color: Colors.grey,
                            ),
                          _buildNumberButton('0', isDark),
                          _buildActionButton(
                            icon: Icons.backspace_outlined,
                            onTap: _onBackspace,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Prominent "OK / UNLOCK" Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: Text(
                            'OK / UNLOCK',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                            disabledBackgroundColor: isDark
                                ? AppTheme.darkCardElevated
                                : Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                          ),
                          onPressed: _enteredPin.length == 4 ? _validatePin : null,
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

  Widget _buildKeypadRow(List<String> numbers, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((digit) => _buildNumberButton(digit, isDark)).toList(),
    );
  }

  Widget _buildNumberButton(String number, bool isDark) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(number),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardElevated : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: 26, color: color ?? (isDark ? Colors.white70 : Colors.black87)),
          ),
        ),
      ),
    );
  }
}
